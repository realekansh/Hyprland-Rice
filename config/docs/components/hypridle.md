# Hypridle

Hypridle is the idle management daemon for Hyprland. It coordinates screen dimming, idle notifications, display sleep (DPMS), and system suspension.

---

## Configuration File

* `hypr/hypridle.conf` — Idle listener timeouts and dispatch commands.

---

## Idle Lifecycle Timers

Hypridle executes actions at progressive stages of inactivity:

| Inactivity | Action | Command | Resume Action |
| :--- | :--- | :--- | :--- |
| **120s** (2m) | Notification | `notify-send ":/ Your screen is on Idle"` | `notify-send ":) You're back, $USER"` |
| **180s** (2.5m) | Dim Screen | `brightnessctl -s set 50` | `brightnessctl -r` (restores brightness) |
| **180s** (2.5m) | Keyboard Backlight | `brightnessctl -sd rgb:kbd_backlight set 0` | `brightnessctl -rd rgb:kbd_backlight` |
| **300s** (5m) | Lock Screen | `loginctl lock-session` | Unlocked via Hyprlock |
| **330s** (5.5m) | Display Off | `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` | DPMS enabled on activity |
| **1800s** (30m) | Suspend | `systemctl suspend` | Wakes on power button or lid open |

---

## Sleep & Lock Hooks

* **Lock Command**: `lock_cmd = pidof hyprlock || hyprlock` (prevents duplicate instances).
* **Before Sleep**: `before_sleep_cmd = loginctl lock-session` (guarantees screen is locked prior to system suspension).
* **After Sleep**: `after_sleep_cmd = hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'` (turns displays back on immediately so key presses wake the screen).

---

## Related Documents

* [Hyprlock](../components/hyprlock.md)
* [System Controls](../workflow/system-controls.md)
