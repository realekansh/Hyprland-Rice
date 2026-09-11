#!/usr/bin/env bash

backup_existing() {
    local target="$1" relative backup_path
    path_exists "$target" || return 0
    (( BACKUP_EXISTING )) || return 0

    relative="${target#"$HOME"/}"
    [[ "$relative" == "$target" ]] && relative="external/$(basename -- "$target")"
    backup_path="$BACKUP_ROOT/$relative"
    if (( DRY_RUN )); then
        log "dry-run: backup $target -> $backup_path"
        register_backup "$backup_path" "$target"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$backup_path")"
    cp -a -- "$target" "$backup_path"
    register_backup "$backup_path" "$target"
    ok "Backed up $target"
}
