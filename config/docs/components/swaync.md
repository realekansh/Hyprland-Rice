# SwayNC (Sway Notification Center)

SwayNC handles desktop notification popups and provides a slide-out control center panel.

---

## Configuration Files

* `swaync/config.jsonc` — Daemon configuration, widget layout, and timeouts.
* `swaync/style.css` — Panel stylesheet and card layout.
* `swaync/themes/catppuccin-mocha.css` — Color tokens.

---

## Configuration Highlights

* **Layer**: Overlay layer for notifications; top layer for control center.
* **Geometry**: Panel width `320px`, height `420px`. Notification cards are `310px` wide.
* **Timeouts**: Low urgency notifications timeout in 3s; normal urgency in 6s; critical notifications persist until dismissed (`0s`).
* **Widgets**:
  * `title`: Header displaying "Notifications" and a "Clear All" button.
  * `dnd`: "Do Not Disturb" toggle switch that silences popup banners.
  * `notifications`: Scrollable history of received notification cards.

---

## Theming & Styling

SwayNC is styled with Catppuccin Mocha tokens:
* **Background**: Semi-transparent dark slate panel (`@cc_bg`) with `16px` border radius.
* **Cards**: Rounded cards (`12px`) with subtle border highlights and app icon padding.
* **Critical Alerts**: Critical notifications receive a solid red left border indicator (`border-left: 4px solid @red`) and red summary typography.
* **Layer Blur**: Blurred by Hyprland using `hl.layer_rule` for `swaync-control-center` and `swaync-notification-window`.

---

## Lockscreen Integration

Unread notification counts are queried by `hypr/hyprlock/scripts/notifications.sh` using `swaync-client -c` to display an active counter on the lock screen surface.

---

## Related Documents

* [Hyprlock](../components/hyprlock.md)
* [Hyprland Window Rules](../components/hyprland.md)
