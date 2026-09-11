#!/usr/bin/env bash

## Rofi   : Wi-Fi Control Menu
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/wifi"
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
    local icon="${3:-network-wireless}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Wi-Fi Manager" -i "$icon" "$summary" "$msg"
    fi
}

# Check if Wi-Fi radio is enabled
is_wifi_on() {
    local status
    status=$(nmcli radio wifi 2>/dev/null)
    [[ "$status" == "enabled" ]]
}

# Get Wi-Fi signal glyph
get_signal_icon() {
    local sig="${1:-0}"
    if [[ "$sig" -ge 75 ]]; then
        echo "󰤨"
    elif [[ "$sig" -ge 50 ]]; then
        echo "󰤥"
    elif [[ "$sig" -ge 25 ]]; then
        echo "󰤢"
    else
        echo "󰤟"
    fi
}

# -------------------------------------------------------------
# Saved Connection Action Submenu
# -------------------------------------------------------------
show_connection_menu() {
    local con_name="$1"
    local con_uuid="$2"
    local is_active="$3"
    local safe_name
    safe_name=$(pango_escape "$con_name")

    while true; do
        local active_badge="<span alpha='45%'>○ Disconnected</span>"
        [[ "$is_active" == "yes" ]] && active_badge="<span color='#00CCF5'><b>● Active / Connected</b></span>"

        local mesg="<b>Wi-Fi Profile:</b> ${safe_name}
<b>Status:</b> ${active_badge}   <span alpha='70%'>UUID:</span> <span size='small' alpha='50%'>${con_uuid}</span>"

        local items=()
        if [[ "$is_active" == "yes" ]]; then
            items+=("󰤮  Disconnect from ${safe_name}")
        else
            items+=("󰤨  Connect to ${safe_name}")
        fi

        items+=("  Forget / Delete Network Profile")
        items+=("󰋽  Show Profile Details &amp; Password")
        items+=("󰌍  Back to Main Menu")

        local chosen
        chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Wi-Fi Profile" -mesg "$mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
            exit 0
        fi

        if [[ "$chosen" == *"Back"* ]]; then
            break
        fi

        case "$chosen" in
            *"Connect to"*)
                notify "Connecting..." "Connecting to ${con_name}..." "network-wireless"
                local out
                out=$(nmcli connection up uuid "$con_uuid" 2>&1)
                if echo "$out" | grep -qi "successfully activated"; then
                    notify "Wi-Fi Connected" "Connected to ${con_name}" "network-wireless-connected"
                    is_active="yes"
                else
                    notify "Connection Failed" "$out" "dialog-error"
                fi
                ;;
            *"Disconnect from"*)
                nmcli connection down uuid "$con_uuid" >/dev/null 2>&1
                notify "Wi-Fi Disconnected" "Disconnected from ${con_name}" "network-wireless"
                is_active="no"
                ;;
            *"Forget"*|*"Delete"*)
                nmcli connection delete uuid "$con_uuid" >/dev/null 2>&1
                notify "Wi-Fi Profile Deleted" "Deleted profile for ${con_name}" "network-wireless"
                break
                ;;
            *"Show Profile Details"*)
                local details
                details=$(nmcli connection show uuid "$con_uuid" 2>/dev/null)
                local psk
                psk=$(nmcli -s -g 802-11-wireless-security.psk connection show uuid "$con_uuid" 2>/dev/null)
                local psk_info="Stored Password: (None or Protected)"
                [[ -n "$psk" ]] && psk_info="Stored Password: ${psk}"

                echo -e "=== ${con_name} ===\n${psk_info}\n\n${details}" | rofi -dmenu -theme "$theme_path" -p "Profile Details" -mesg "<b>Profile Details: ${safe_name}</b>"
                local d_exit=$?
                if [[ $d_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
        esac
    done
}

# -------------------------------------------------------------
# Discovery & Available Nearby Wi-Fi Submenu
# -------------------------------------------------------------
show_discovery_menu() {
    while true; do
        local raw_list
        raw_list=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null)
        local items=()
        local count=0

        items+=("󰑐  Rescan Nearby Networks")
        items+=("󰌍  Back to Main Menu")

        declare -A seen_ssids
        declare -A ssid_by_item
        declare -A sec_by_item

        if [[ -n "$raw_list" ]]; then
            while IFS=':' read -r in_use signal security ssid; do
                [[ -z "$ssid" || "$ssid" == "--" ]] && continue
                [[ -n "${seen_ssids[$ssid]}" ]] && continue
                seen_ssids["$ssid"]=1

                local sig_icon
                sig_icon=$(get_signal_icon "$signal")
                local sec_icon=" Open"
                [[ -n "$security" && "$security" != "--" ]] && sec_icon=" ${security}"

                local safe_ssid
                safe_ssid=$(pango_escape "$ssid")

                local in_use_tag=""
                if [[ "$in_use" == "*" ]]; then
                    in_use_tag="  <span color='#00CCF5'><b>● Connected</b></span>"
                fi

                local item_line="${sig_icon}  ${safe_ssid}  <span size='small' alpha='65%'>(${signal}%)</span>  <span size='small' alpha='60%'>[${sec_icon}]</span>${in_use_tag}"
                items+=("$item_line")
                ssid_by_item["$item_line"]="$ssid"
                sec_by_item["$item_line"]="$security"
                ((count++))
            done <<< "$raw_list"
        fi

        if [[ "$count" -eq 0 ]]; then
            items+=("󰤮  No nearby networks found (Click Rescan above)")
        fi

        local disc_mesg="<b>󰤨 Nearby Wi-Fi Networks</b>  <span alpha='65%'>(${count} available)</span>
<span alpha='60%'>Select any network below to connect or enter security credentials</span>"

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Scan Wi-Fi" -mesg "$disc_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        if [[ "$selection" == *"Back to Main Menu"* ]]; then
            break
        fi

        if [[ "$selection" == *"Rescan Nearby Networks"* ]]; then
            notify "Wi-Fi Scanning" "Scanning for nearby Wi-Fi networks..." "network-wireless"
            nmcli dev wifi rescan >/dev/null 2>&1
            sleep 1.5
            continue
        fi

        local sel_ssid="${ssid_by_item[$selection]}"
        local sel_sec="${sec_by_item[$selection]}"
        [[ -z "$sel_ssid" ]] && continue

        local saved_uuid
        saved_uuid=$(nmcli -t -f NAME,UUID,TYPE connection show | grep ":802-11-wireless$" | grep "^${sel_ssid}:" | head -n1 | cut -d':' -f2)

        if [[ -n "$saved_uuid" ]]; then
            notify "Wi-Fi Connecting" "Connecting to saved network ${sel_ssid}..." "network-wireless"
            local out
            out=$(nmcli connection up uuid "$saved_uuid" 2>&1)
            if echo "$out" | grep -qi "successfully activated"; then
                notify "Wi-Fi Connected" "Connected to ${sel_ssid}" "network-wireless-connected"
                break
            else
                notify "Connection Failed" "$out" "dialog-error"
            fi
        else
            if [[ -z "$sel_sec" || "$sel_sec" == "--" ]]; then
                notify "Connecting..." "Connecting to open network ${sel_ssid}..." "network-wireless"
                local out
                out=$(nmcli dev wifi connect "$sel_ssid" 2>&1)
                if echo "$out" | grep -qi "successfully activated"; then
                    notify "Wi-Fi Connected" "Connected to ${sel_ssid}" "network-wireless-connected"
                    break
                else
                    notify "Connection Failed" "$out" "dialog-error"
                fi
            else
                local pass
                pass=$(rofi -dmenu -password -theme "$theme_path" -p "Password" -mesg "<b>Enter Wi-Fi Password for:</b> $(pango_escape "$sel_ssid")")
                local pass_exit=$?
                if [[ $pass_exit -ne 0 || -z "$pass" ]]; then
                    continue
                fi

                notify "Connecting..." "Connecting to ${sel_ssid}..." "network-wireless"
                local out
                out=$(nmcli dev wifi connect "$sel_ssid" password "$pass" 2>&1)
                if echo "$out" | grep -qi "successfully activated"; then
                    notify "Wi-Fi Connected" "Successfully connected to ${sel_ssid}" "network-wireless-connected"
                    break
                else
                    notify "Connection Failed" "$out" "dialog-error"
                fi
            fi
        fi
    done
}

# -------------------------------------------------------------
# Manual / Hidden Network Dialog
# -------------------------------------------------------------
connect_hidden_network() {
    local h_ssid
    h_ssid=$(rofi -dmenu -theme "$theme_path" -p "Hidden SSID" -mesg "<b>Enter Hidden / Custom Network SSID:</b>")
    local s_exit=$?
    if [[ $s_exit -ne 0 || -z "$h_ssid" ]]; then
        return
    fi

    local h_pass
    h_pass=$(rofi -dmenu -password -theme "$theme_path" -p "Password" -mesg "<b>Enter Password for:</b> $(pango_escape "$h_ssid") (Leave empty if Open)")
    local p_exit=$?
    if [[ $p_exit -ne 0 ]]; then
        return
    fi

    notify "Connecting..." "Connecting to hidden network ${h_ssid}..." "network-wireless"
    local out
    if [[ -n "$h_pass" ]]; then
        out=$(nmcli dev wifi connect "$h_ssid" password "$h_pass" hidden yes 2>&1)
    else
        out=$(nmcli dev wifi connect "$h_ssid" hidden yes 2>&1)
    fi

    if echo "$out" | grep -qi "successfully activated"; then
        notify "Wi-Fi Connected" "Connected to hidden network ${h_ssid}" "network-wireless-connected"
    else
        notify "Connection Failed" "$out" "dialog-error"
    fi
}

# -------------------------------------------------------------
# Main Application Loop
# -------------------------------------------------------------
main() {
    while true; do
        if ! is_wifi_on; then
            local off_mesg="<b>Wi-Fi Status:</b> <span color='#DF5296'><b>Powered OFF</b></span>
<span alpha='65%'>Enable Wi-Fi to scan and connect networks</span>"
            local items=()
            items+=("󰤨  Turn Wi-Fi ON")
            items+=("󰚥  Unblock RFKill &amp; Reload Service")
            items+=("󰈆  Exit")

            local chosen_off
            chosen_off=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Wi-Fi (OFF)" -mesg "$off_mesg" -markup-rows)
            local rofi_exit=$?

            if [[ $rofi_exit -ne 0 || -z "$chosen_off" || "$chosen_off" == *"Exit"* ]]; then
                exit 0
            fi

            case "$chosen_off" in
                *"Turn Wi-Fi ON"*)
                    rfkill unblock wifi >/dev/null 2>&1
                    nmcli radio wifi on >/dev/null 2>&1
                    sleep 0.5
                    notify "Wi-Fi Enabled" "Wi-Fi has been turned ON" "network-wireless"
                    ;;
                *"Unblock RFKill"*)
                    rfkill unblock wifi >/dev/null 2>&1
                    notify "RFKill Unblocked" "Unblocked Wi-Fi radio" "network-wireless"
                    ;;
            esac
            continue
        fi

        local wlan_dev
        wlan_dev=$(nmcli -t -f DEVICE,TYPE device | grep ":wifi$" | head -n1 | cut -d':' -f1)
        [[ -z "$wlan_dev" ]] && wlan_dev="wlan0"

        local active_info
        active_info=$(nmcli -t -f DEVICE,NAME,TYPE,STATE connection show --active | grep ":802-11-wireless:" | head -n1)
        local active_ssid=""
        [[ -n "$active_info" ]] && active_ssid=$(echo "$active_info" | cut -d':' -f2)

        local ip_addr
        ip_addr=$(ip -4 addr show "$wlan_dev" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
        [[ -z "$ip_addr" ]] && ip_addr="No IP"

        local active_sig="0"
        if [[ -n "$active_ssid" ]]; then
            active_sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi list 2>/dev/null | grep "^\*:" | cut -d':' -f2 | head -n1)
            [[ -z "$active_sig" ]] && active_sig="100"
        fi

        local safe_active
        safe_active=$(pango_escape "${active_ssid:-Disconnected}")
        local status_badge="<span alpha='45%'>○ Offline</span>"
        [[ -n "$active_ssid" ]] && status_badge="<span color='#00CCF5'><b>● Connected</b></span>"

        local main_mesg="<b>󰤨 ${safe_active}</b>  ${status_badge}   <span alpha='70%'>IP:</span> <span color='#00CCF5'><b>${ip_addr}</b></span>   <span alpha='70%'>Signal:</span> <span color='#00CCF5'><b>${active_sig}%</b></span>"

        local items=()
        items+=("󰤮  Turn Wi-Fi OFF")
        items+=("󰤨  Scan &amp; Connect to Nearby Wi-Fi")
        items+=("󰤫  Connect to Hidden / Manual Network")

        local saved_profiles
        saved_profiles=$(nmcli -t -f NAME,UUID,TYPE connection show | grep ":802-11-wireless$" | sort -u)
        local count=0
        declare -A prof_name_by_item
        declare -A prof_uuid_by_item

        if [[ -n "$saved_profiles" ]]; then
            while IFS=':' read -r s_name s_uuid s_type; do
                [[ -z "$s_name" ]] && continue
                local is_act="no"
                local s_badge="<span alpha='45%'>○ Saved</span>"
                local s_icon="󰤟"

                if [[ "$s_name" == "$active_ssid" ]]; then
                    is_act="yes"
                    s_badge="<span color='#00CCF5'><b>● Connected (${active_sig}%)</b></span>"
                    s_icon=$(get_signal_icon "$active_sig")
                fi

                local safe_s_name
                safe_s_name=$(pango_escape "$s_name")
                local item_line="${s_icon}  ${safe_s_name}  <span size='small' alpha='50%'>(${s_uuid:0:8}...)</span>  ${s_badge}"

                items+=("$item_line")
                prof_name_by_item["$item_line"]="$s_name"
                prof_uuid_by_item["$item_line"]="$s_uuid"
                ((count++))
            done <<< "$saved_profiles"
        fi

        if [[ "$count" -eq 0 ]]; then
            items+=("󰤮  No saved Wi-Fi profiles found (Click Scan above)")
        fi

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Wi-Fi" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Turn Wi-Fi OFF"*)
                nmcli radio wifi off >/dev/null 2>&1
                notify "Wi-Fi Disabled" "Wi-Fi has been turned OFF" "network-wireless-offline"
                exit 0
                ;;
            *"Scan & Connect to Nearby Wi-Fi"*)
                show_discovery_menu
                ;;
            *"Connect to Hidden / Manual Network"*)
                connect_hidden_network
                ;;
            *"No saved Wi-Fi profiles"*)
                show_discovery_menu
                ;;
            *)
                local sel_name="${prof_name_by_item[$selection]}"
                local sel_uuid="${prof_uuid_by_item[$selection]}"

                if [[ -n "$sel_uuid" ]]; then
                    local is_connected="no"
                    [[ "$sel_name" == "$active_ssid" ]] && is_connected="yes"
                    show_connection_menu "$sel_name" "$sel_uuid" "$is_connected"
                fi
                ;;
        esac
    done
}

main "$@"
