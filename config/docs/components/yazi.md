# Yazi

Yazi is a fast, asynchronous terminal file manager built in Rust. It is integrated into the desktop ecosystem with Git badges, custom keymaps, and shell directory synchronization.

---

## Configuration Files

* `yazi/yazi.toml` — Core file manager options, openers, and preview rules.
* `yazi/theme.toml` — Catppuccin Mocha UI tokens and filetype icon mapping.
* `yazi/keymap.toml` — Custom keybindings.
* `yazi/init.lua` — Plugin initialization.
* `yazi/package.toml` — Managed plugin dependencies (`ya pkg`).

---

## Layout & Design

* **Ratio**: `1:3:4` split (parent folder, active directory, preview pane).
* **Theme**: Catppuccin Mocha palette with JetBrains Mono Nerd Font file icons.
* **Borders**: Rendered with full rounded borders via `full-border.yazi`.

---

## Installed Plugins

1. **`git.yazi`**: Displays real-time Git file states (untracked, modified, added, deleted) directly in the file list.
2. **`chmod.yazi`**: Interactive chmod permission editor triggered by pressing `C`.
3. **`full-border.yazi`**: Full UI border renderer for a cohesive terminal frame.

---

## Key Customizations

| Keybinding | Action | Description |
| :--- | :--- | :--- |
| `C` | `plugin chmod` | Interactively modify file permissions |
| `y p` | `copy path` | Copy absolute file path to Wayland clipboard |
| `y d` | `copy dirname` | Copy parent directory path to clipboard |
| `y n` | `copy filename` | Copy filename to clipboard |
| `.` | `hidden toggle` | Toggle hidden dotfiles visibility |
| `T` | `tab_create` | Open a new tab in current working directory |
| `Ctrl + n` | `shell 'nvim .'` | Launch Neovim in the active directory |
| `Ctrl + s` | `shell '$SHELL'` | Spawn a subshell in current directory |

---

## Shell Integration

The shell wrapper function `y` in `~/.bashrc` ensures that when you exit Yazi, your shell's current working directory updates automatically:

```bash
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
```

---

## Related Documents

* [Keybindings Reference](../workflow/keybindings.md)
