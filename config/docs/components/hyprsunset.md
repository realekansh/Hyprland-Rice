# Hyprsunset

Hyprsunset is an ambient gamma and color temperature adjustment daemon for Hyprland, used as a night-light filter to reduce eye strain.

---

## Configuration Files

* `hypr/hyprsunset.conf` — Daemon limits and profile templates.
* `hypr/scripts/hyprsunset-toggle.sh` — Toggle script.

---

## Configuration & Limits

* **Maximum Gamma**: `max-gamma = 150` (permits display gamma adjustments up to 150%).
* **Profiles**: Scheduled time-based profiles are commented out by default, leaving activation to the on-demand toggle script.

---

## Toggle Mechanism (`hyprsunset-toggle.sh`)

The filter is toggled dynamically:
1. Tracks active status in `${XDG_RUNTIME_DIR:-/tmp}/hyprsunset_state`.
2. Starts the `hyprsunset` daemon if not already running.
3. If currently **ON**: runs `hyprctl hyprsunset identity` to reset the color matrix to neutral daylight.
4. If currently **OFF**: runs `hyprctl hyprsunset temperature 4000` to apply a warm 4000K night temperature.

---

## Related Documents

* [Scripts & Automation](../workflow/scripts.md)
