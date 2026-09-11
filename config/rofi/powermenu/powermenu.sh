#!/usr/bin/env bash

## Rofi   : Power & Logout Menu
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/powermenu"
theme='style-1'
theme_path="${dir}/${theme}.rasi"

# Helper for Pango XML escaping
pango_escape() {
    local str="$1"
    str="${str//&/&amp;}"
    str="${str//</&lt;}"
    str="${str//>/&gt;}"
    echo "$str"
}

# Helper for desktop notifications
notify() {
    local summary="$1"
    local msg="$2"
    local icon="${3:-system-shutdown}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Power Manager" -i "$icon" "$summary" "$msg"
    fi
}

# Confirmation dialog
confirm_action() {
    local action_title="$1"
    local safe_title
    safe_title=$(pango_escape "$action_title")

    local mesg="<b>Confirm ${safe_title}?</b>"

    local items=()
    items+=("<span size='large'>󰄬</span>  Confirm")
    items+=("<span size='large'>󰅖</span>  Cancel")

    local choice
    choice=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -theme-str "window { width: 420px; } listview { columns: 2; }" -p "Confirm" -mesg "$mesg" -markup-rows)
    local rofi_exit=$?

    if [[ $rofi_exit -ne 0 || -z "$choice" ]]; then
        exit 0
    fi

    if [[ "$choice" == *"Confirm"* ]]; then
        return 0
    else
        return 1
    fi
}

# Lock screen handler
lock_screen() {
    if command -v hyprlock >/dev/null 2>&1; then
        hyprlock &
    elif command -v swaylock >/dev/null 2>&1; then
        swaylock &
    elif command -v loginctl >/dev/null 2>&1; then
        loginctl lock-session
    fi
}

# -------------------------------------------------------------
# Main Application Loop
# -------------------------------------------------------------
main() {
    local user_name="${USER:-$(whoami)}"
    local host_name="${HOSTNAME:-$(hostname)}"
    local uptime_str
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
    [[ -z "$uptime_str" ]] && uptime_str=$(uptime 2>/dev/null | awk -F'( |,|:)+' '{print $6,"hrs,", $7,"mins"}')
    [[ -z "$uptime_str" ]] && uptime_str="Active"

    local safe_user
    safe_user=$(pango_escape "$user_name")
    local safe_host
    safe_host=$(pango_escape "$host_name")

    local main_mesg="<b>󰐥 Session Menu</b>   <span color='#00CCF5'><b>[${safe_user}@${safe_host}]</b></span>   <span alpha='65%'>Uptime:</span> <b>${uptime_str}</b>"

    # Build 6 Wlogout-style Action Cards
    local items=()
    items+=("<span size='large'>󰌾</span>  Lock")
    items+=("<span size='large'>󰍃</span>  Logout")
    items+=("<span size='large'>󰤄</span>  Suspend")
    items+=("<span size='large'>󰒲</span>  Hibernate")
    items+=("<span size='large'>󰜉</span>  Reboot")
    items+=("<span size='large'>󰐥</span>  Shutdown")

    local selection
    selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Power" -mesg "$main_mesg" -markup-rows)
    local rofi_exit=$?

    if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
        exit 0
    fi

    case "$selection" in
        *"Lock"*)
            lock_screen
            exit 0
            ;;
        *"Logout"*)
            if confirm_action "Logout"; then
                notify "Session" "Logging out..." "system-log-out"
                hyprctl dispatch exit || loginctl terminate-user "$USER"
            fi
            ;;
        *"Suspend"*)
            lock_screen
            sleep 0.5
            systemctl suspend || loginctl suspend
            exit 0
            ;;
        *"Hibernate"*)
            if confirm_action "Hibernate"; then
                lock_screen
                sleep 0.5
                systemctl hibernate || loginctl hibernate
            fi
            ;;
        *"Reboot"*)
            if confirm_action "Reboot"; then
                notify "System" "Rebooting..." "system-reboot"
                systemctl reboot || loginctl reboot
            fi
            ;;
        *"Shutdown"*)
            if confirm_action "Shutdown"; then
                notify "System" "Shutting down..." "system-shutdown"
                systemctl poweroff || loginctl poweroff
            fi
            ;;
    esac
}

main "$@"
