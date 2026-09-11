#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell, GLib, Gdk
import os
import sys
import signal
import time
import subprocess
import fcntl
import json
import re
import threading
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

RUNTIME_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-system-popup")
STATE_FILE = os.path.join(RUNTIME_DIR, "state")
PID_FILE = os.path.join(RUNTIME_DIR, "popup.pid")
LOCK_FILE = os.path.join(RUNTIME_DIR, "popup.lock")
CONFIG_PATH = os.path.expanduser("~/.config/waybar/scripts/system-popup.toml")

def get_active_theme_path() -> str:
    style_path = os.path.expanduser("~/.config/waybar/style.css")
    default_theme = os.path.expanduser("~/.config/waybar/themes/catppuccin-mocha.css")
    if not os.path.exists(style_path):
        return default_theme
    try:
        with open(style_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("@import"):
                    match = re.search(r'["\']([^"\']+)["\']', line)
                    if match:
                        rel = match.group(1)
                        full = os.path.normpath(os.path.join(os.path.dirname(style_path), rel))
                        if os.path.exists(full):
                            return full
    except Exception:
        pass
    return default_theme

def calculate_popup_geometry():
    """
    Calculates Wayland layer shell geometry based on monitor geometry,
    Waybar reserved bar margins, and mouse cursor location.
    """
    target_mon_id = None
    top_margin = 54
    left_margin = 120

    try:
        mon_proc = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.3)
        cur_proc = subprocess.run(['hyprctl', 'cursorpos'], capture_output=True, text=True, timeout=0.3)

        if mon_proc.returncode == 0 and cur_proc.returncode == 0:
            monitors = json.loads(mon_proc.stdout)
            cx, cy = [int(v.strip()) for v in cur_proc.stdout.split(',')]

            active_mon = None
            for m in monitors:
                scale = m.get('scale', 1.0)
                log_w = m['width'] / scale
                log_h = m['height'] / scale
                if m['x'] <= cx <= m['x'] + log_w and m['y'] <= cy <= m['y'] + log_h:
                    active_mon = m
                    break
            if not active_mon:
                active_mon = next((m for m in monitors if m.get('focused')), monitors[0])

            scale = active_mon.get('scale', 1.0)
            log_w = int(active_mon['width'] / scale)
            rel_cx = cx - active_mon['x']

            # Read monitor reserved top region (Waybar reserved space)
            reserved = active_mon.get('reserved', [0, 48, 0, 0])
            reserved_top = reserved[1] if len(reserved) > 1 else 48
            top_margin = max(reserved_top + 6, 44)

            popup_width = 380
            target_left = rel_cx - (popup_width // 2)
            left_margin = max(12, min(target_left, log_w - popup_width - 12))
            target_mon_id = active_mon.get('id')
    except Exception:
        pass

    return target_mon_id, top_margin, left_margin

def load_config():
    default_config = {
        "system": {
            "cpu": True, "ram": True, "gpu": True, "storage": True,
            "network_speed": True, "temperature": True,
            "updates": True, "github": False
        }
    }
    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "rb") as f:
                user_config = tomllib.load(f)
                if "system" in user_config:
                    default_config["system"].update(user_config["system"])
        except Exception as e:
            print(f"Error parsing config: {e}")
    return default_config["system"]

class SystemPopup(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.config = load_config()

        # Single-instance lock and runtime directory setup
        os.makedirs(RUNTIME_DIR, mode=0o700, exist_ok=True)
        self.lock_fd = open(LOCK_FILE, "a+")
        try:
            fcntl.flock(self.lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except (BlockingIOError, OSError):
            self.lock_fd.close()
            self.lock_fd = None
            if os.path.exists(PID_FILE):
                try:
                    with open(PID_FILE, "r") as f:
                        pid = int(f.read().strip())
                    if pid > 0:
                        os.kill(pid, signal.SIGUSR1)
                except Exception:
                    pass
            sys.exit(0)

        try:
            self.lock_fd.seek(0)
            self.lock_fd.truncate()
            self.lock_fd.write(f"{os.getpid()}\n")
            self.lock_fd.flush()
            with open(PID_FILE, "w") as f:
                f.write(f"{os.getpid()}\n")
        except Exception:
            pass

        # State
        self.is_visible = False
        self.is_closing = False
        self.update_timer = None
        self.fast_timer = None
        self.last_cpu_idle = 0
        self.last_cpu_total = 0
        self.last_net_rx = 0
        self.last_net_tx = 0
        self.last_net_time = 0
        self._programmatic_conn_update = False

        # UI Setup
        self.set_title("System Popup")
        self.set_decorated(False)
        self.set_name("system-popup")
        
        # Transparent window for compositor styling
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
        self.set_app_paintable(True)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_namespace(self, "system-popup")
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, False)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, False)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        # Dynamic monitor and cursor placement
        target_mon_id, top_margin, left_margin = calculate_popup_geometry()
        display = Gdk.Display.get_default()
        if target_mon_id is not None and display and 0 <= target_mon_id < display.get_n_monitors():
            gdk_mon = display.get_monitor(target_mon_id)
            if gdk_mon:
                GtkLayerShell.set_monitor(self, gdk_mon)

        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, top_margin)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.LEFT, left_margin)
        
        self.connect("focus-out-event", self.on_focus_out)
        self.connect("key-press-event", self.on_key_press)
        self.connect("delete-event", self.on_delete_event)
        self.connect("destroy", self.on_destroy)
        
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=25)
        main_box.set_margin_top(20)
        main_box.set_margin_bottom(20)
        main_box.set_margin_start(20)
        main_box.set_margin_end(20)
        self.add(main_box)
        
        # --- 1. Connectivity ---
        conn_label = Gtk.Label(label="Connectivity")
        conn_label.set_halign(Gtk.Align.START)
        conn_label.get_style_context().add_class("section-title")
        main_box.pack_start(conn_label, False, False, 0)
        
        conn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        main_box.pack_start(conn_box, False, False, 0)
        
        self.wifi_btn = Gtk.ToggleButton(label="   Wi-Fi")
        self.eth_btn = Gtk.ToggleButton(label="󰈀   Ethernet")
        self.bt_btn = Gtk.ToggleButton(label="   Bluetooth")
        
        for btn in [self.wifi_btn, self.eth_btn, self.bt_btn]:
            btn.get_style_context().add_class("conn-btn")
            conn_box.pack_start(btn, True, True, 0)
            btn.connect("toggled", self.on_conn_toggled)
            
        # --- 2. System ---
        sys_label = Gtk.Label(label="System")
        sys_label.set_halign(Gtk.Align.START)
        sys_label.get_style_context().add_class("section-title")
        main_box.pack_start(sys_label, False, False, 0)
        
        self.sys_grid = Gtk.Grid(column_spacing=25, row_spacing=20)
        main_box.pack_start(self.sys_grid, False, False, 0)
        
        self.metrics = {}
        self.metric_titles = {}
        self._updates_checking = False
        row, col = 0, 0
        
        def add_metric(key, icon, name):
            nonlocal col, row
            if not self.config.get(key, False): return
            
            box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
            
            icon_lbl = Gtk.Label(label=icon)
            icon_lbl.get_style_context().add_class("metric-icon")
            icon_lbl.set_valign(Gtk.Align.CENTER)
            
            vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            vbox.set_valign(Gtk.Align.CENTER)
            
            name_lbl = Gtk.Label(label=name)
            name_lbl.set_halign(Gtk.Align.START)
            name_lbl.get_style_context().add_class("metric-name")
            
            val_lbl = Gtk.Label(label="--")
            val_lbl.set_halign(Gtk.Align.START)
            val_lbl.get_style_context().add_class("metric-val")
            
            vbox.pack_start(name_lbl, False, False, 0)
            vbox.pack_start(val_lbl, False, False, 0)
            
            box.pack_start(icon_lbl, False, False, 0)
            box.pack_start(vbox, True, True, 0)
            
            # Make boxes equal width for clean grid layout
            box.set_size_request(140, -1)
            
            self.sys_grid.attach(box, col, row, 1, 1)
            self.metrics[key] = val_lbl
            self.metric_titles[key] = name_lbl
            
            col += 1
            if col > 1:
                col = 0
                row += 1
                
        add_metric("cpu", "", "CPU Usage")
        add_metric("ram", "", "Memory")
        add_metric("gpu", "󰢮", "GPU Usage")
        add_metric("storage", "", "Storage")
        add_metric("temperature", "", "Temperature")
        add_metric("network_speed", "󰓢", "Network")
        add_metric("updates", "", "Updates")
        add_metric("github", "", "GitHub")
        
        self.load_css()
        
    def load_css(self):
        theme_path = get_active_theme_path()
        css = f"""
        @import url("{theme_path}");

        window#system-popup {{
            background-color: alpha(@tooltip_bg, 0.95);
            border-radius: 16px;
            border: 1px solid @workspace_border;
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.45);
        }}
        #system-popup .section-title {{
            font-weight: 800;
            font-size: 14px;
            color: @text;
            margin-bottom: 5px;
        }}
        #system-popup .conn-btn {{
            border-radius: 12px;
            padding: 10px 16px;
            background-color: alpha(@surface, 0.6);
            color: @inactive;
            font-weight: bold;
            font-size: 13px;
            border: 1px solid transparent;
            box-shadow: none;
            text-shadow: none;
            transition: all 0.2s ease;
        }}
        #system-popup .conn-btn:checked {{
            background-color: @module_icon;
            color: @utility_fg;
            border-color: @module_icon;
        }}
        #system-popup .conn-btn:hover {{
            background-color: alpha(@text, 0.12);
            color: @text;
        }}
        #system-popup .conn-btn:checked:hover {{
            background-color: @blue;
            color: @utility_fg;
        }}
        #system-popup .conn-btn:disabled {{
            opacity: 0.45;
        }}
        #system-popup .metric-icon {{
            font-size: 22px;
            color: @module_icon;
            min-width: 35px;
        }}
        #system-popup .metric-name {{
            font-size: 12px;
            color: @inactive;
            font-weight: 600;
        }}
        #system-popup .metric-val {{
            font-size: 15px;
            font-weight: 900;
            color: @text;
        }}
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode('utf-8'))

        def add_provider_recursive(widget):
            widget.get_style_context().add_provider(
                provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            if isinstance(widget, Gtk.Container):
                for child in widget.get_children():
                    add_provider_recursive(child)

        add_provider_recursive(self)
        
    def _query_wifi_state(self):
        """Queries NetworkManager for Wi-Fi radio status. Returns True, False, or None."""
        try:
            proc = subprocess.run(["nmcli", "radio", "wifi"], capture_output=True, text=True, timeout=2.5)
            if proc.returncode == 0:
                out = proc.stdout.strip().lower()
                if out == "enabled":
                    return True
                elif out == "disabled":
                    return False
        except Exception:
            pass
        return None

    def _query_bluetooth_state(self):
        """Queries BlueZ/rfkill for Bluetooth adapter power. Returns True, False, or None."""
        try:
            proc = subprocess.run(["bluetoothctl", "show"], capture_output=True, text=True, timeout=2.5)
            if proc.returncode == 0:
                if "Powered: yes" in proc.stdout:
                    return True
                elif "Powered: no" in proc.stdout:
                    return False
            rf = subprocess.run(["rfkill", "list", "bluetooth"], capture_output=True, text=True, timeout=2.5)
            if rf.stdout.strip():
                if "Soft blocked: yes" in rf.stdout or "Hard blocked: yes" in rf.stdout:
                    return False
                return False
            else:
                return None
        except Exception:
            pass
        return None

    def _query_ethernet_state(self):
        """
        Dynamically detects physical Ethernet interface(s) and their carrier/link state.
        Returns: (status, iface) where status is 'connected', 'disconnected', or 'unavailable'.
        """
        net_dir = "/sys/class/net"
        if not os.path.exists(net_dir):
            return ("unavailable", None)

        eth_ifaces = []
        for iface in sorted(os.listdir(net_dir)):
            dev_path = os.path.join(net_dir, iface, "device")
            wire_path = os.path.join(net_dir, iface, "wireless")
            phy_path = os.path.join(net_dir, iface, "phy80211")
            type_path = os.path.join(net_dir, iface, "type")

            if os.path.exists(dev_path) and not os.path.exists(wire_path) and not os.path.exists(phy_path):
                itype = None
                if os.path.exists(type_path):
                    try:
                        with open(type_path, "r") as f:
                            itype = f.read().strip()
                    except Exception:
                        pass
                if itype == "1":
                    eth_ifaces.append(iface)

        if not eth_ifaces:
            return ("unavailable", None)

        for iface in eth_ifaces:
            carrier_path = os.path.join(net_dir, iface, "carrier")
            oper_path = os.path.join(net_dir, iface, "operstate")
            carrier = 0
            oper = "unknown"
            if os.path.exists(carrier_path):
                try:
                    with open(carrier_path, "r") as f:
                        carrier = int(f.read().strip())
                except Exception:
                    carrier = 0
            if os.path.exists(oper_path):
                try:
                    with open(oper_path, "r") as f:
                        oper = f.read().strip()
                except Exception:
                    pass

            if carrier == 1 or oper == "up":
                return ("connected", iface)

        return ("disconnected", eth_ifaces[0])

    def _apply_conn_states(self, wifi, bt, eth_status, eth_iface):
        """
        Applies queried connectivity states to GTK buttons using the programmatic guard
        to prevent signal recursion.
        """
        if not self.is_visible or self.is_closing:
            return False

        self._programmatic_conn_update = True
        try:
            # Wi-Fi
            if wifi is not None:
                self.wifi_btn.set_sensitive(True)
                self.wifi_btn.set_active(wifi)
                self.wifi_btn.set_tooltip_text("Wi-Fi is enabled" if wifi else "Wi-Fi is disabled")
            else:
                self.wifi_btn.set_sensitive(False)
                self.wifi_btn.set_active(False)
                self.wifi_btn.set_tooltip_text("Wi-Fi unavailable (NetworkManager error)")

            # Bluetooth
            if bt is not None:
                self.bt_btn.set_sensitive(True)
                self.bt_btn.set_active(bt)
                self.bt_btn.set_tooltip_text("Bluetooth is powered on" if bt else "Bluetooth is powered off")
            else:
                self.bt_btn.set_sensitive(False)
                self.bt_btn.set_active(False)
                self.bt_btn.set_tooltip_text("Bluetooth unavailable")

            # Ethernet (Status Indicator)
            if eth_status == "connected":
                self.eth_btn.set_sensitive(True)
                self.eth_btn.set_active(True)
                self.eth_btn.set_tooltip_text(f"Ethernet connected ({eth_iface})")
            elif eth_status == "disconnected":
                self.eth_btn.set_sensitive(True)
                self.eth_btn.set_active(False)
                self.eth_btn.set_tooltip_text(f"Ethernet disconnected ({eth_iface})")
            else:
                self.eth_btn.set_sensitive(False)
                self.eth_btn.set_active(False)
                self.eth_btn.set_tooltip_text("No Ethernet adapter")
        finally:
            self._programmatic_conn_update = False

        return False

    def refresh_connectivity_async(self):
        """Reads system connectivity state in a background thread."""
        def worker():
            wifi = self._query_wifi_state()
            bt = self._query_bluetooth_state()
            eth_status, eth_iface = self._query_ethernet_state()
            GLib.idle_add(self._apply_conn_states, wifi, bt, eth_status, eth_iface)

        threading.Thread(target=worker, daemon=True).start()

    def _toggle_wifi_async(self, enable: bool):
        """Toggles Wi-Fi radio via nmcli in background, then re-queries authoritative state."""
        def worker():
            try:
                subprocess.run(
                    ["nmcli", "radio", "wifi", "on" if enable else "off"],
                    capture_output=True, text=True, timeout=5
                )
            except Exception:
                pass
            actual_wifi = self._query_wifi_state()
            bt = self._query_bluetooth_state()
            eth_status, eth_iface = self._query_ethernet_state()
            GLib.idle_add(self._apply_conn_states, actual_wifi, bt, eth_status, eth_iface)

        threading.Thread(target=worker, daemon=True).start()

    def _toggle_bt_async(self, enable: bool):
        """Toggles Bluetooth adapter power in background, then re-queries authoritative state."""
        def worker():
            try:
                if enable:
                    subprocess.run(["rfkill", "unblock", "bluetooth"], capture_output=True, text=True, timeout=3)
                    subprocess.run(["bluetoothctl", "power", "on"], capture_output=True, text=True, timeout=5)
                else:
                    subprocess.run(["bluetoothctl", "power", "off"], capture_output=True, text=True, timeout=5)
            except Exception:
                pass
            wifi = self._query_wifi_state()
            actual_bt = self._query_bluetooth_state()
            eth_status, eth_iface = self._query_ethernet_state()
            GLib.idle_add(self._apply_conn_states, wifi, actual_bt, eth_status, eth_iface)

        threading.Thread(target=worker, daemon=True).start()

    def on_conn_toggled(self, btn):
        if self._programmatic_conn_update or not self.is_visible or self.is_closing:
            return

        if btn == self.wifi_btn:
            target = self.wifi_btn.get_active()
            self._toggle_wifi_async(target)
        elif btn == self.bt_btn:
            target = self.bt_btn.get_active()
            self._toggle_bt_async(target)
        elif btn == self.eth_btn:
            # Ethernet is a status indicator. Re-sync to real system state.
            self.refresh_connectivity_async()

    def toggle(self):
        if self.is_visible:
            self.close_popup(reason="toggle")
        else:
            self.show_popup()
            
    def show_popup(self):
        if self.is_visible:
            return
        self.is_visible = True
        self.show_all()
        self.present()

        # Update runtime state to open (1) and signal Waybar
        try:
            with open(STATE_FILE, "w") as f:
                f.write("1\n")
            subprocess.run(["pkill", "-RTMIN+10", "-x", "waybar"], check=False)
        except Exception:
            pass

        # Reset baseline for rate and differential metrics
        self.last_cpu_idle = 0
        self.last_cpu_total = 0
        self.last_net_rx = 0
        self.last_net_tx = 0
        self.last_net_time = 0

        self.refresh_connectivity_async()
        self.update_metrics_slow()
        self.update_metrics_fast()
        # High frequency for network speed
        self.fast_timer = GLib.timeout_add(1000, self.update_metrics_fast)
        # Low frequency for heavy metrics
        self.update_timer = GLib.timeout_add(3000, self.update_metrics_slow)
        
    def close_popup(self, reason="unknown"):
        if self.is_closing:
            return
        self.is_closing = True

        # 1. Hide / unmap popup
        try:
            self.hide()
        except Exception:
            pass
        self.is_visible = False

        # 2. Stop active timers
        if self.fast_timer is not None:
            GLib.source_remove(self.fast_timer)
            self.fast_timer = None
        if self.update_timer is not None:
            GLib.source_remove(self.update_timer)
            self.update_timer = None

        # 3. Write closed state (0)
        try:
            with open(STATE_FILE, "w") as f:
                f.write("0\n")
        except Exception:
            pass

        # 4. Signal Waybar
        try:
            subprocess.run(["pkill", "-RTMIN+10", "-x", "waybar"], check=False)
        except Exception:
            pass

        # 5. Release process lock & remove PID file
        try:
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)
        except Exception:
            pass
        if self.lock_fd is not None:
            try:
                fcntl.flock(self.lock_fd, fcntl.LOCK_UN)
                self.lock_fd.close()
                self.lock_fd = None
            except Exception:
                pass

        # 6. Exit cleanly
        if Gtk.main_level() > 0:
            Gtk.main_quit()

    def on_focus_out(self, widget, event):
        self.close_popup(reason="focus-out")
        return False
        
    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_popup(reason="escape")
            return True
        return False

    def on_delete_event(self, widget, event):
        self.close_popup()
        return True

    def on_destroy(self, widget):
        self.close_popup()
        
    def _get_active_net_interfaces(self):
        """
        Determines the active network interface(s) to monitor.
        Prioritizes the default-route physical interface to avoid double-counting
        VPN or virtual bridge traffic.
        """
        default_ifaces = []
        if os.path.exists("/proc/net/route"):
            try:
                with open("/proc/net/route", "r") as f:
                    lines = f.readlines()[1:]
                for line in lines:
                    parts = line.strip().split()
                    if len(parts) >= 4:
                        iface, dest, flags = parts[0], parts[1], int(parts[3], 16)
                        if dest == "00000000" and (flags & 2):
                            default_ifaces.append(iface)
            except Exception:
                pass

        physical_up = []
        net_dir = "/sys/class/net"
        if os.path.exists(net_dir):
            for iface in sorted(os.listdir(net_dir)):
                dev_path = os.path.join(net_dir, iface, "device")
                oper_path = os.path.join(net_dir, iface, "operstate")
                if os.path.exists(dev_path):
                    oper = "unknown"
                    if os.path.exists(oper_path):
                        try:
                            with open(oper_path, "r") as f:
                                oper = f.read().strip()
                        except Exception:
                            pass
                    if oper == "up":
                        physical_up.append(iface)

        if default_ifaces and any(i in physical_up for i in default_ifaces):
            return [i for i in default_ifaces if i in physical_up][:1]
        elif physical_up:
            return physical_up
        elif default_ifaces:
            return default_ifaces[:1]
        else:
            return [i for i in os.listdir(net_dir) if i != "lo" and not i.startswith(("veth", "docker", "br-"))]

    def update_metrics_fast(self):
        if not self.is_visible or self.is_closing:
            return False

        if "network_speed" in self.metrics:
            try:
                active_ifaces = set(self._get_active_net_interfaces())
                with open("/proc/net/dev", "r") as f:
                    lines = f.readlines()[2:]
                rx, tx = 0, 0
                for line in lines:
                    parts = line.split()
                    iface = parts[0].strip(":")
                    if iface in active_ifaces:
                        rx += int(parts[1])
                        tx += int(parts[9])

                now = time.time()
                if self.last_net_time > 0 and now > self.last_net_time:
                    dt = now - self.last_net_time
                    if rx >= self.last_net_rx and tx >= self.last_net_tx:
                        rx_rate = (rx - self.last_net_rx) / dt
                        tx_rate = (tx - self.last_net_tx) / dt

                        def fmt(b):
                            if b >= 1048576:
                                return f"{b/1048576:.1f} MB/s"
                            if b >= 1024:
                                return f"{b/1024:.0f} KB/s"
                            return f"{b:.0f} B/s"

                        self.metrics["network_speed"].set_label(f"↓ {fmt(rx_rate)}   ↑ {fmt(tx_rate)}")
                        tip_ifaces = ", ".join(sorted(active_ifaces))
                        self.metrics["network_speed"].set_tooltip_text(f"Interface: {tip_ifaces}")
                else:
                    self.metrics["network_speed"].set_label("--")

                self.last_net_rx = rx
                self.last_net_tx = tx
                self.last_net_time = now
            except Exception:
                self.metrics["network_speed"].set_label("N/A")
        return True

    def _read_cpu_temp(self):
        """
        Deterministically selects CPU package temperature instead of arbitrary thermal zones.
        """
        cpu_types = ["x86_pkg_temp", "coretemp", "k10temp", "zenpower", "cpu-thermal", "soc_thermal", "cpu_thermal"]
        thermal_dir = "/sys/class/thermal"

        # 1. Thermal zones with recognized CPU types
        if os.path.exists(thermal_dir):
            for zone in sorted(os.listdir(thermal_dir)):
                if not zone.startswith("thermal_zone"):
                    continue
                zpath = os.path.join(thermal_dir, zone)
                type_file = os.path.join(zpath, "type")
                temp_file = os.path.join(zpath, "temp")
                try:
                    with open(type_file, "r") as f:
                        ztype = f.read().strip()
                    if ztype.lower() in cpu_types:
                        with open(temp_file, "r") as f:
                            raw = int(f.read().strip())
                        if raw > 0:
                            return (raw / 1000.0, f"{ztype} ({zone})")
                except Exception:
                    continue

        # 2. hwmon fallback (e.g. coretemp, k10temp)
        hwmon_dir = "/sys/class/hwmon"
        if os.path.exists(hwmon_dir):
            for h in sorted(os.listdir(hwmon_dir)):
                hpath = os.path.join(hwmon_dir, h)
                name_file = os.path.join(hpath, "name")
                try:
                    with open(name_file, "r") as f:
                        hname = f.read().strip()
                    if any(t in hname.lower() for t in ["coretemp", "k10temp", "zenpower"]):
                        for f in sorted(os.listdir(hpath)):
                            if f.endswith("_label"):
                                with open(os.path.join(hpath, f), "r") as lf:
                                    label = lf.read().strip()
                                if any(lbl in label.lower() for lbl in ["package", "tdie", "tctl"]):
                                    in_file = f.replace("_label", "_input")
                                    inp_path = os.path.join(hpath, in_file)
                                    if os.path.exists(inp_path):
                                        with open(inp_path, "r") as inf:
                                            raw = int(inf.read().strip())
                                        if raw > 0:
                                            return (raw / 1000.0, f"{hname} ({label})")
                        t1 = os.path.join(hpath, "temp1_input")
                        if os.path.exists(t1):
                            with open(t1, "r") as inf:
                                raw = int(inf.read().strip())
                            if raw > 0:
                                return (raw / 1000.0, f"{hname} (temp1)")
                except Exception:
                    continue

        # 3. Fallback to any thermal zone matching cpu or acpi
        if os.path.exists(thermal_dir):
            for zone in sorted(os.listdir(thermal_dir)):
                if not zone.startswith("thermal_zone"):
                    continue
                zpath = os.path.join(thermal_dir, zone)
                type_file = os.path.join(zpath, "type")
                temp_file = os.path.join(zpath, "temp")
                try:
                    with open(type_file, "r") as f:
                        ztype = f.read().strip()
                    if "acpi" in ztype.lower() or "cpu" in ztype.lower():
                        with open(temp_file, "r") as f:
                            raw = int(f.read().strip())
                        if raw > 0:
                            return (raw / 1000.0, f"{ztype} ({zone})")
                except Exception:
                    continue

        return (None, None)

    def _read_gpu_metric(self):
        """
        Dynamically scans /sys/class/drm/card* devices.
        Distinguishes AMDGPU utilization (%) from Intel i915 clock frequency (MHz).
        Returns: (title_string, value_string, tooltip_string)
        """
        drm_dir = "/sys/class/drm"
        if not os.path.exists(drm_dir):
            return ("GPU Usage", "N/A", None)

        cards = sorted([c for c in os.listdir(drm_dir) if re.match(r"^card[0-9]+$", c)])
        for card in cards:
            card_path = os.path.join(drm_dir, card)

            # 1. AMD gpu_busy_percent
            amd_path = os.path.join(card_path, "device", "gpu_busy_percent")
            if os.path.exists(amd_path):
                try:
                    with open(amd_path, "r") as f:
                        busy = int(f.read().strip())
                    return ("GPU Usage", f"{busy}%", f"AMDGPU ({card})")
                except Exception:
                    pass

            # 2. Intel i915 frequency
            intel_paths = [
                os.path.join(card_path, "gt_act_freq_mhz"),
                os.path.join(card_path, "gt", "gt0", "rps_act_freq_mhz")
            ]
            for ip in intel_paths:
                if os.path.exists(ip):
                    try:
                        with open(ip, "r") as f:
                            act_freq = int(f.read().strip())
                        max_p = os.path.join(card_path, "gt_max_freq_mhz")
                        max_freq = None
                        if os.path.exists(max_p):
                            try:
                                with open(max_p, "r") as mf:
                                    max_freq = mf.read().strip()
                            except Exception:
                                pass
                        tip = f"Intel Graphics ({card})"
                        if max_freq:
                            tip += f" - Max: {max_freq} MHz"
                        return ("GPU Clock", f"{act_freq} MHz", tip)
                    except Exception:
                        pass

        return ("GPU Usage", "N/A", None)

    def _get_cached_updates(self):
        cache_file = os.path.join(RUNTIME_DIR, "updates_cache.json")
        if os.path.exists(cache_file):
            try:
                with open(cache_file, "r") as f:
                    cache_data = json.load(f)
                age = time.time() - cache_data.get("timestamp", 0)
                return cache_data, age
            except Exception:
                pass
        return None, float("inf")

    def _trigger_updates_check(self):
        if self._updates_checking:
            return
        self._updates_checking = True
        thread = threading.Thread(target=self._check_updates_worker, daemon=True)
        thread.start()

    def _check_updates_worker(self):
        official_count = None
        aur_count = None

        # 1. Check official repo updates
        try:
            p_off = subprocess.run(["checkupdates"], capture_output=True, text=True, timeout=20)
            if p_off.returncode == 0:
                official_count = len([l for l in p_off.stdout.splitlines() if l.strip()])
            elif p_off.returncode == 2:
                official_count = 0
            else:
                official_count = None
        except Exception:
            official_count = None

        # 2. Check AUR updates
        try:
            p_aur = subprocess.run(["yay", "-Qua"], capture_output=True, text=True, timeout=20)
            if p_aur.returncode == 0:
                aur_count = len([l for l in p_aur.stdout.splitlines() if l.strip()])
            elif p_aur.returncode == 1 and not p_aur.stdout.strip():
                aur_count = 0
            else:
                aur_count = None
        except Exception:
            aur_count = None

        # Result formatting
        if official_count is None and aur_count is None:
            label = "Unavailable"
            tooltip = "Failed to query pacman and AUR"
            total = None
        elif official_count is None:
            total = aur_count
            label = f"{aur_count} pkgs" if aur_count > 0 else "Up to date"
            tooltip = f"AUR: {aur_count}, Official: failed"
        elif aur_count is None:
            total = official_count
            label = f"{official_count} pkgs" if official_count > 0 else "Up to date"
            tooltip = f"Official: {official_count}, AUR: failed"
        else:
            total = official_count + aur_count
            if total == 0:
                label = "Up to date"
                tooltip = "All packages are up to date"
            else:
                label = f"{total} pkgs"
                tooltip = f"{total} updates available ({official_count} repo, {aur_count} AUR)"

        if total is not None:
            try:
                cache_data = {
                    "timestamp": time.time(),
                    "official": official_count,
                    "aur": aur_count,
                    "total": total,
                    "label": label,
                    "tooltip": tooltip
                }
                cache_file = os.path.join(RUNTIME_DIR, "updates_cache.json")
                with open(cache_file, "w") as f:
                    json.dump(cache_data, f)
            except Exception:
                pass

        self._updates_checking = False
        GLib.idle_add(self._apply_updates_result, label, tooltip)

    def _apply_updates_result(self, label_text, tooltip_text):
        if not self.is_visible or self.is_closing:
            return False
        if "updates" in self.metrics:
            self.metrics["updates"].set_label(label_text)
            if tooltip_text:
                self.metrics["updates"].set_tooltip_text(tooltip_text)
        return False

    def update_metrics_slow(self):
        if not self.is_visible or self.is_closing:
            return False

        # 1. CPU Telemetry
        if "cpu" in self.metrics:
            try:
                with open("/proc/stat", "r") as f:
                    fields = [float(col) for col in f.readline().strip().split()[1:]]
                idle, total = fields[3], sum(fields)
                if self.last_cpu_total > 0:
                    idle_delta = idle - self.last_cpu_idle
                    total_delta = total - self.last_cpu_total
                    if total_delta > 0:
                        usage = max(0.0, min(100.0, 100.0 * (1.0 - idle_delta / total_delta)))
                        self.metrics["cpu"].set_label(f"{usage:.1f}%")
                else:
                    self.metrics["cpu"].set_label("--%")
                self.last_cpu_idle = idle
                self.last_cpu_total = total
            except Exception:
                self.metrics["cpu"].set_label("N/A")

        # 2. Memory Telemetry
        if "ram" in self.metrics:
            try:
                mem = {}
                with open("/proc/meminfo", "r") as f:
                    for line in f:
                        parts = line.split()
                        if len(parts) >= 2:
                            mem[parts[0].strip(":")] = int(parts[1])
                total_kb = mem.get("MemTotal", 0)
                avail_kb = mem.get("MemAvailable", None)
                if avail_kb is None:
                    avail_kb = mem.get("MemFree", 0) + mem.get("Buffers", 0) + mem.get("Cached", 0) + mem.get("SReclaimable", 0)
                used_kb = max(0, total_kb - avail_kb)
                if total_kb > 0:
                    used_gb = used_kb / (1024 * 1024)
                    total_gb = total_kb / (1024 * 1024)
                    perc = (used_kb / total_kb) * 100
                    self.metrics["ram"].set_label(f"{used_gb:.1f} / {total_gb:.1f} GB ({perc:.0f}%)")
                    self.metrics["ram"].set_tooltip_text(f"Used: {used_gb:.2f} GB, Available: {avail_kb / (1024*1024):.2f} GB, Total: {total_gb:.2f} GB")
                else:
                    self.metrics["ram"].set_label("N/A")
            except Exception:
                self.metrics["ram"].set_label("N/A")

        # 3. Storage Telemetry
        if "storage" in self.metrics:
            try:
                st = os.statvfs('/')
                total = st.f_blocks * st.f_frsize
                free = st.f_bavail * st.f_frsize
                used = max(0, total - free)
                if total > 0:
                    perc = (used / total) * 100
                    used_gb = used / (1024**3)
                    total_gb = total / (1024**3)
                    self.metrics["storage"].set_label(f"{used_gb:.0f} GB ({perc:.0f}%)")
                    self.metrics["storage"].set_tooltip_text(f"Root: {used_gb:.1f} / {total_gb:.1f} GB ({free / (1024**3):.1f} GB free)")
                else:
                    self.metrics["storage"].set_label("N/A")
            except Exception:
                self.metrics["storage"].set_label("N/A")

        # 4. Temperature Telemetry
        if "temperature" in self.metrics:
            try:
                temp, tip = self._read_cpu_temp()
                if temp is not None:
                    self.metrics["temperature"].set_label(f"{temp:.0f}°C")
                    if tip:
                        self.metrics["temperature"].set_tooltip_text(tip)
                else:
                    self.metrics["temperature"].set_label("N/A")
            except Exception:
                self.metrics["temperature"].set_label("N/A")

        # 5. GPU Telemetry
        if "gpu" in self.metrics:
            try:
                title, val, tip = self._read_gpu_metric()
                if "gpu" in self.metric_titles and title:
                    self.metric_titles["gpu"].set_label(title)
                self.metrics["gpu"].set_label(val)
                if tip:
                    self.metrics["gpu"].set_tooltip_text(tip)
            except Exception:
                self.metrics["gpu"].set_label("N/A")

        # 6. Updates Telemetry
        if "updates" in self.metrics:
            cache_data, age = self._get_cached_updates()
            if cache_data is not None:
                self.metrics["updates"].set_label(cache_data["label"])
                if cache_data.get("tooltip"):
                    self.metrics["updates"].set_tooltip_text(cache_data["tooltip"])
                if age > 600:
                    self._trigger_updates_check()
            else:
                if not self._updates_checking:
                    self.metrics["updates"].set_label("Checking...")
                    self._trigger_updates_check()

        # 7. GitHub Telemetry
        if "github" in self.metrics:
            self.metrics["github"].set_label("N/A")
            self.metrics["github"].set_tooltip_text("GitHub integration disabled")

        return True

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "toggle":
        if os.path.exists(PID_FILE):
            try:
                with open(PID_FILE, "r") as f:
                    pid = int(f.read().strip())
                if pid > 0 and os.path.exists(f"/proc/{pid}"):
                    os.kill(pid, signal.SIGUSR1)
                    sys.exit(0)
            except Exception:
                pass

    win = SystemPopup()

    def handle_signal(sig, frame):
        sig_name = "SIGUSR1" if sig == signal.SIGUSR1 else ("SIGTERM" if sig == signal.SIGTERM else "SIGINT")
        GLib.idle_add(win.close_popup, sig_name)

    signal.signal(signal.SIGUSR1, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    win.show_popup()
    Gtk.main()
