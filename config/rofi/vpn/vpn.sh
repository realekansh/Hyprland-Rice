#!/usr/bin/env bash

## Rofi   : VPN Manager Menu
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/vpn"
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
    local icon="${3:-network-vpn}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "VPN Manager" -i "$icon" "$summary" "$msg"
    fi
}

# Get list of all configured VPN profiles
get_vpn_profiles() {
    nmcli -t -f NAME,UUID,TYPE connection show | grep -E ":(vpn|wireguard|tun)$" | sort -u
}

# Get list of active VPN names
get_active_vpns() {
    nmcli -t -f NAME,TYPE,STATE connection show --active | grep -E ":(vpn|wireguard|tun):" | cut -d':' -f1
}

# -------------------------------------------------------------
# VPN Profile Action Submenu
# -------------------------------------------------------------
show_vpn_menu() {
    local vpn_name="$1"
    local vpn_uuid="$2"
    local is_active="$3"
    local safe_name
    safe_name=$(pango_escape "$vpn_name")

    while true; do
        local status_tag="<span alpha='45%'>○ Disconnected</span>"
        [[ "$is_active" == "yes" ]] && status_tag="<span color='#00CCF5'><b>● Active / Encrypted</b></span>"

        local mesg="<b>VPN Profile:</b> ${safe_name}
<b>Status:</b> ${status_tag}   <span alpha='70%'>UUID:</span> <span size='small' alpha='50%'>${vpn_uuid}</span>"

        local items=()
        if [[ "$is_active" == "yes" ]]; then
            items+=("󰌿  Disconnect from ${safe_name}")
        else
            items+=("󰌾  Connect to ${safe_name}")
        fi

        items+=("󰋽  Show VPN Profile Configuration")
        items+=("  Delete VPN Profile")
        items+=("󰌍  Back to Main Menu")

        local chosen
        chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "VPN Action" -mesg "$mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
            exit 0
        fi

        if [[ "$chosen" == *"Back"* ]]; then
            break
        fi

        case "$chosen" in
            *"Connect to"*)
                notify "VPN Connecting..." "Connecting to secure VPN ${vpn_name}..." "network-vpn"
                local out
                out=$(nmcli connection up uuid "$vpn_uuid" 2>&1)
                if echo "$out" | grep -qi "successfully activated"; then
                    notify "VPN Connected" "Secure tunnel active: ${vpn_name}" "network-vpn-acquiring"
                    is_active="yes"
                else
                    notify "VPN Connection Failed" "$out" "dialog-error"
                fi
                ;;
            *"Disconnect from"*)
                nmcli connection down uuid "$vpn_uuid" >/dev/null 2>&1
                notify "VPN Disconnected" "Disconnected from ${vpn_name}" "network-vpn"
                is_active="no"
                ;;
            *"Show VPN Profile"*)
                local details
                details=$(nmcli connection show uuid "$vpn_uuid" 2>/dev/null)
                echo -e "=== VPN Profile: ${vpn_name} ===\n\n${details}" | rofi -dmenu -theme "$theme_path" -p "VPN Details" -mesg "<b>Configuration: ${safe_name}</b>"
                local d_exit=$?
                if [[ $d_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
            *"Delete VPN Profile"*)
                nmcli connection delete uuid "$vpn_uuid" >/dev/null 2>&1
                notify "VPN Profile Deleted" "Removed VPN profile ${vpn_name}" "network-vpn"
                break
                ;;
        esac
    done
}

# -------------------------------------------------------------
# Main Application Loop
# -------------------------------------------------------------
main() {
    while true; do
        local active_vpn_list
        active_vpn_list=$(get_active_vpns)
        local primary_active
        primary_active=$(echo "$active_vpn_list" | head -n1)

        local vpn_badge="<span alpha='45%'>○ No Active VPN (Unencrypted)</span>"
        if [[ -n "$primary_active" ]]; then
            vpn_badge="<span color='#00CCF5'><b>● Protected (${primary_active})</b></span>"
        fi

        local safe_primary
        safe_primary=$(pango_escape "${primary_active:-None}")

        local main_mesg="<b>󰌾 VPN Security:</b> ${safe_primary}   ${vpn_badge}
<span alpha='65%'>Select a VPN profile below to connect or manage encrypted tunnels</span>"

        local items=()
        if [[ -n "$primary_active" ]]; then
            items+=("󰌿  Disconnect All Active VPNs")
        fi

        items+=("󰑐  Refresh VPN Status")
        items+=("󰋽  Show Public IP &amp; Network Routing Details")

        local profiles
        profiles=$(get_vpn_profiles)
        local count=0
        declare -A vpn_name_by_item
        declare -A vpn_uuid_by_item

        if [[ -n "$profiles" ]]; then
            while IFS=':' read -r p_name p_uuid p_type; do
                [[ -z "$p_name" ]] && continue
                local p_badge="<span alpha='45%'>○ Disconnected</span>"
                local is_act="no"

                if echo "$active_vpn_list" | grep -qx "$p_name"; then
                    p_badge="<span color='#00CCF5'><b>● Connected [Encrypted]</b></span>"
                    is_act="yes"
                fi

                local safe_p_name
                safe_p_name=$(pango_escape "$p_name")
                local item_line="󰌾  ${safe_p_name}  <span size='small' alpha='50%'>(${p_type^^})</span>  ${p_badge}"

                items+=("$item_line")
                vpn_name_by_item["$item_line"]="$p_name"
                vpn_uuid_by_item["$item_line"]="$p_uuid"
                ((count++))
            done <<< "$profiles"
        fi

        if [[ "$count" -eq 0 ]]; then
            items+=("󰌿  No VPN profiles configured in NetworkManager")
        fi

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "VPN" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Disconnect All Active VPNs"*)
                while IFS= read -r v_name; do
                    [[ -n "$v_name" ]] && nmcli connection down id "$v_name" >/dev/null 2>&1
                done <<< "$active_vpn_list"
                notify "VPN Disconnected" "All active VPN tunnels closed" "network-vpn"
                ;;
            *"Refresh VPN Status"*)
                notify "VPN Status" "Refreshed VPN profiles." "network-vpn"
                continue
                ;;
            *"Show Public IP"*)
                notify "VPN Status" "Querying network routing details..." "network-vpn"
                local ip_info
                ip_info=$(ip -br addr 2>/dev/null)
                local routes
                routes=$(ip route show 2>/dev/null)
                echo -e "=== Active Network Interfaces ===\n${ip_info}\n\n=== Routing Table ===\n${routes}" | rofi -dmenu -theme "$theme_path" -p "Network Details" -mesg "<b>Routing &amp; Interface Details</b>"
                local ip_exit=$?
                if [[ $ip_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
            *)
                local sel_pname="${vpn_name_by_item[$selection]}"
                local sel_uuid="${vpn_uuid_by_item[$selection]}"

                if [[ -n "$sel_uuid" ]]; then
                    local is_act="no"
                    echo "$active_vpn_list" | grep -qx "$sel_pname" && is_act="yes"
                    show_vpn_menu "$sel_pname" "$sel_uuid" "$is_act"
                fi
                ;;
        esac
    done
}

main "$@"
