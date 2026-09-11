# Comprehensive Changelog & Audit Record

This document provides an exhaustive, chronological, and thematic record of all architectural updates, feature integrations, security hardenings, bug fixes, and package synchronizations performed on this repository.

It cross-references historical lineage from the upstream source dotfiles repository (`~/Projects/Workflows/dotfiles`) with the refactoring and auditing completed in `Hyprland-Rice`.

---

## Table of Contents
1. [Lineage: Upstream Feature & Styling Evolution](#1-lineage-upstream-feature--styling-evolution)
2. [Architectural Refactoring: Installer & Manifest Overhaul](#2-architectural-refactoring-installer--manifest-overhaul)
3. [Audit Findings & Core Fixes (Phase 1)](#3-audit-findings--core-fixes-phase-1)
4. [Runtime Dependency & Package Additions (Phase 2)](#4-runtime-dependency--package-additions-phase-2)
5. [Portability & Multi-User Decoupling (Phase 3)](#5-portability--multi-user-decoupling-phase-3)
6. [Deep-Scan Debugging & Script Resilience (Phase 4)](#6-deep-scan-debugging--script-resilience-phase-4)
7. [Repository Verification & Diff Summary](#7-repository-verification--diff-summary)

---

## 1. Lineage: Upstream Feature & Styling Evolution

The core configuration modules in `config/` were refined through a series of dedicated feature and style commits originating in `~/Projects/Workflows/dotfiles`. Below is the commit genealogy mapping each upstream enhancement to the active configuration:

| Upstream Hash | Upstream Commit Message | Applied Subsystem & Impact |
|---|---|---|
| `640001d` | `feat(hyprland): add a blur rule specifically for kitty` | **Hyprland Rules**: Added dedicated Kitty blur and opacity overrides in `rules.lua`. |
| `7838f22` | `style(hyprland:appearance): refine active border color palette` | **Appearance**: Catppuccin Mocha gradient active borders (Mauve, Lavender, Sapphire at 45°). |
| `f58a55b` | `feat(waybar): refine UI, fix repeat icon, and add screenshot detection` | **Waybar / Media**: Refined media widget status icons and process detection in `media-popup.py`. |
| `a34f29a` | `feat(hyprland) add hypridle for make system hibernate on idle & hyprsunset for reducing bluelight strain` | **Hypr Ecosystem**: Integrated idle escalation in `hypridle.conf` and night-light toggle script. |
| `90dffd6` | `style(hyprlock): removed user details, profile avtar & moved the input to the center` | **Hyprlock**: Cleaned up lockscreen UI, centering input-field with blurred wallpaper background. |
| `ecd22a0` | `fix(modules): repair broken scripts, translate to English, and clean up clutter` | **Waybar Scripts**: Standardized script outputs and translated user-facing text to English. |
| `bbcba54` | `feat(waybar): implement interactive ags system popup and waybar integration` | **Waybar / AGS**: Built `system-popup.py` GTK layer-shell overlay for quick settings. |
| `13924c5` | `fix(hyprland): reduced blur intensity for better performance` | **Hyprland Appearance**: Tuned blur passes to 3 and size to 3 for optimal iGPU frame pacing. |
| `f45f50a` | `feat(hyprland): improve touchpad workspace navigation` | **Hyprland Input**: Enhanced 3-finger horizontal gestures and smooth workspace switching. |
| `faf6776` | `feat(waybar): overhaul modules, theming, and popup scripts` | **Waybar Architecture**: Converted monolithic bar into modular, theme-swappable architecture. |
| `9c87c44` | `feat(hypr): add layer blur rules for SwayNC control center and notifications` | **Hyprland Rules**: Layer rules for `swaync-control-center` and `swaync-notification-window`. |
| `337010a` | `style(swaync): redesign notification center with compact layout and translucent mocha theme` | **SwayNC**: Modern CSS styling matching Catppuccin Mocha desktop glassmorphism. |
| `f624c84` | `feat(btop): add Catppuccin Mocha theme and desktop-aligned configuration` | **Btop**: Shipped `btop.conf` with truecolor, rounded corners, and Catppuccin Mocha palette. |
| `b3de844` | `feat(hypridle): add new fancy message for idle and welcome notification` | **Hypridle**: Progressive idle steps (120s notification, 180s backlight dim, 300s lock, 330s DPMS off, 1800s suspend). |
| `a76852e` | `feat(hyprpaper) changed wallpaper directory for better navigation` | **Hyprpaper**: Standardized wallpaper directory to `~/Pictures/wallpapers`. |
| `37c076f` | `refactor(hyprland): reorganize input and window rules` | **Hyprland Modularization**: Separated monolithic configs into `input.lua`, `rules.lua`, etc. |
| `da535d8` | `feat(hyprsunset): rewrite hyprsunset and created a toggle script for waybar integration` | **Hyprsunset**: Shipped `hyprsunset-toggle.sh` providing smooth 4000K toggle via IPC. |
| `e791e83` | `feat(hyprlock): moved hyprlocked scripts to its dedicated folder and cleared previous junk` | **Hyprlock**: Isolated runtime scripts into `config/hypr/hyprlock/scripts/`. |
| `0f39b87` | `feat(waybar): integrate hyprcaffeine and hyprsunset controls` | **Waybar Custom Modules**: Added clickable status pills for blue-light and sleep inhibitors. |
| `b79e0e3` | `feat(hypr): add new script for system maintainance` | **Maintenance**: Added `sysmaintenance.sh` Arch housekeeping tool with cache/orphan trimming. |
| `7969a1b` | `feat(yazi): configure Yazi file manager with Catppuccin Mocha theme` | **Yazi**: Configured modern terminal file manager with plugins (`full-border`, `chmod`, `git`). |
| `22d29fc` | `feat(ags): import system popup styles` | **AGS**: Imported stylesheet and widget layouts for popup window framework. |
| `8473643` | `feat(hyprland): switch browser keybind to Chromium` | **Hyprland Keybinds**: Updated default browser keybinding. |
| `0aed9f2` | `feat(hyprland): new themes and updated configuration for waybar blur` | **Hyprland Themes**: Added Catppuccin color variants (`latte`, `macchiato`, `frappe`, `mocha`). |
| `3513e0d` | `feat(hyprland): update launcher keybind and add wlogout layer blur rules` | **Hyprland Keybinds/Rules**: Bound Super+Space to Rofi; added wlogout blur layer rule. |
| `f79a242` | `fix(wlogout): fix suspend action with hyprlock and update styling with local icons` | **wlogout**: Bundled local icons and chained `hyprlock` ahead of `systemctl suspend`. |
| `8c31799` | `feat(waybar): integrate rofi applets for bluetooth, network, vpn, battery and logout` | **Waybar Integration**: Linked status bar widgets directly to Rofi applets. |
| `2627321` | `feat(rofi): add custom applet suite for battery, bluetooth, wifi, ethernet, vpn, network and powermenu` | **Rofi Suite**: Deployed multi-style applet scripts and themes. |
| `14f1c2b` | `docs: add comprehensive project documentation and README` | **Documentation**: Authored technical architecture, component manuals, and customization guides. |
| `0de9afa` | `feat(hypr): audit configurations, apply bug fixes, and modernize modular setup` | **Hyprland Lua Engine**: Migrated from legacy `config.*` to modern `hyprland.*` module imports. |
| `82333ea` | `feat(waybar): restructure modular layout into includes and excludes, update scripts and styling` | **Waybar Layout**: Restructured modules into granular JSONC files for flexible inclusion. |
| `6e5c480` | `feat(waybar): add default universal theme and configure as default` | **Waybar Theming**: Established default glassmorphic stylesheet. |
| `0eda88d` | `fix(hypr): use hyprctl dispatch in waybar-reload script` | **Hyprland Scripts**: Fixed Waybar restart mechanism. |
| `103912e` | `feat(waybar): add modular layout system with floating islands and standard bar modes` | **Waybar Layout**: Supported floating island geometry vs docked bars. |
| `a3fc6b7` | `feat(waybar): decouple modules into independent untrapped floating pills` | **Waybar Styling**: Separated widgets into individual floating pills. |
| `34daebf` | `feat(waybar): add accent styling to interactive tiles while preserving neutral glass for metric groups` | **Waybar Styling**: Styled active tiles with Catppuccin accent highlights. |
| `0f6c1e5` | `feat(hypr): provide dual wallpaper shufflers for wallpaper-only and full theme sync` | **Hyprland Scripts**: Shipped `wallpaper-only.sh` (wallpaper) and `wallpaper-theme.sh` (both). |
| `30536b5` | `fix(waybar): fix workspace centering when empty and eliminate icon clipping on multi-window pills` | **Waybar Styling**: Fixed geometry clipping on workspace badge indicators. |
| `d800395` | `feat(waybar): add comfortable spacing between workspace icons and enable dynamic smooth pill sizing` | **Waybar Styling**: Spaced workspace icons and animated size transitions. |
| `4fa983c` | `fix(waybar): remove fixed min-width constraints for slim, content-driven dynamic workspace sizing` | **Waybar Styling**: Enabled adaptive pill sizing without fixed min-width bottlenecks. |
| `60abf5f` | `feat(waybar): add 3D elevation groove to active workspace, interactive hover animation, and tighten icon spacing` | **Waybar Styling**: Added box-shadow depth and tactile feedback to the active workspace. |
| `8b41774` | `fix(waybar): implement state-conditional padding to prevent right-corner icon clipping and collapse empty badges` | **Waybar Styling**: Resolved corner clipping on workspace elements. |
| `736a52f` | `fix(waybar): restore original compact workspace pill dimensions with active groove` | **Waybar Styling**: Finalized balanced, compact dimensions for workspace indicators. |

---

## 2. Architectural Refactoring: Installer & Manifest Overhaul

The installation subsystem was overhauled from brittle monolithic scripts into a logged, modular, and reversible transaction engine:

### Legacy Scripts Removed
- `scripts/config-manager.sh`
- `scripts/detect-distro.sh`
- `scripts/install-aur-helper.sh`
- `scripts/install-hyprshot.sh`
- `scripts/install-packages.sh`
- `packages/distros/*` (`arch.txt`, `fedora.txt`, `gentoo.txt`, `nixos.txt`, `opensuse.txt`)
- `packages/extras/*` (`bar.txt`, `hypr-ecosystem.txt`, `launcher.txt`, `notify.txt`, `screenshot.txt`, `system.txt`, `terminal.txt`, `utils.txt`)

### Modular Engine Introduced (`scripts/install/`)
- `install.sh` (Root): Minimal 8-line wrapper executing `scripts/install/install.sh "$@"`.
- `scripts/install/common.sh`: Transaction logging (`logs/install-*.log`), rollback stack (`CREATED_TARGETS`, `BACKUP_RECORDS`), ANSI color handling.
- `scripts/install/ui.sh`: Non-interactive and interactive prompt handling with `--dry-run`, `--non-interactive`, and `--yes` support.
- `scripts/install/detect.sh`: Hardware inventory (CPU, GPU, login session), Arch/pacman validation, network latency verification.
- `scripts/install/packages.sh`: Manifest validation, duplicate checking, `pacman` and `paru`/`yay` package installation.
- `scripts/install/backup.sh`: Pre-installation backups to `~/.local/state/hyprland-rice/backups/<TIMESTAMP>/`.
- `scripts/install/copy.sh`: Deep copying and byte-level verification (`cmp -s`) across 13 target ecosystems.
- `scripts/install/fonts.sh`: Deployment of bundled fonts to `~/.local/share/fonts/Hyprland-Rice` and `fc-cache` update.
- `scripts/install/themes.sh`: GTK (`Adwaita-dark`), icon (`Papirus-Dark`), and cursor (`Adwaita`) configuration via `gsettings`.
- `scripts/install/wallpapers.sh`: Deployment of bundled wallpapers to `~/Pictures/wallpapers`.
- `scripts/install/services.sh`: Automatic enablement of user daemons (`swaync.service`).
- `scripts/install/verify.sh`: Post-install entry point validation.
- `scripts/install/cleanup.sh`: Temporary state reclamation.

---

## 3. Audit Findings & Core Fixes (Phase 1)

During static and dynamic analysis of the codebase, 21 prioritized issues were isolated and resolved:

### Critical Fixes (5)
1. **C1 (`verify.sh:14`)**: Changed string condition `[[ "$CONFIG_MODE" != skip && ! DRY_RUN ]]` to arithmetic `[[ "$CONFIG_MODE" != skip ]] && (( ! DRY_RUN ))`. Previously, `! DRY_RUN` evaluated as a non-empty string check (always false), completely skipping Hyprland entry point verification on real installations.
2. **C2 (`waybar-reload.sh:18-19`)**: Replaced invalid Lua IPC string `hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'` with valid Hyprland CLI dispatcher `hyprctl dispatch exec waybar`.
3. **C3 (`wallpaper-only.sh` & `wallpaper-theme.sh`)**: Replaced unescaped `sed -i "s|path = .*|path = $WALLPAPER|g"` which corrupted `hyprlock.conf` input-field blocks. Replaced with safe character escaping (`&` and `\`) and an `awk` state machine targeting only the `background {}` section.
4. **C4 (`common.sh:130-155`)**: Guarded array expansions `"${CREATED_TARGETS[@]}"` and `"${BACKUP_RECORDS[@]}"` in `rollback_installation()` with `if (( ${#array[@]} ))` checks to prevent `set -u` unbound variable crashes when rollbacks occur prior to target creation.
5. **C5 (`sysmaintenance.sh:12-13`)**: Restored `set -euo pipefail` and signal trap (`INT`, `TERM`) to prevent silent command failures during system maintenance.

### High Severity Fixes (8)
6. **H1 (`packages/fonts.txt:4`)**: Replaced non-existent Arch package `adwaita-fonts` with `cantarell-fonts`.
7. **H2 (`packages/themes.txt:8-9`)**: Removed non-existent package `adwaita-cursors` and ensured `papirus-icon-theme` is retained.
8. **H3 (`packages/rofi.txt:3`)**: Swapped X11 `rofi` with `rofi-wayland`.
9. **H4 (`packages/optional.txt:15-22`)**: Added 7 packages required by bundled keybinds and scripts: `hyprsunset`, `hyprcaffeine`, `vicinae`, `yazi`, `aylurs-gtk-shell`, `nwg-look`, `pavucontrol`.
10. **H5 (`scripts/install/detect.sh:55-58`)**: Inlined guidance messages into the `die` call to eliminate dead code after `set -e` triggers.
11. **H6 (`README.md:38-46`)**: Replaced 13 broken flat documentation links with valid nested markdown paths under `docs/`.
12. **H7 (`scripts/install/copy.sh:58-61`)**: Removed erroneous backslash substitution `${target//\\/\\/}\\/icons` which corrupted icon destination paths.
13. **H8 (`config/hypr/hyprland/keybinds.lua:29`)**: Replaced `/usr/bin/chromium` with `/usr/bin/firefox` to align with the shipped desktop package manifest.

### Medium Severity Fixes (5)
14. **M1 (`scripts/install/common.sh:40`)**: Converted color gating from `[[ -t 1 && -z "${NO_COLOR:-}" ]]` to `[[ -t 1 ]] && (( ! NO_COLOR ))`.
15. **M2 (`config/hypr/scripts/wallpaper.sh:21`)**: Removed invalid whitespace in `cat << HELP` heredoc.
16. **M3 (`config/hypr/hyprland/startup.lua:20`)**: Replaced non-standard `XDG_CURRENT_SESSION` with canonical `XDG_SESSION_TYPE`.
17. **M4 (`config/hypr/hyprland.lua:42`)**: Added missing module import `require("hyprland.permissions")`.
18. **M5 (`docs/components/hypridle.md:20-21`)**: Corrected mathematical inconsistency `180s (2.5m)` to `180s (3m)`.

### Low Severity Fixes (3)
19. **L1 (`assets/screenshots/` & `README.md:22`)**: Renamed misspelled asset `tilling.png` → `tiling.png` and updated markdown reference.
20. **L2 (`config/README.md:78`)**: Standardized British spelling "Organised" to "Organized".
21. **L3 (`config/hypr/hyprland.lua:33`)**: Corrected grammatical typo "File that are" → "Files that are".

---

## 4. Runtime Dependency & Package Additions (Phase 2)

A comprehensive binary invocation scan matched against `pacman -Qo` revealed 6 packages actively used by desktop scripts that were absent from package lists:

1. **`libnotify`** (`packages/notifications.txt`):
   - *Commands Provided*: `notify-send`
   - *Consumers*: `hypridle.conf`, `wallpaper.sh`, `wallpaper-only.sh`, `wallpaper-theme.sh`, and Rofi scripts (`wifi.sh`, `bluetooth.sh`, `battery.sh`, `ethernet.sh`, `vpn.sh`).
2. **`gtk-layer-shell`** (`packages/waybar.txt`):
   - *GObject Namespace*: `GtkLayerShell 0.1`
   - *Consumers*: `config/waybar/scripts/system-popup.py` and `config/waybar/scripts/media-popup.py`.
3. **`nm-connection-editor`** (`packages/desktop.txt`):
   - *Commands Provided*: `nm-connection-editor`
   - *Consumers*: Waybar clicks in `config/waybar/modules/custom/vpn.jsonc` and `config/waybar/modules/network.jsonc`.
4. **`psmisc`** (`packages/core.txt`):
   - *Commands Provided*: `killall`
   - *Consumers*: `config/hypr/scripts/wallpaper-theme.sh` (`killall -SIGUSR2 waybar`), `config/waybar/scripts/launch.sh`.
5. **`hyprpolkitagent`** (`packages/core.txt`):
   - *Binary*: `/usr/lib/hyprpolkitagent/hyprpolkitagent`
   - *Consumers*: `config/hypr/hyprland/startup.lua:33` and `config/hypr/hyprland/rules.lua:138`. Replaces mismatched `polkit-kde-agent`.
6. **`upower`** (`packages/desktop.txt`):
   - *Commands Provided*: `upower`
   - *Consumers*: `config/rofi/battery/battery.sh` (device enumerations and diagnostics).

---

## 5. Portability & Multi-User Decoupling (Phase 3)

The configuration tree contained hardcoded references to developer user directory `/home/notrealekansh/`. These were made portable for any user installation:

- **`config/waybar/modules/includes/battery.jsonc`**: Changed `/home/notrealekansh/.config/rofi/battery/battery.sh` → `~/.config/rofi/battery/battery.sh`.
- **`config/waybar/modules/includes/network.jsonc`**: Changed hardcoded paths to `~/.config/rofi/wifi/wifi.sh` and `~/.config/rofi/network/network.sh`.
- **`config/waybar/modules/includes/bluetooth.jsonc`**: Changed hardcoded path to `~/.config/rofi/bluetooth/bluetooth.sh`.
- **`config/waybar/modules/includes/custom/app.jsonc`**: Changed hardcoded path to `~/.config/rofi/launchers/type-1/launcher.sh`.
- **`config/waybar/modules/includes/custom/power-button.jsonc`**: Changed hardcoded path to `~/.config/rofi/powermenu/powermenu.sh`.
- **`config/waybar/modules/includes/custom/vpn.jsonc`**: Changed hardcoded path to `~/.config/rofi/vpn/vpn.sh`.
- **`config/hypr/hyprpaper.conf:24`**: Changed `path = /home/notrealekansh/...` → `path = ~/.config/hypr/hyprpaper/cold-alley.png`.
- **`config/hypr/hyprlock.conf:23`**: Changed `path = /home/notrealekansh/...` → `path = ~/.config/hypr/hyprpaper/cold-alley.png`.
- **`scripts/install/copy.sh:61`**: Updated wlogout dynamic icon path rewriting regex to match any source home directory (`/home/[^/]\+/\.config/wlogout/icons`).
- **`scripts/install/detect.sh:56`**: Added root check `(( EUID == 0 ))` preventing users from corrupting dotfiles via `sudo ./install.sh`.
- **`scripts/install/copy.sh:10-13,79-84`**: Added copy rules and targets for `AGS`, `Btop`, `Fastfetch`, and `Yazi` so they are deployed to `~/.config/`.
- **`scripts/install/packages.sh:57-73`**: Added support for both `paru` and `yay` as AUR helpers.

---

## 6. Deep-Scan Debugging & Script Resilience (Phase 4)

1. **`config/waybar/scripts/wolinfo.sh`**:
   - Guarded missing secrets files `ip-address.txt` and `mac-address.txt`.
   - Initialized variable `tooltip` to prevent `set -u` crash `bash: tooltip: unbound variable`.
2. **`config/alacritty/alacritty.toml`**:
   - Fixed font configuration: `family = "JetBrainsMono  Nerd Font Semibold"` (double space + Semibold in family name) caused Fontconfig to fail and fallback to `Noto Sans Mono`. Updated to `family = "JetBrainsMono Nerd Font"` with `style = "SemiBold"`.
3. **`config/kitty/kitty.conf`**:
   - Removed stray token `5` on line 27 causing startup directive parsing warnings.
4. **`config/waybar/scripts/tailscaleinfo.sh` & `cyclehost.sh`**:
   - Guarded `mapfile` against missing `hostnames.txt` to silence stderr leakage.
   - Guarded `cyclehost.sh` arithmetic calculation against empty hostname indices.
5. **`config/waybar/scripts/connectssh.sh` & `wol.sh`**:
   - Added user validation and clean exit messaging when connection secret targets are unconfigured.
6. **`config/hypr/scripts/status.sh` & `hyprlock/scripts/status.sh`**:
   - Fixed `/sys/class/power_supply/*/status` globbing bug that read peripheral wireless mouse batteries instead of the laptop battery; scoped directly to `"$battery/status"` and `"$battery/capacity"`.
7. **`config/hypr/hyprlock/scripts/check-capslock.sh`**:
   - Standardized shebang from `#!/bin/env bash` to portable `#!/usr/bin/env bash`.
8. **`config/hypr/scripts/hyprsunset-toggle.sh`**:
   - Added executable presence validation for `hyprsunset` with desktop notification alert if uninstalled.
9. **`config/hypr/hyprland/keybinds.lua`**:
   - Added application fallback cascades (Terminal: Kitty → Alacritty; File Manager: Nautilus → Thunar; Browser: Firefox → Chromium → Chrome → Brave).
   - Wrapped `hyprcaffeine` bindings in `if hyprcaffeine then` to prevent dead key registrations when uninstalled.
10. **`config/waybar/scripts/getupdates.sh` & `installupdates.sh`**:
    - Added autodetection for `paru` and `yay`.
    - Handled zero-update states cleanly without throwing non-zero exit codes.
11. **`config/.bashrc`**:
    - Removed duplicate interactive shell check (`[[ $- != *i* ]] && return`).

---

## 7. Repository Verification & Diff Summary

### Verification Metrics
- **Shell Scripts**: 100% pass `bash -n` validation.
- **Python Code**: 100% pass `py_compile` byte-compilation.
- **Lua Modules**: 100% pass `luac -p` validation.
- **JSON / JSONC Configuration**: 100% pass strict comments-stripped JSON parsing.
- **Installer Transaction**: Verified with `./install.sh --dry-run --non-interactive`, successfully tracking 65 packages and 13 application directories.

### File Modifications At-A-Glance
```
Tracked modifications:
  M README.md
  M install.sh
  M packages/core.txt
  M packages/desktop.txt
  M packages/notifications.txt
  M packages/optional.txt
  M packages/waybar.txt
  M scripts/install/common.sh
  M scripts/install/copy.sh
  M scripts/install/detect.sh
  M scripts/install/packages.sh
  M scripts/install/themes.sh
  M scripts/install/ui.sh
  M scripts/install/verify.sh
  M config/.bashrc
  M config/alacritty/alacritty.toml
  M config/kitty/kitty.conf
  M config/hypr/hyprland.lua
  M config/hypr/hyprlock.conf
  M config/hypr/hyprpaper.conf
  M config/hypr/hyprland/keybinds.lua
  M config/hypr/hyprland/startup.lua
  M config/hypr/hyprlock/scripts/check-capslock.sh
  M config/hypr/hyprlock/scripts/status.sh
  M config/hypr/scripts/status.sh
  M config/hypr/scripts/wallpaper.sh
  M config/hypr/scripts/waybar-reload.sh
  M config/waybar/modules/includes/battery.jsonc
  M config/waybar/modules/includes/bluetooth.jsonc
  M config/waybar/modules/includes/custom/app.jsonc
  M config/waybar/modules/includes/custom/power-button.jsonc
  M config/waybar/modules/includes/custom/vpn.jsonc
  M config/waybar/modules/includes/network.jsonc
  M config/waybar/scripts/addhost.sh
  M config/waybar/scripts/connectssh.sh
  M config/waybar/scripts/cyclehost.sh
  M config/waybar/scripts/getupdates.sh
  M config/waybar/scripts/installupdates.sh
  M config/waybar/scripts/launch.sh
  M config/waybar/scripts/tailscaleinfo.sh
  M config/waybar/scripts/wol.sh
  M config/waybar/scripts/wolinfo.sh
  M config/wlogout/style.css
```
