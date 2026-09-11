#!/usr/bin/env python3
import sys
import os
import subprocess
import signal
import json

STATE_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "waybar-media-active-player")

def handle_control(action: str):
    """
    Executes a media control action targeting the canonical active player.
    """
    target = None
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                target = f.read().strip()
        except Exception:
            target = None

    cmd = ["playerctl"]
    if target:
        cmd.extend(["--player", target])
    cmd.append(action)

    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass
    sys.exit(0)

# Fast-path for control actions from Waybar clicks/scrolls
if len(sys.argv) > 1 and sys.argv[1] == "--cmd":
    if len(sys.argv) > 2:
        handle_control(sys.argv[2])
    sys.exit(0)

# Daemon setup
signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib

SCROLL_LIMIT = 40
SCROLL_SPEED = 0.25  # seconds

KNOWN_PLAYERS = {
    "spotify": ("spotify", ""),
    "mpv": ("mpv", ""),
    "vlc": ("vlc", "󰕼"),
    "firefox": ("firefox", ""),
    "chromium": ("chromium", ""),
    "chrome": ("chromium", ""),
    "google-chrome": ("chromium", ""),
    "brave": ("chromium", ""),
    "edge": ("chromium", ""),
    "microsoft-edge": ("chromium", ""),
    "opera": ("chromium", ""),
    "vivaldi": ("chromium", ""),
    "youtube-music": ("youtube-music", ""),
    "youtube music": ("youtube-music", ""),
    "fooyin": ("fooyin", ""),
    "lollypop": ("lollypop", ""),
    "apple-music": ("apple-music", ""),
    "apple music": ("apple-music", ""),
    "amberol": ("amberol", ""),
    "rhythmbox": ("rhythmbox", ""),
    "audacious": ("audacious", ""),
    "cider": ("apple-music", ""),
}

def normalize_player(raw_name: str) -> tuple[str, str]:
    """
    Returns (canonical_base_name, icon).
    Normalizes instances like 'chromium.instance1234' -> ('chromium', '')
    and 'firefox.instance_user_1' -> ('firefox', '').
    """
    if not raw_name:
        return ("default", "")

    name = raw_name.lower().strip()

    # 1. Exact match against known players
    if name in KNOWN_PLAYERS:
        return KNOWN_PLAYERS[name]

    # 2. Check for instance suffixes (e.g. name.instance*, name-instance*)
    for known_key, (base_name, icon) in KNOWN_PLAYERS.items():
        if name.startswith(f"{known_key}.") or name.startswith(f"{known_key}-"):
            return (base_name, icon)

    # 3. Substring check if known_key is within the name (e.g. "google-chrome-stable")
    for known_key, (base_name, icon) in KNOWN_PLAYERS.items():
        if known_key in name:
            return (base_name, icon)

    # 4. Unknown player fallback: preserve base name without trailing instance ids
    cleaned = name.split(".")[-1] if "." in name and not name.startswith("instance") else name
    return (cleaned, "")

class Scroller:
    def __init__(self):
        self.manager = Playerctl.PlayerManager()
        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)

        self.active_player = None
        self.current_icon = ""
        self.current_class = "stopped"

        self.scroll_idx = 0
        self.scroll_text = ""
        self.is_playing = False

        self.timer_id = None
        self.last_payload = None

        for name in self.manager.props.player_names:
            self.init_player(name)

    def sync_active_player_state(self, player_name: str | None):
        """
        Persists the canonical active player identity to XDG_RUNTIME_DIR
        for control actions (play-pause, next, previous).
        """
        try:
            if player_name:
                with open(STATE_FILE, "w") as f:
                    f.write(player_name)
            else:
                if os.path.exists(STATE_FILE):
                    os.remove(STATE_FILE)
        except Exception:
            pass

    def update_scroll_timer_state(self):
        """
        Reconciles the 250ms GLib scroll timer state based on whether
        active scrolling is genuinely needed:
        - PLAYING + text length > SCROLL_LIMIT -> timer ON
        - All other states (NO PLAYER, STOPPED, PAUSED, short title) -> timer OFF
        """
        needs_scrolling = self.is_playing and len(self.scroll_text) > SCROLL_LIMIT

        if needs_scrolling:
            if self.timer_id is None:
                self.timer_id = GLib.timeout_add(int(SCROLL_SPEED * 1000), self.tick)
        else:
            if self.timer_id is not None:
                try:
                    GLib.source_remove(self.timer_id)
                except Exception:
                    pass
                self.timer_id = None

    def init_player(self, name):
        player = Playerctl.Player.new_from_name(name)
        player.connect("playback-status", self.on_status)
        player.connect("metadata", self.on_metadata)
        self.manager.manage_player(player)

    def on_player_appeared(self, manager, name):
        self.init_player(name)
        self.update_state()

    def on_player_vanished(self, manager, name):
        self.update_state()

    def update_state(self):
        players = self.manager.props.players
        if not players:
            self.active_player = None
            self.is_playing = False
            self.current_class = "stopped"
            self.scroll_text = ""
            self.current_icon = ""
            self.sync_active_player_state(None)
            self.update_scroll_timer_state()
            self.output()
            return

        # Canonical active player selection
        active = None

        # 1. Prefer current active player if it is still playing
        if self.active_player in players and self.active_player.props.playback_status == Playerctl.PlaybackStatus.PLAYING:
            active = self.active_player

        # 2. Otherwise find the first playing player
        if not active:
            for p in players:
                if p.props.playback_status == Playerctl.PlaybackStatus.PLAYING:
                    active = p
                    break

        # 3. Prefer current active player if it is paused
        if not active and self.active_player in players and self.active_player.props.playback_status == Playerctl.PlaybackStatus.PAUSED:
            active = self.active_player

        # 4. Otherwise find the first paused player
        if not active:
            for p in players:
                if p.props.playback_status == Playerctl.PlaybackStatus.PAUSED:
                    active = p
                    break

        # 5. Fallback to first player
        if not active:
            active = players[0]

        # Check if active player is stopped
        if active.props.playback_status == Playerctl.PlaybackStatus.STOPPED:
            self.active_player = None
            self.is_playing = False
            self.current_class = "stopped"
            self.scroll_text = ""
            self.current_icon = ""
            self.sync_active_player_state(None)
            self.update_scroll_timer_state()
            self.output()
            return

        self.active_player = active
        self.is_playing = (active.props.playback_status == Playerctl.PlaybackStatus.PLAYING)
        self.current_class = "playing" if self.is_playing else "paused"

        raw_name = getattr(active.props, "player_name", "") or ""
        base_name, icon = normalize_player(raw_name)
        self.current_icon = icon
        self.sync_active_player_state(raw_name)

        artist = active.get_artist() or ""
        title = active.get_title() or ""
        if artist and title:
            text = f"{title} - {artist}"
        else:
            text = title or artist or "Unknown"

        if text != self.scroll_text:
            self.scroll_text = text
            self.scroll_idx = 0

        self.update_scroll_timer_state()
        self.output()

    def on_status(self, player, status):
        self.update_state()

    def on_metadata(self, player, metadata):
        self.update_state()

    def emit_json(self, out: dict):
        try:
            sys.stdout.write(json.dumps(out) + "\n")
            sys.stdout.flush()
        except (BrokenPipeError, IOError):
            try:
                sys.stdout.close()
            except Exception:
                pass
            os._exit(0)

    def output(self):
        if not self.scroll_text or self.current_class == "stopped":
            out = {
                "text": "",
                "alt": "stopped",
                "class": "stopped",
                "tooltip": ""
            }
            if out != self.last_payload:
                self.last_payload = out
                self.emit_json(out)
            return

        display_text = self.scroll_text
        if len(display_text) > SCROLL_LIMIT:
            padded = display_text + "   •   "
            idx = self.scroll_idx % len(padded)
            display_text = (padded + padded)[idx:idx+SCROLL_LIMIT]

        full_text = f"{self.current_icon} {display_text}" if self.current_icon else display_text
        raw_name = getattr(self.active_player.props, "player_name", "") if self.active_player else "default"
        base_name, _ = normalize_player(raw_name)

        out = {
            "text": full_text,
            "alt": base_name,
            "class": [self.current_class, base_name],
            "tooltip": self.scroll_text
        }
        if out != self.last_payload:
            self.last_payload = out
            self.emit_json(out)

    def tick(self):
        # 1. Verify active scrolling is still required
        if not (self.is_playing and len(self.scroll_text) > SCROLL_LIMIT):
            self.timer_id = None
            return False  # GLib removes the timeout source

        # 2. Advance scroll position and emit frame
        self.scroll_idx += 1
        self.output()
        return True

if __name__ == "__main__":
    s = Scroller()
    s.update_state()
    GLib.MainLoop().run()

