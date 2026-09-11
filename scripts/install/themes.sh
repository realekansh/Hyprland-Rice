#!/usr/bin/env bash

install_themes() {
    if (( INSTALL_GTK_THEME || INSTALL_CURSOR_THEME || INSTALL_ICON_THEME )); then
        log "Theme packages are handled by the selected themes manifest."
    fi
    (( DRY_RUN )) && return 0
    if (( INSTALL_GTK_THEME )) && command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' || warn "Could not select GTK theme through gsettings."
    fi
    if (( INSTALL_ICON_THEME )) && command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' || warn "Could not select icon theme through gsettings."
    fi
    if (( INSTALL_CURSOR_THEME )); then
        if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' || warn "Could not select cursor theme through gsettings."
        fi
        warn "The checked-in Hyprland Lua config requests Moga-Black; edit ~/.config/hypr/hyprland/cursor.lua if you want to use Adwaita."
    fi
}
