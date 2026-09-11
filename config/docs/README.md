# Documentation Index

Welcome to the technical documentation for this Hyprland dotfiles repository. This documentation provides a comprehensive guide to how the desktop environment is constructed, how individual components behave, and how to customize the setup for your own workflow.

> [!NOTE]
> Installation and system provisioning are maintained separately on the **GitHub Wiki**. This documentation focuses exclusively on architecture, component behavior, workflows, customization, and troubleshooting.

---

## Documentation Structure

```text
docs/
├── architecture/         # System design, process hierarchy, and modularity
├── components/           # Deep dives into individual applications and daemons
├── workflow/             # Keybindings, scripts, automation, and hardware controls
├── customization/        # Step-by-step guides for displays, apps, and aesthetics
└── troubleshooting/      # Practical fixes for common issues
```

---

## Reading Paths

### 1. Architecture & System Design
Understand how the environment connects from the Wayland compositor down to kernel interfaces:
* [Architecture Overview](architecture/overview.md) — Process tree, layer shell surfaces, and inter-process communication.
* [Hyprland Lua Architecture](architecture/hyprland.md) — Modular Lua configuration pattern, loading order, and API structure.

### 2. Component Reference
Detailed implementation notes for every application configured in this repository:
* [Hyprland](components/hyprland.md) — Window manager, tiling rules, layout physics, and layer blur.
* [AGS (Aylur's GTK Shell)](components/ags.md) — MPRIS media player widget and live hardware telemetry popup.
* [Rofi](components/rofi.md) — Application launchers and custom applets (battery, wifi, bluetooth, network, vpn, power).
* [SwayNC](components/swaync.md) — Notification center, widget layout, Do Not Disturb, and lockscreen integration.
* [Wlogout](components/wlogout.md) — Session menu overlay, button geometry, and system power actions.
* [Kitty](components/kitty.md) — Primary terminal, font sizing, padding, blur, and opacity.
* [Alacritty](components/alacritty.md) — Secondary terminal emulator and theme importing system.
* [Yazi](components/yazi.md) — Terminal file manager, Git integration, file permissions, and shell wrappers.
* [Hyprlock](components/hyprlock.md) — Screen locker, multi-pass background blur, typography, and status scripts.
* [Hypridle](components/hypridle.md) — Idle listener timeouts, backlight dimming, and suspend automation.
* [Hyprpaper](components/hyprpaper.md) — Wallpaper daemon, cover-fit rendering, and IPC controls.
* [Hyprsunset](components/hyprsunset.md) — Gamma and blue light temperature management.
* [Btop](components/btop.md) — Resource monitor configuration and transparency settings.
* [Fastfetch](components/fastfetch.md) — System fetch configuration, ASCII branding, and presets.

### 3. Workflow & Automation
Everyday interaction patterns, keybindings, and automation scripts:
* [Keybindings Reference](workflow/keybindings.md) — Complete dispatch table of all keyboard and mouse shortcuts.
* [Scripts & Utilities](workflow/scripts.md) — Maintenance, wallpaper shuffler, night mode toggle, and lockscreen scripts.
* [Wallpaper Workflow](workflow/wallpapers.md) — Storage, selection, multi-daemon synchronization, and theme reload hooks.
* [System Controls](workflow/system-controls.md) — Audio (`wpctl`), backlight (`brightnessctl`), CPU power profiles, and networking.

### 4. Customization Guides
Modify the desktop to suit your own hardware and visual preferences:
* [Monitors & Displays](customization/monitors.md) — Resolution, refresh rate, HiDPI scaling, and multi-monitor setups.
* [Default Applications](customization/applications.md) — Changing default terminal, browser, file manager, and launcher.
* [Appearance & Layout](customization/appearance.md) — Modifying gaps, border widths, corner rounding, blur, and shadows.
* [Theming System](customization/theming.md) — Catppuccin Mocha color palette distribution and tokens.
* [Typography & Fonts](customization/fonts.md) — Font definitions across terminals, bars, menus, and lockscreen.

### 5. Troubleshooting
* [Common Issues](troubleshooting/common-issues.md) — Solutions for Lua loading errors, missing glyphs, CPU profile permissions, and backlight controls.
