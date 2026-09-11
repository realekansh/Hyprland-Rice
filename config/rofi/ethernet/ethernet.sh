#!/usr/bin/env bash

## Rofi   : Ethernet Control Menu
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/ethernet"
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
    local icon="${3:-network-wired}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Ethernet Manager" -i "$icon" "$summary" "$msg"
    fi
}

# -------------------------------------------------------------
# Ethernet Profile Actions Submenu
# -------------------------------------------------------------
show_profile_menu() {
    local prof_name="$1"
    local prof_uuid="$2"
    local is_active="$3"
    local safe_name
    safe_name=$(pango_escape "$prof_name")

    while true; do
        local status_tag="<span alpha='45%'>○ Inactive</span>"
        [[ "$is_active" == "yes" ]] && status_tag="<span color='#00CCF5'><b>● Active / Connected</b></span>"

        local mesg="<b>Ethernet Profile:</b> ${safe_name}
<b>Status:</b> ${status_tag}   <span alpha='70%'>UUID:</span> <span size='small' alpha='50%'>${prof_uuid}</span>"

        local items=()
        if [[ "$is_active" == "yes" ]]; then
            items+=("󰈂  Disconnect Ethernet Profile")
        else
            items+=("󰈀  Activate Ethernet Profile")
        fi

        items+=("󰑐  Renew DHCP Lease (Reapply Profile)")
        items+=("󰋽  Show Profile Details")
        items+=("󰌍  Back to Main Menu")

        local chosen
        chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Ethernet Profile" -mesg "$mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
            exit 0
        fi

        if [[ "$chosen" == *"Back"* ]]; then
            break
        fi

        case "$chosen" in
            *"Activate"*)
                notify "Ethernet" "Activating profile ${prof_name}..." "network-wired"
                local out
                out=$(nmcli connection up uuid "$prof_uuid" 2>&1)
                if echo "$out" | grep -qi "successfully activated"; then
                    notify "Ethernet Connected" "Active profile: ${prof_name}" "network-wired-activated"
                    is_active="yes"
                else
                    notify "Activation Failed" "$out" "dialog-error"
                fi
                ;;
            *"Disconnect"*)
                nmcli connection down uuid "$prof_uuid" >/dev/null 2>&1
                notify "Ethernet Disconnected" "Deactivated profile ${prof_name}" "network-wired-disconnected"
                is_active="no"
                ;;
            *"Renew DHCP"*)
                notify "Ethernet" "Renewing DHCP lease for ${prof_name}..." "network-wired"
                nmcli connection up uuid "$prof_uuid" >/dev/null 2>&1
                notify "Ethernet" "DHCP lease renewed." "network-wired"
                ;;
            *"Show Profile Details"*)
                local details
                details=$(nmcli connection show uuid "$prof_uuid" 2>/dev/null)
                echo -e "=== Ethernet Profile: ${prof_name} ===\n\n${details}" | rofi -dmenu -theme "$theme_path" -p "Details" -mesg "<b>Profile Details: ${safe_name}</b>"
                local d_exit=$?
                if [[ $d_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
        esac
    done
}

# -------------------------------------------------------------
# Main Application Loop
# -------------------------------------------------------------
main() {
    while true; do
        local eth_dev
        eth_dev=$(nmcli -t -f DEVICE,TYPE device | grep ":ethernet$" | grep -v "veth" | head -n1 | cut -d':' -f1)
        [[ -z "$eth_dev" ]] && eth_dev="eno1"

        local eth_state
        eth_state=$(nmcli -t -f DEVICE,STATE device | grep "^${eth_dev}:" | cut -d':' -f2)
        [[ -z "$eth_state" ]] && eth_state="unavailable"

        local active_prof
        active_prof=$(nmcli -t -f DEVICE,NAME,TYPE connection show --active | grep ":ethernet$" | head -n1 | cut -d':' -f2)

        local ip_addr
        ip_addr=$(ip -4 addr show "$eth_dev" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [[ -z "$ip_addr" ]] && ip_addr="No IP"

        local speed_info
        speed_info=$(cat "/sys/class/net/${eth_dev}/speed" 2>/dev/null)
        local speed_str="Auto"
        [[ -n "$speed_info" && "$speed_info" != "-1" ]] && speed_str="${speed_info} Mbps"

        local state_badge="<span alpha='45%'>○ Disconnected (${eth_state})</span>"
        [[ "$eth_state" == "connected" ]] && state_badge="<span color='#00CCF5'><b>● Connected</b></span>"

        local main_mesg="<b>󰈀 Ethernet (${eth_dev})</b>  ${state_badge}   <span alpha='70%'>IP:</span> <span color='#00CCF5'><b>${ip_addr}</b></span>   <span alpha='70%'>Speed:</span> <span color='#00CCF5'><b>${speed_str}</b></span>"

        local items=()
        if [[ "$eth_state" == "connected" ]]; then
            items+=("󰈂  Disconnect Ethernet (${eth_dev})")
        else
            items+=("󰈀  Connect / Auto-Negotiate Ethernet (${eth_dev})")
        fi

        items+=("󰑐  Renew DHCP Lease / Reconnect")
        items+=("󰋽  Show Interface Hardware &amp; Network Info")

        local profiles
        profiles=$(nmcli -t -f NAME,UUID,TYPE connection show | grep ":802-3-ethernet$" | sort -u)
        local prof_count=0
        declare -A prof_name_by_item
        declare -A prof_uuid_by_item

        if [[ -n "$profiles" ]]; then
            while IFS=':' read -r p_name p_uuid p_type; do
                [[ -z "$p_name" ]] && continue
                local p_badge="<span alpha='45%'>○ Inactive</span>"
                [[ "$p_name" == "$active_prof" ]] && p_badge="<span color='#00CCF5'><b>● Active</b></span>"

                local safe_p_name
                safe_p_name=$(pango_escape "$p_name")
                local item_line="󰈀  ${safe_p_name}  <span size='small' alpha='50%'>(${p_uuid:0:8}...)</span>  ${p_badge}"

                items+=("$item_line")
                prof_name_by_item["$item_line"]="$p_name"
                prof_uuid_by_item["$item_line"]="$p_uuid"
                ((prof_count++))
            done <<< "$profiles"
        fi

        if [[ "$prof_count" -eq 0 ]]; then
            items+=("󰈂  No Ethernet profiles configured")
        fi

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Ethernet" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Disconnect Ethernet"*)
                nmcli device disconnect "$eth_dev" >/dev/null 2>&1
                notify "Ethernet" "Disconnected ${eth_dev}" "network-wired-disconnected"
                ;;
            *"Connect / Auto-Negotiate"*)
                notify "Ethernet" "Connecting ${eth_dev}..." "network-wired"
                local out
                out=$(nmcli device connect "$eth_dev" 2>&1)
                if echo "$out" | grep -qi "successfully"; then
                    notify "Ethernet Connected" "Connected on ${eth_dev}" "network-wired-activated"
                else
                    notify "Connection Info" "$out" "network-wired"
                fi
                ;;
            *"Renew DHCP"*)
                notify "Ethernet" "Reapplying network configuration on ${eth_dev}..." "network-wired"
                nmcli device reapply "$eth_dev" >/dev/null 2>&1 || nmcli device connect "$eth_dev" >/dev/null 2>&1
                notify "Ethernet" "DHCP configuration renewed." "network-wired"
                ;;
            *"Show Interface Hardware"*)
                local dev_details
                dev_details=$(nmcli device show "$eth_dev" 2>/dev/null)
                echo -e "=== Interface: ${eth_dev} ===\n\n${dev_details}" | rofi -dmenu -theme "$theme_path" -p "Interface Info" -mesg "<b>Interface Details: ${eth_dev}</b>"
                local i_exit=$?
                if [[ $i_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
            *)
                local sel_pname="${prof_name_by_item[$selection]}"
                local sel_uuid="${prof_uuid_by_item[$selection]}"

                if [[ -n "$sel_uuid" ]]; then
                    local is_act="no"
                    [[ "$sel_pname" == "$active_prof" ]] && is_act="yes"
                    show_profile_menu "$sel_pname" "$sel_uuid" "$is_act"
                fi
                ;;
        esac
    done
}

main "$@"
