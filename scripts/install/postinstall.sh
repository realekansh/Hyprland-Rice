#!/usr/bin/env bash

postinstall() {
    run_cmd mkdir -p "$HOME/.config" "$HOME/.local/bin"
    log "Post-install user directories are ready; source file modes were preserved during copy."
}
