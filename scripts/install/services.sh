#!/usr/bin/env bash

configure_services() {
    (( INSTALL_SERVICES || START_SERVICES )) || { log "Skipping service configuration."; return 0; }
    command -v systemctl >/dev/null 2>&1 || { warn "systemctl is unavailable; skipping user services."; return 0; }
    local service="swaync.service"
    if ! systemctl --user cat "$service" >/dev/null 2>&1; then
        warn "$service is not installed; startup.lua will launch swaync when available."
        return 0
    fi
    if (( INSTALL_SERVICES )); then
        run_cmd systemctl --user enable "$service"
    fi
    if (( START_SERVICES )); then
        run_cmd systemctl --user start "$service"
    fi
    ok "User service configuration completed."
}
