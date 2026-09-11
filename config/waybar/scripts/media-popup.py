#!/usr/bin/env python3
import sys
import os
import signal
import threading
import urllib.request
import urllib.error
from urllib.parse import unquote
import json
import re
import subprocess
import hashlib
import fcntl
import tempfile

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
gi.require_version('Playerctl', '2.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, GtkLayerShell, Playerctl

LOCK_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir()), "waybar-media-popup.lock")
lock_fd = None

def acquire_instance_lock():
    global lock_fd
    try:
        lock_fd = open(LOCK_FILE, "w")
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except (IOError, BlockingIOError):
        # Another popup instance is already starting or running
        sys.exit(0)

acquire_instance_lock()

win = None

def cleanup(*args):
    global win
    if win:
        try:
            win.cleanup_resources()
        except Exception:
            pass
    Gtk.main_quit()
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT, cleanup)

def format_time(seconds):
    if seconds < 0:
        return "0:00"
    m = int(seconds // 60)
    s = int(seconds % 60)
    return f"{m}:{s:02d}"

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

            reserved = active_mon.get('reserved', [0, 48, 0, 0])
            reserved_top = reserved[1] if len(reserved) > 1 else 48
            top_margin = max(reserved_top + 6, 44)

            popup_width = 330
            target_left = rel_cx - (popup_width // 2)
            left_margin = max(12, min(target_left, log_w - popup_width - 12))
            target_mon_id = active_mon.get('id')
    except Exception:
        pass

    return target_mon_id, top_margin, left_margin

class MediaPopup(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title("Media Popup")
        self.set_name("media-popup")

        self.temp_cover_files = set()
        self.style_provider = None
        self.cover_provider = None

        # Transparent window for compositor styling
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual and screen.is_composited():
            self.set_visual(visual)
        self.set_app_paintable(True)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.LEFT, True)
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

        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", self.on_focus_out)

        self.manager = Playerctl.PlayerManager()
        self.active_player = None
        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)

        self.current_cover_url = None
        self.dragging = False

        self.build_ui()
        self.apply_scoped_theme()

        for name in self.manager.props.player_names:
            self.on_player_appeared(self.manager, name)

        GLib.timeout_add(100, self.update_position)

    def cleanup_resources(self):
        for path in list(self.temp_cover_files):
            try:
                if os.path.exists(path):
                    os.remove(path)
            except Exception:
                pass
        self.temp_cover_files.clear()
        self.style_provider = None

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            cleanup()
            return True
        return False

    def on_focus_out(self, widget, event):
        try:
            for proc in ["slurp", "grim"]:
                if subprocess.run(["pgrep", "-x", proc], stdout=subprocess.DEVNULL).returncode == 0:
                    return False
            if subprocess.run(["pgrep", "-f", "hyprshot"], stdout=subprocess.DEVNULL).returncode == 0:
                return False
        except Exception:
            pass

        cleanup()
        return False

    def build_ui(self):
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.main_box.set_name("main-container")
        self.add(self.main_box)

        # Album Art
        self.cover_box = Gtk.Box()
        self.cover_box.set_size_request(150, 150)
        self.cover_box.set_name("cover")
        self.cover_box.set_halign(Gtk.Align.CENTER)
        self.main_box.pack_start(self.cover_box, False, False, 2)

        # Title & Artist Container
        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        text_box.set_halign(Gtk.Align.CENTER)
        self.main_box.pack_start(text_box, False, False, 0)

        # Song Title
        self.lbl_title = Gtk.Label(xalign=0.5)
        self.lbl_title.set_name("title")
        self.lbl_title.set_line_wrap(True)
        self.lbl_title.set_lines(2)
        self.lbl_title.set_max_width_chars(30)
        self.lbl_title.set_justify(Gtk.Justification.CENTER)
        text_box.pack_start(self.lbl_title, False, False, 0)

        # Song Artist
        self.lbl_artist = Gtk.Label(xalign=0.5)
        self.lbl_artist.set_name("artist")
        self.lbl_artist.set_ellipsize(3)  # END
        self.lbl_artist.set_max_width_chars(35)
        text_box.pack_start(self.lbl_artist, False, False, 0)

        # Progress
        prog_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        self.main_box.pack_start(prog_box, False, False, 2)

        self.lbl_pos = Gtk.Label(label="0:00")
        self.lbl_pos.set_name("time-label")
        prog_box.pack_start(self.lbl_pos, False, False, 0)

        self.slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        self.slider.set_draw_value(False)
        self.slider.connect("button-press-event", self.on_slider_press)
        self.slider.connect("button-release-event", self.on_slider_release)
        self.slider.connect("change-value", self.on_slider_changed)
        prog_box.pack_start(self.slider, True, True, 0)

        self.lbl_len = Gtk.Label(label="0:00")
        self.lbl_len.set_name("time-label")
        prog_box.pack_start(self.lbl_len, False, False, 0)

        # Controls
        ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        ctrl_box.set_halign(Gtk.Align.CENTER)
        self.main_box.pack_start(ctrl_box, False, False, 2)

        self.btn_shuffle = Gtk.Button()
        self.img_shuffle = Gtk.Image.new_from_icon_name("media-playlist-shuffle-symbolic", Gtk.IconSize.BUTTON)
        self.btn_shuffle.set_image(self.img_shuffle)
        self.btn_shuffle.connect("clicked", self.on_shuffle)
        self.btn_shuffle.set_name("ctrl-btn-small")
        ctrl_box.pack_start(self.btn_shuffle, False, False, 0)

        # Previous
        self.btn_prev = Gtk.Button()
        self.btn_prev.set_image(Gtk.Image.new_from_icon_name("media-skip-backward-symbolic", Gtk.IconSize.BUTTON))
        self.btn_prev.connect("clicked", self.on_prev)
        self.btn_prev.set_name("ctrl-btn")
        ctrl_box.pack_start(self.btn_prev, False, False, 0)

        # Play/Pause
        self.btn_play = Gtk.Button()
        self.img_play = Gtk.Image.new_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON)
        self.btn_play.set_image(self.img_play)
        self.btn_play.connect("clicked", self.on_play_pause)
        self.btn_play.set_name("ctrl-btn-play")
        ctrl_box.pack_start(self.btn_play, False, False, 0)

        # Next
        self.btn_next = Gtk.Button()
        self.btn_next.set_image(Gtk.Image.new_from_icon_name("media-skip-forward-symbolic", Gtk.IconSize.BUTTON))
        self.btn_next.connect("clicked", self.on_next)
        self.btn_next.set_name("ctrl-btn")
        ctrl_box.pack_start(self.btn_next, False, False, 0)

        # Repeat
        self.btn_repeat = Gtk.Button()
        self.img_repeat = Gtk.Image.new_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
        self.btn_repeat.set_image(self.img_repeat)
        self.btn_repeat.connect("clicked", self.on_repeat)
        self.btn_repeat.set_name("ctrl-btn-small")
        ctrl_box.pack_start(self.btn_repeat, False, False, 0)

    def apply_scoped_theme(self):
        theme_path = get_active_theme_path()
        css = f"""
        @import url("{theme_path}");

        #media-popup #main-container {{
            background-color: @surface;
            border: 1px solid @workspace_border;
            border-radius: 20px;
            padding: 20px;
            min-width: 310px;
            box-shadow: 0px 8px 24px rgba(0, 0, 0, 0.4);
        }}
        #media-popup #cover {{
            border-radius: 16px;
            background-color: @workspace_border;
            box-shadow: 0px 6px 12px rgba(0, 0, 0, 0.4);
            transition: background-image 0.3s ease-in-out;
        }}
        #media-popup #title {{
            color: @text;
            font-weight: 800;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
        }}
        #media-popup #artist {{
            color: alpha(@text, 0.6);
            font-weight: 500;
            font-size: 13px;
            font-family: 'Inter', sans-serif;
            margin-top: 2px;
        }}
        #media-popup #time-label {{
            color: @inactive;
            font-size: 11px;
            font-family: 'Inter', sans-serif;
            font-weight: 600;
        }}
        #media-popup scale trough {{
            background-color: alpha(@text, 0.15);
            min-height: 6px;
            border-radius: 6px;
        }}
        #media-popup scale highlight {{
            background-color: @blue;
            border-radius: 6px;
        }}
        #media-popup scale slider {{
            background-color: @utility_bg;
            min-width: 14px;
            min-height: 14px;
            border-radius: 50%;
            margin: -4px 0;
            box-shadow: 0px 2px 6px rgba(0, 0, 0, 0.5);
            border: 1px solid rgba(0, 0, 0, 0.1);
            transition: all 0.15s cubic-bezier(0.4, 0.0, 0.2, 1);
        }}
        #media-popup scale slider:hover {{
            background-color: @blue;
            min-width: 16px;
            min-height: 16px;
            margin: -5px 0;
        }}
        #media-popup button#ctrl-btn {{
            background-color: transparent;
            color: @text;
            border: none;
            border-radius: 20px;
            min-width: 36px;
            min-height: 36px;
            transition: all 0.15s ease;
        }}
        #media-popup button#ctrl-btn-play {{
            background-color: @blue;
            color: @utility_fg;
            border: none;
            border-radius: 26px;
            min-width: 52px;
            min-height: 52px;
            box-shadow: 0px 4px 10px alpha(@blue, 0.3);
            transition: all 0.15s ease;
        }}
        #media-popup button#ctrl-btn:hover {{
            background-color: alpha(@text, 0.1);
        }}
        #media-popup button#ctrl-btn-play:hover {{
            background-color: @cyan;
            box-shadow: 0px 6px 14px alpha(@blue, 0.4);
        }}
        #media-popup button#ctrl-btn:active, #media-popup button#ctrl-btn-play:active {{
            opacity: 0.7;
        }}
        #media-popup button#ctrl-btn-small, #media-popup button#ctrl-btn-small-active {{
            background-color: transparent;
            color: alpha(@text, 0.4);
            border: none;
            border-radius: 18px;
            min-width: 36px;
            min-height: 36px;
            transition: all 0.15s ease;
        }}
        #media-popup button#ctrl-btn-small-active {{
            color: @blue;
            background-color: alpha(@blue, 0.1);
        }}
        #media-popup button#ctrl-btn-small:hover {{
            color: alpha(@text, 0.8);
            background-color: alpha(@text, 0.05);
        }}
        #media-popup button#ctrl-btn-small-active:hover {{
            background-color: alpha(@blue, 0.2);
        }}
        """
        self.style_provider = Gtk.CssProvider()
        self.style_provider.load_from_data(css.encode('utf-8'))

        def add_provider_recursive(widget):
            widget.get_style_context().add_provider(
                self.style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
            if isinstance(widget, Gtk.Container):
                for child in widget.get_children():
                    add_provider_recursive(child)

        add_provider_recursive(self)

    def on_player_appeared(self, manager, name):
        player = Playerctl.Player.new_from_name(name)
        player.connect("metadata", self.on_metadata, manager)
        player.connect("playback-status", self.on_status, manager)
        manager.manage_player(player)
        self.update_active_player()

    def on_player_vanished(self, manager, player):
        self.update_active_player()

    def update_active_player(self):
        players = self.manager.props.players
        if not players:
            self.active_player = None
            self.lbl_title.set_text("No media playing")
            self.lbl_artist.set_text("")
            self.set_image(None)
            self.current_cover_url = None
            return

        # 1. Prioritize canonical active player selected by media-scroll.py
        canonical_name = None
        state_file = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-media-active-player")
        if os.path.exists(state_file):
            try:
                with open(state_file, "r") as f:
                    canonical_name = f.read().strip()
            except Exception:
                pass

        active = None
        if canonical_name:
            for p in players:
                if p.props.player_name == canonical_name:
                    active = p
                    break

        # 2. Fallback to playing / paused / first
        if not active:
            playing = [p for p in players if p.props.playback_status == Playerctl.PlaybackStatus.PLAYING]
            paused = [p for p in players if p.props.playback_status == Playerctl.PlaybackStatus.PAUSED]
            if playing:
                active = playing[0]
            elif paused:
                active = paused[0]
            else:
                active = players[0]

        self.active_player = active
        self.update_ui()

    def on_metadata(self, player, metadata, manager):
        if player == self.active_player:
            self.update_ui()
        else:
            self.update_active_player()

    def on_status(self, player, status, manager):
        self.update_active_player()

    def update_ui(self):
        if not self.active_player:
            return

        title = self.active_player.get_title() or "Unknown Title"
        artist = self.active_player.get_artist() or "Unknown Artist"

        self.lbl_title.set_text(title)
        self.lbl_artist.set_text(artist)

        self.update_play_button()

        # Update cover async
        try:
            art_url = self.active_player.print_metadata_prop("mpris:artUrl")
        except Exception:
            art_url = None

        if art_url != self.current_cover_url:
            self.current_cover_url = art_url
            if art_url:
                threading.Thread(target=self.load_image, args=(art_url,), daemon=True).start()
            else:
                self.set_image(None)

    def load_image(self, url):
        try:
            if url.startswith("file://"):
                path = unquote(url[7:])
                if not os.path.isfile(path):
                    path = None
            else:
                req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                # Bounded timeout of 3 seconds
                with urllib.request.urlopen(req, timeout=3.0) as resp:
                    data = resp.read()

                if not data:
                    path = None
                else:
                    # Validate image data
                    loader = GdkPixbuf.PixbufLoader()
                    loader.write(data)
                    loader.close()

                    # Store in secure user runtime dir
                    base_dir = os.environ.get("XDG_RUNTIME_DIR")
                    if base_dir and os.path.isdir(base_dir):
                        art_dir = os.path.join(base_dir, "waybar-media-art")
                    else:
                        art_dir = os.path.join(tempfile.gettempdir(), f"waybar-media-art-{os.getuid()}")
                    os.makedirs(art_dir, mode=0o700, exist_ok=True)

                    url_hash = hashlib.sha256(url.encode('utf-8')).hexdigest()[:16]
                    dest_path = os.path.join(art_dir, f"cover_{url_hash}.jpg")
                    temp_path = dest_path + f".{os.getpid()}.tmp"

                    with open(temp_path, "wb") as f:
                        f.write(data)
                    os.replace(temp_path, dest_path)
                    os.chmod(dest_path, 0o600)

                    path = dest_path
                    self.temp_cover_files.add(path)

            if url == self.current_cover_url:
                GLib.idle_add(self.set_image, path)
        except Exception:
            if url == self.current_cover_url:
                GLib.idle_add(self.set_image, None)

    def set_image(self, path):
        if path:
            css = f"#media-popup #cover {{ background-image: url('file://{path}'); background-size: cover; background-position: center; }}"
        else:
            css = "#media-popup #cover { background-image: none; background-color: @workspace_border; }"

        if hasattr(self, 'cover_provider') and self.cover_provider:
            try:
                self.cover_box.get_style_context().remove_provider(self.cover_provider)
            except Exception:
                pass

        self.cover_provider = Gtk.CssProvider()
        self.cover_provider.load_from_data(css.encode('utf-8'))
        self.cover_box.get_style_context().add_provider(
            self.cover_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def update_play_button(self):
        if not self.active_player:
            return
        status = self.active_player.props.playback_status
        if status == Playerctl.PlaybackStatus.PLAYING:
            self.img_play.set_from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.BUTTON)
        else:
            self.img_play.set_from_icon_name("media-playback-start-symbolic", Gtk.IconSize.BUTTON)

        # Update shuffle button
        try:
            shuffle = self.active_player.props.shuffle
            self.btn_shuffle.set_name("ctrl-btn-small-active" if shuffle else "ctrl-btn-small")
        except Exception:
            self.btn_shuffle.set_name("ctrl-btn-small")

        # Update repeat button
        try:
            loop = self.active_player.props.loop_status
            if loop == Playerctl.LoopStatus.TRACK:
                self.img_repeat.set_from_icon_name("media-playlist-repeat-song-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small-active")
            elif loop == Playerctl.LoopStatus.PLAYLIST:
                self.img_repeat.set_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small-active")
            else:
                self.img_repeat.set_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small")
        except Exception:
            self.img_repeat.set_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
            self.btn_repeat.set_name("ctrl-btn-small")

    def update_position(self):
        if self.active_player and not self.dragging:
            try:
                pos = self.active_player.get_position() / 1000000.0
                length = self.active_player.print_metadata_prop("mpris:length")
                length = float(length) / 1000000.0 if length else 0

                if length > 0:
                    self.slider.set_range(0, length)
                    self.slider.set_value(pos)
                    self.lbl_len.set_text(format_time(length))
                self.lbl_pos.set_text(format_time(pos))
            except Exception:
                pass
        return True

    def on_slider_press(self, widget, event):
        self.dragging = True
        return False

    def on_slider_release(self, widget, event):
        self.dragging = False
        if self.active_player:
            val = self.slider.get_value()
            try:
                self.active_player.set_position(int(val * 1000000))
            except Exception:
                pass
        return False

    def on_slider_changed(self, scale, scroll, val):
        if self.active_player:
            self.lbl_pos.set_text(format_time(val))
        return False

    def on_shuffle(self, *args):
        if not self.active_player:
            return
        try:
            current = self.active_player.props.shuffle
            new_state = not current
            self.active_player.set_shuffle(new_state)
            self.btn_shuffle.set_name("ctrl-btn-small-active" if new_state else "ctrl-btn-small")
        except Exception:
            pass

    def on_repeat(self, *args):
        if not self.active_player:
            return
        try:
            current = self.active_player.props.loop_status
            if current == Playerctl.LoopStatus.NONE:
                self.active_player.set_loop_status(Playerctl.LoopStatus.PLAYLIST)
                self.img_repeat.set_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small-active")
            elif current == Playerctl.LoopStatus.PLAYLIST:
                self.active_player.set_loop_status(Playerctl.LoopStatus.TRACK)
                self.img_repeat.set_from_icon_name("media-playlist-repeat-song-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small-active")
            else:
                self.active_player.set_loop_status(Playerctl.LoopStatus.NONE)
                self.img_repeat.set_from_icon_name("media-playlist-repeat-symbolic", Gtk.IconSize.BUTTON)
                self.btn_repeat.set_name("ctrl-btn-small")
        except Exception:
            pass

    def on_prev(self, *args):
        if self.active_player:
            try:
                self.active_player.previous()
            except Exception:
                pass

    def on_next(self, *args):
        if self.active_player:
            try:
                self.active_player.next()
            except Exception:
                pass

    def on_play_pause(self, *args):
        if self.active_player:
            try:
                self.active_player.play_pause()
            except Exception:
                pass

if __name__ == "__main__":
    win = MediaPopup()
    win.show_all()
    win.present()
    Gtk.main()

