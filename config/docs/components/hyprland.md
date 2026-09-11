# Hyprland

Hyprland is the Wayland tiling compositor that serves as the foundation of the desktop. It manages window tiling, animations, display scaling, and compositor blur.

---

## Configuration Files

* `hypr/hyprland.lua` — Main loader.
* `hypr/hyprland/monitors.lua` — Display outputs and scaling.
* `hypr/hyprland/appearance.lua` — Gaps, borders, blur, and shadows.
* `hypr/hyprland/animations.lua` — Physics curves and transitions.
* `hypr/hyprland/input.lua` — Keyboard repeat and touchpad gestures.
* `hypr/hyprland/keybinds.lua` — Keyboard shortcuts and dispatchers.
* `hypr/hyprland/rules.lua` — Window and layer blur rules.
* `hypr/hyprland/startup.lua` — Autostart commands and environment setup.

---

## Layout & Appearance

Hyprland is configured with the **dwindle** layout:
* **Inner Gaps**: `5px` between adjacent tiled windows.
* **Outer Gaps**: `10px` between windows and screen edges.
* **Borders**: `2px` border width. Active windows render a 45° gradient blending `#cdd6f4`, `#c7bdd3`, and `#676a80`. Inactive windows have a subtle `#333333` border.
* **Corner Rounding**: `8px` corner radius (`rounding_power = 2`).
* **Shadows**: Enabled with `range = 6` and `render_power = 3`.
* **Compositor Blur**: 3 passes with a size of 3 and vibrancy of `0.1696`.

---

## Animations

Window physics are calibrated for responsiveness rather than lingering movement:
* **Curves**: Custom named beziers (`easeOutQuint`, `easeInOutCubic`, `almostLinear`, `quick`).
* **Spring Model**: Windows use a stiff spring named `snappy` (`mass = 1, stiffness = 170, dampening = 20`) so windows snap into place without overshoot bounce.
* **Workspaces**: Workspace switches slide smoothly using trackpad gestures or hotkeys (`easeInOutCubic` curve with `slide` style).

---

## Window & Layer Rules

Rules declared in `hypr/hyprland/rules.lua` manage application behavior and visual effects:

### Maximize & XWayland Guards
* Browser and application maximize events are suppressed (`suppress-maximize-events`) to prevent applications from breaking tiling layout on startup.
* Empty XWayland drag surfaces are stripped of focus (`fix-xwayland-drags`) to prevent focus theft.

### Layer Blur Rules
Layer shell surfaces have background blur and alpha ignore thresholds enabled:
* `waybar` — Blur enabled with `ignore_alpha = 0.2`.
* `swaync-control-center` & `swaync-notification-window` — Blur enabled with `ignore_alpha = 0.2`.
* `wlogout` & `gtk-layer-shell` — Blur enabled with `ignore_alpha = 0.0`.

### Window Floating & Centering Rules
Utility windows are configured to float and open centered automatically:
* `pavucontrol` — Floats, centered, sized at `900x600`.
* `blueman-manager` — Floats, centered.
* `nwg-look` — Floats, centered.

---

## Touchpad & Gestures

Configured in `hypr/hyprland/input.lua`:
* **Tap-to-click**: Enabled.
* **Natural scroll**: Enabled.
* **Drag lock**: Enabled (`drag_lock = 1`).
* **Typing protection**: `disable_while_typing = true`.
* **Workspace Gestures**: 3-finger horizontal swipe triggers native 1:1 workspace transitions.

---

## Related Documents

* [Keybindings Reference](../workflow/keybindings.md)
* [Monitors Customization](../customization/monitors.md)
* [Appearance Customization](../customization/appearance.md)
