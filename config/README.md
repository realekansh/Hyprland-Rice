<h1 align="center">Hyprland Dotfiles</h1>

<p align="center">
  My daily-driver desktop configuration for an Arch Linux laptop, built around Hyprland, Catppuccin Mocha aesthetics, and a keyboard-first workflow.
</p>

<p align="center">
  <a href="https://archlinux.org/">
    <img src="https://img.shields.io/badge/Arch_Linux-Wayland-1793d1?style=flat-square&logo=arch-linux&logoColor=white" alt="Arch Linux">
  </a>
  <a href="https://hyprland.org/">
    <img src="https://img.shields.io/badge/Hyprland-Lua-00c8a0?style=flat-square&logo=hyprland&logoColor=white" alt="Hyprland">
  </a>
  <a href="https://github.com/catppuccin/catppuccin">
    <img src="https://img.shields.io/badge/Theme-Catppuccin_Mocha-cba6f7?style=flat-square" alt="Catppuccin Mocha">
  </a>
  <a href="https://github.com/realekansh/dotfiles/commits/main">
    <img src="https://img.shields.io/github/last-commit/realekansh/dotfiles?style=flat-square&color=89b4fa&label=Last%20Commit" alt="Last Commit">
  </a>
  <a href="https://github.com/realekansh/dotfiles/stargazers">
    <img src="https://img.shields.io/github/stars/realekansh/dotfiles?style=flat-square&color=f9e2af" alt="Stars">
  </a>
  <a href="https://github.com/realekansh/dotfiles/issues">
    <img src="https://img.shields.io/github/issues/realekansh/dotfiles?style=flat-square&color=eba0ac" alt="Issues">
  </a>
</p>

---

## Introduction

These are my personal dotfiles for an Arch Linux laptop running Wayland.

This setup is the environment I use every day for programming, writing, and general work. It is built around Hyprland with a keyboard-driven workflow, quiet Catppuccin Mocha colors, and practical system controls that stay out of the way. Rather than setting up complex animations or excessive desktop widgets, the focus is on fast window management, good contrast, and hardware controls that work predictably.

---

## Screenshot

The visual arrangement is kept clean and lightweight: a discreet status bar with essential system meters, tiled windows with gentle rounded corners and subtle border gradients, and translucent terminal windows that remain easy to read across different wallpapers.

```text
+------------------------------------------------------------------------------------+
|  [Apps]  10:45 AM  Artist - Track Title     1 2 [3] 4 5     CPU: 12%  RAM: 4.2G  󰂂 |
+------------------------------------------------------------------------------------+
|                                                                                    |
|   +-----------------------------+       +--------------------------------------+   |
|   | Kitty                       |       | Editor / File Manager                |   |
|   |  󰣇 ~/Projects/dotfiles main |       | 1:3:4 split, full border             |   |
|   |  ❯ sudo pacman -Syu         |       | Real-time Git status, file preview   |   |
|   |                             |       |                                      |   |
|   +-----------------------------+       +--------------------------------------+   |
|                                                                                    |
+------------------------------------------------------------------------------------+
```

> [!NOTE]
> Desktop screenshots and workflow recordings will be placed in `docs/screenshots/`.

---

## Documentation

| Document | Description |
| --- | --- |
| [docs/README.md](docs/README.md) | Documentation home, sitemap, and reading paths |
| [Architecture](docs/architecture/overview.md) | System design, process hierarchy, and modular Lua structure |
| [Components](docs/components/hyprland.md) | Window manager, UI widgets, and application configurations |
| [Keybindings](docs/workflow/keybindings.md) | Complete keyboard and mouse shortcut reference |
| [Workflow & Scripts](docs/workflow/scripts.md) | Automation scripts, wallpaper shuffler, and system controls |
| [Customization](docs/customization/appearance.md) | Displays, appearance, application defaults, and theming |
| [Troubleshooting](docs/troubleshooting/common-issues.md) | Diagnostic checks and practical fixes for common issues |

**Start here:** [docs/README.md](docs/README.md).

---

## How I Organized It

The repository keeps configurations separated by application rather than bundled into large monolithic files:

```text
dotfiles/
├── hypr/        # Hyprland Lua modules, hyprlock, hypridle, hyprpaper, scripts
├── ags/         # Aylur's GTK Shell widgets (media player and telemetry)
├── rofi/        # Launchers and custom applets (battery, wifi, bluetooth, power)
├── swaync/      # Notification center styling and widgets
├── wlogout/     # Session menu layout and local icons
├── kitty/       # Primary terminal configuration
├── alacritty/   # Alternative terminal configuration
├── yazi/        # Terminal file manager configuration and plugins
├── btop/        # Terminal resource monitor theme
├── fastfetch/   # System fetch branding and ASCII logos
└── .bashrc      # Fallback Bash configuration
```

Hyprland itself uses native Lua configuration (Hyprland 0.55+). The entry point `hypr/hyprland.lua` loads dedicated modules for each concern—monitors, input, appearance, animations, keybindings, window rules, and startup commands—so changing one aspect of the setup does not require touching anything else.

---

## Notes & Compatibility

* **Target platform**: Arch Linux
* **Session**: Pure Wayland (X11 is not supported)
* **Compositor**: Hyprland (version 0.55 or newer is required for native Lua configuration support)
* **Hardware profile**: Configured for an x86_64 laptop. Touchpad gestures, battery monitors, and brightness controls rely on standard Linux kernel interfaces (`/sys/class/power_supply`, `/sys/class/backlight`)
* **Personal setup**: These files reflect my personal hardware and preferences. If you choose to use them, review the files first and adapt paths and monitor settings to match your own machine

---

## License

This repository does not specify an overarching open-source license for the personal configuration collection. Third-party themes, assets, and plugins included in this repository (such as Alacritty themes and Yazi plugins) remain subject to their respective upstream licenses.

---

## Credits

This setup builds on work from several open-source projects:

* [Hyprland](https://hyprland.org/) by Vaxry and contributors
* [Catppuccin](https://github.com/catppuccin/catppuccin) for the color palette
* [Aylur's GTK Shell (AGS)](https://github.com/Aylur/ags) by Aylur
* [Rofi](https://github.com/davatorium/rofi) by Dave Davenport and contributors
* [Sway Notification Center](https://github.com/erikreider/SwayNotificationCenter) by Erik Reider
* [Wlogout](https://github.com/ArtsyMacaw/wlogout) by ArtsyMacaw
* [Kitty](https://sw.kovidgoyal.net/kitty/) by Kovid Goyal
* [Yazi](https://yazi-rs.github.io/) by sxyazi and community plugin authors

---

<p align="center">
  <i>Configured for daily use. Take what's helpful, change what isn't.</i>
</p>
