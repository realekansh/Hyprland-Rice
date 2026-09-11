# Yazi Terminal File Manager Configuration

A practical, high-performance, maintainable configuration for **Yazi** fully integrated into the Hyprland / Catppuccin Mocha desktop ecosystem.

---

## 📁 Configuration Structure

```text
~/.config/yazi/
├── yazi.toml      # Core manager, previewer, opener, and plugin configurations
├── theme.toml     # Catppuccin Mocha palette, status bar, file colors & Nerd Font icons
├── keymap.toml    # Custom keybindings prepended over default Yazi controls
├── init.lua       # Plugin initialization (Git status & Full-border UI)
├── package.toml   # Managed plugin dependencies (ya pkg)
└── README.md      # Configuration documentation
```

---

## 🎨 Design & Theme

- **Palette**: Catppuccin Mocha (`#89b4fa` Accent, `#313244` Surface, `#cdd6f4` Text, `#1e1e2e` Background).
- **Typography**: JetBrainsMono Nerd Font.
- **Icons**: Nerd Font v3 icons matching Waybar/Rofi icon conventions for directories, file extensions, and special filenames.
- **Layout**: 1:3:4 split ratio (parent, active directory, preview pane) with rounded full borders.

---

## 🔌 Plugins Installed (`ya pkg`)

1. **`git.yazi`** (`yazi-rs/plugins:git`):
   Real-time Git file state and repository indicators (modified, added, untracked, deleted).
2. **`chmod.yazi`** (`yazi-rs/plugins:chmod`):
   Interactive file permission editor bound to `C`.
3. **`full-border.yazi`** (`yazi-rs/plugins:full-border`):
   Full UI border renderer for a clean, unified aesthetic.

---

## ⌨️ Key Customizations & Keybindings

| Binding | Action | Description |
| :--- | :--- | :--- |
| `C` | `plugin chmod` | Interactively modify file permissions |
| `y p` | `copy path` | Copy absolute file path to Wayland clipboard (`wl-copy`) |
| `y d` | `copy dirname` | Copy parent directory path to clipboard |
| `y n` | `copy filename` | Copy filename to clipboard |
| `.` | `hidden toggle` | Toggle visibility of hidden files |
| `T` | `tab_create --current` | Create new tab in current working directory |
| `Ctrl+n` | `shell 'nvim .'` | Launch Neovim in current directory |
| `Ctrl+s` | `shell '$SHELL'` | Open interactive shell in current directory |

---

## 🐚 Shell Integration

The shell wrapper function `y` is configured in `~/.bashrc`:

```bash
y
```

Running `y` instead of `yazi` launches Yazi and automatically changes your terminal's current working directory (`cd`) to the directory you were in when exiting.

---

## 📦 Dependencies

### Required
- `yazi` / `ya`: Terminal file manager binary & package manager.
- `git`: Version control and repository status.

### Recommended (Previews & Search)
- `bat`: Syntax highlighting for code/text previews.
- `jq`: Formatted JSON previews.
- `chafa`: Terminal graphics image previewer.
- `pdftoppm` (`poppler`): High-resolution PDF previews.
- `ffmpegthumbnailer`: Video thumbnail generation.
- `7z`: Archive file previewing and extraction.
- `fd` & `rg`: Fast file finding and text searching.
- `fzf`: Interactive fuzzy searching.

### Desktop Handlers (Openers)
- **Editor**: `nvim` / `vim` / `$EDITOR`
- **Images**: `loupe` / `xdg-open`
- **PDFs**: `evince` / `xdg-open`
- **Videos**: `vlc` / `totem` / `xdg-open`
- **Audio**: `vlc` / `xdg-open`
- **Graphical Manager**: `nautilus`

---

## 🛠 Maintenance & Updates

To upgrade installed plugins:

```bash
ya pkg upgrade
```

To validate configuration syntax:

```bash
yazi --debug
```
