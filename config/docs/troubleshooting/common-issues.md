# Troubleshooting Common Issues

Practical troubleshooting guide for issues related to the desktop configuration.

---

## 1. Hyprland Fails to Load Lua Modules

### Problem
Hyprland fails to start or displays a red error bar indicating syntax errors or missing modules.

### Cause
Hyprland must be version 0.55.0 or newer compiled with Lua configuration support. Additionally, `hyprland.lua` expects module paths relative to the configuration directory (`hyprland.<module>`).

### Check
Run Hyprland version check:
```bash
Hyprland --version
```
Verify that `~/.config/hypr/hyprland/` contains `monitors.lua`, `appearance.lua`, `keybinds.lua`, etc.

### Fix
* Ensure your system is running Hyprland >= 0.55.
* Verify symbolic links: `ls -la ~/.config/hypr/hyprland/`.
* Test Lua syntax manually if needed: `lua ~/.config/hypr/hyprland.lua`.

---

## 2. Missing Icons or Square Glyphs

### Problem
Status bars, Rofi applets, terminal prompts, or Yazi render hollow squares or question marks instead of icons.

### Cause
The Nerd Font glyph patch or icon font is missing from your font cache.

### Check
Check if JetBrains Mono Nerd Font is recognized:
```bash
fc-list : family | grep -i "JetBrainsMono Nerd Font"
```

### Fix
Install the font package and rebuild fontconfig cache:
```bash
sudo pacman -S ttf-jetbrains-mono-nerd papirus-icon-theme
fc-cache -fv
```

---

## 3. Rofi Battery Applet Fails to Change CPU Profiles

### Problem
Selecting "Performance Mode" or "Power Saver Mode" in the Rofi battery applet does not change CPU state or reports permission denied.

### Cause
Modifying `/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference` requires write permissions to root-owned sysfs nodes.

### Check
Check permissions on CPU 0 preference:
```bash
ls -l /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
```

### Fix
Create a udev rule (e.g. `/etc/udev/rules.d/99-cpu-governor.rules`) to grant user write access to the cpufreq directory, or run profile changes through a polkit-authenticated wrapper.

---

## 4. Brightness Keys Do Not Adjust Display

### Problem
Pressing `XF86MonBrightnessUp` or `XF86MonBrightnessDown` produces no change in screen brightness.

### Cause
`brightnessctl` is either missing or your user account lacks permissions to write to `/sys/class/backlight`.

### Check
Test brightnessctl directly from terminal:
```bash
brightnessctl set 5%+
```

### Fix
Add your user to the `video` and `input` groups:
```bash
sudo usermod -aG video,input $USER
```
Log out and log back in to apply group changes.

---

## 5. Waybar Disappears or Fails to Reload

### Problem
After running the wallpaper shuffler (`Super + Shift + W`), Waybar disappears and does not respawn.

### Cause
CSS syntax error in the selected theme stylesheet or Waybar process hung during signal handling.

### Check
Run the reload script from terminal to view stdout/stderr:
```bash
bash ~/.config/hypr/scripts/waybar-reload.sh
```

### Fix
* Inspect `~/.config/waybar/style.css` for invalid `@import` theme paths.
* Ensure all theme files in `~/.config/waybar/themes/` have valid GTK CSS syntax.

---

## 6. Hyprlock Status Scripts Return Empty

### Problem
Lockscreen status shows empty strings for battery or unread notifications.

### Cause
* Battery: Battery name in `/sys/class/power_supply/` does not match `*BAT*`.
* Notifications: `swaync-client` is not running.

### Check
Run the scripts manually:
```bash
bash ~/.config/hypr/hyprlock/scripts/status.sh
bash ~/.config/hypr/hyprlock/scripts/notifications.sh
```

### Fix
* Inspect your power supply device name using `ls /sys/class/power_supply/`.
* Ensure SwayNC daemon is autostarted in `hypr/hyprland/startup.lua`.
