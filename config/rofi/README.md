# Custom Translucent Rofi Theme

A clean, modern, and minimalist Rofi configuration featuring a 40% translucent black background, dynamic search layouts, and smooth padding alignments.

![Rofi Preview](https://placeholder.com) <!-- Replace with a path to your screenshot if desired -->

## Features

- **40% Transparency**: Implements custom RGBA hex channels to overlay smoothly on desktop wallpapers.
- **Consistent Layout Polish**: Carefully measured internal margins (`mainbox` padding) and row spacing prevent elements from looking cramped.
- **Unified Text Contrast**: Highlights the selected row using crisp, maximum-contrast white typography over an elegant dark gray focus block.
- **Clean Input Structure**: Custom `Apps : Search` prompt design with a tailored placeholder field.

---

## Code Breakdown

The configuration file is divided into four highly organized components:

### 1. Engine Configuration (`configuration {}`)
This block controls Rofi’s internal operational behavior and launcher settings:
* `font`: Sets system-wide typography (`JetBrains Mono`).
* `modi`: Enables application launching (`drun`), binary execution (`run`), and directory navigation (`filebrowser`).
* `show-icons`: Displays application brand icons next to list names.
* `hover-select`: Automatically shifts row highlight focus to track the mouse cursor movement.

### 2. Global Variables (`* {}`)
A central color palette declaration making adjustments simple and modular:
* `background: #00000066`: The primary window backdrop. The `66` hex suffix restricts the opacity channel strictly to `40%`.
* `background-selected`: The opaque dark focus bar behind active rows.
* `accent`: A modern system-blue theme color used for framing and emphasis.

### 3. Layout Frame Containers
Handles the structural spacing and dimensional limits of the interface window:
* `window`: Enforces a fixed modal constraint (`30%` screen width, `40%` screen height) along with smooth matching border corners (`8px`).
* `mainbox`: Acts as the invisible inner padding wall pushing content cleanly away from the window's outer blue frame.
* `listview`: Constrains rendering blocks cleanly to a maximum structure of 8 visible vertical item rows.

### 4. Search and Row Element Modules
Styles individual interface items to avoid standard text-clashing behaviors:
* `inputbar`: Restructures order logic using internal text arrays (`prompt -> colon -> entry`) while giving space right below it.
* `element`: Implements universal transparency overrides across both `normal` and `alternate` list states to destroy default "striped row" backgrounds.
* `element-icon`: Sets a locked layout dimension (`24px`) with a explicit right-hand margin to keep app icons from brushing against title labels.

---

## Installation and Usage

### Prerequisites
To see the window transparency correctly, your Linux desktop setup **must have an active compositor running**. Examples include:
* **X11**: `picom` or `compton`
* **Wayland**: Built-in compositors like Hyprland, Sway, or Wayfire handle this natively.

### Steps to Apply

1. Locate your local Rofi theme directory (usually `~/.config/rofi/`).
2. Save the configuration code into a file named `config.rasi`:
   ```bash
   nano ~/.config/rofi/config.rasi
   ```
3. Test your theme immediately from the terminal using the command flag:
   ```bash
   rofi -show drun -theme ~/.config/rofi/config.rasi
   ```

### Binding to Key Shortcuts
To activate this launcher seamlessly with a hotkey change the local launcher variable inside ~/.config/hypr/config/keybinds.lua, map the launcher string directly into your window manager configuration file

```bash
# Example for Hyprland
local launcher    = "rofi -show drun"
```

---
License: MIT - Feel free to modify and share!
