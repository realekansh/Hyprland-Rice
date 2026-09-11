#!/usr/bin/env bash

## Rofi   : Bluetooth Control Menu
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/bluetooth"
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
    local icon="${3:-bluetooth}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Bluetooth" -i "$icon" "$summary" "$msg"
    fi
}

# Get Bluetooth power status
is_powered() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes"
}

# Get Device Icon based on device type / class
get_device_icon() {
    local icon_type="$1"
    case "$icon_type" in
        phone) echo "󰏲" ;;
        audio-card|audio-headset|audio-headphones|headset|headphones) echo "󰋋" ;;
        input-keyboard|keyboard) echo "󰌌" ;;
        input-mouse|mouse) echo "󰍽" ;;
        input-gaming|gamepad|joystick) echo "󰊴" ;;
        computer|laptop) echo "󰍹" ;;
        *) echo "󰂱" ;;
    esac
}

# -------------------------------------------------------------
# Device Action Submenu
# -------------------------------------------------------------
show_device_menu() {
    local mac="$1"
    local raw_name="$2"
    
    while true; do
        local info
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        if [[ -z "$info" ]]; then
            notify "Bluetooth" "Device $raw_name is not reachable or removed." "dialog-warning"
            break
        fi

        local alias
        alias=$(echo "$info" | grep -m1 "Alias:" | sed 's/^[ \t]*Alias:[ \t]*//')
        [[ -z "$alias" ]] && alias="$raw_name"
        local safe_alias
        safe_alias=$(pango_escape "$alias")

        local paired
        paired=$(echo "$info" | grep -m1 "Paired:" | awk '{print $2}')
        local trusted
        trusted=$(echo "$info" | grep -m1 "Trusted:" | awk '{print $2}')
        local connected
        connected=$(echo "$info" | grep -m1 "Connected:" | awk '{print $2}')
        local blocked
        blocked=$(echo "$info" | grep -m1 "Blocked:" | awk '{print $2}')
        local battery
        battery=$(echo "$info" | grep -m1 "Battery Percentage:" | awk -F '[()]' '{print $2}' | tr -d ' ')
        [[ -z "$battery" ]] && battery=$(echo "$info" | grep -m1 "Battery Percentage:" | awk '{print $3}')

        local conn_badge="<span alpha='45%'>○ Disconnected</span>"
        [[ "$connected" == "yes" ]] && conn_badge="<span color='#00CCF5'><b>● Connected</b></span>"
        
        local batt_str=""
        [[ -n "$battery" ]] && batt_str="   <span alpha='70%'>Battery:</span> <span color='#00CCF5'><b>${battery}%</b></span>"

        local mesg="<b>Device:</b> ${safe_alias}  <span alpha='50%'>(${mac})</span>
<b>Status:</b> ${conn_badge}${batt_str}   <span alpha='70%'>Paired:</span> <b>${paired^^}</b>   <span alpha='70%'>Trusted:</span> <b>${trusted^^}</b>"

        local items=()
        if [[ "$connected" == "yes" ]]; then
            items+=("󰂲  Disconnect Device")
        else
            items+=("󰂱  Connect Device")
        fi

        if [[ "$paired" == "yes" ]]; then
            items+=("  Remove Device (Unpair &amp; Forget)")
        else
            items+=("󰐕  Pair &amp; Trust Device")
        fi

        if [[ "$trusted" == "yes" ]]; then
            items+=("󰒃  Untrust Device")
        else
            items+=("󰒃  Trust Device")
        fi

        if [[ "$blocked" == "yes" ]]; then
            items+=("󰂭  Unblock Device")
        else
            items+=("󰂭  Block Device")
        fi

        items+=("󰋽  Show Full Device Info")
        items+=("󰌍  Back to Main Menu")

        local chosen
        chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Device Menu" -mesg "$mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
            exit 0
        fi

        if [[ "$chosen" == *"Back"* ]]; then
            break
        fi

        case "$chosen" in
            *"Connect Device"*)
                notify "Connecting..." "Connecting to ${alias}..." "bluetooth"
                local out
                out=$(bluetoothctl connect "$mac" 2>&1)
                if echo "$out" | grep -qi "successful"; then
                    notify "Bluetooth Connected" "Connected to ${alias}" "bluetooth-active"
                else
                    notify "Connection Failed" "$out" "dialog-error"
                fi
                ;;
            *"Disconnect Device"*)
                bluetoothctl disconnect "$mac" >/dev/null 2>&1
                notify "Bluetooth Disconnected" "Disconnected from ${alias}" "bluetooth"
                ;;
            *"Pair"*)
                notify "Pairing..." "Pairing with ${alias}..." "bluetooth"
                bluetoothctl pair "$mac" >/dev/null 2>&1
                bluetoothctl trust "$mac" >/dev/null 2>&1
                bluetoothctl connect "$mac" >/dev/null 2>&1
                notify "Bluetooth Paired" "Paired and trusted ${alias}" "bluetooth-active"
                ;;
            *"Remove"*|*"Unpair"*|*"Forget"*)
                bluetoothctl remove "$mac" >/dev/null 2>&1
                notify "Bluetooth Device Removed" "Removed ${alias} (${mac})" "bluetooth"
                break
                ;;
            *"Untrust Device"*)
                bluetoothctl untrust "$mac" >/dev/null 2>&1
                notify "Bluetooth" "Untrusted ${alias}" "bluetooth"
                ;;
            *"Trust Device"*)
                bluetoothctl trust "$mac" >/dev/null 2>&1
                notify "Bluetooth" "Trusted ${alias}" "bluetooth"
                ;;
            *"Unblock Device"*)
                bluetoothctl unblock "$mac" >/dev/null 2>&1
                notify "Bluetooth" "Unblocked ${alias}" "bluetooth"
                ;;
            *"Block Device"*)
                bluetoothctl block "$mac" >/dev/null 2>&1
                notify "Bluetooth" "Blocked ${alias}" "bluetooth"
                ;;
            *"Show Full Device Info"*)
                local full_info
                full_info=$(bluetoothctl info "$mac" 2>/dev/null)
                echo "$full_info" | rofi -dmenu -theme "$theme_path" -p "Device Info" -mesg "<b>Details for ${safe_alias} (${mac})</b>"
                local info_exit=$?
                if [[ $info_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
        esac
    done
}

# -------------------------------------------------------------
# Discovery / Available Devices Submenu
# -------------------------------------------------------------
show_discovery_menu() {
    while true; do
        local paired_raw
        paired_raw=$(bluetoothctl devices Paired 2>/dev/null)
        [[ -z "$paired_raw" ]] && paired_raw=$(bluetoothctl devices 2>/dev/null)

        declare -A paired_macs
        while IFS= read -r p_line; do
            [[ -z "$p_line" ]] && continue
            local p_mac
            p_mac=$(echo "$p_line" | awk '{print $2}')
            [[ -n "$p_mac" ]] && paired_macs["$p_mac"]=1
        done <<< "$paired_raw"

        local all_devs
        all_devs=$(bluetoothctl devices 2>/dev/null)
        local items=()
        local count=0
        declare -A dev_mac_by_item
        declare -A dev_name_by_item

        items+=("󰑐  Scan / Rescan Nearby Devices (4s)")
        items+=("󰌍  Back to Main Menu")

        if [[ -n "$all_devs" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local a_mac
                a_mac=$(echo "$line" | awk '{print $2}')
                local a_name
                a_name=$(echo "$line" | cut -d ' ' -f 3-)
                
                if [[ -n "$a_mac" && -z "${paired_macs[$a_mac]}" ]]; then
                    local safe_name
                    safe_name=$(pango_escape "$a_name")
                    local item_line="󰐕  ${safe_name}  <span size='small' alpha='50%'>(${a_mac})</span>  <span color='#DF5296'><b>[Pair &amp; Connect]</b></span>"
                    items+=("$item_line")
                    dev_mac_by_item["$item_line"]="$a_mac"
                    dev_name_by_item["$item_line"]="$a_name"
                    ((count++))
                fi
            done <<< "$all_devs"
        fi

        if [[ "$count" -eq 0 ]]; then
            items+=("󰂲  No new devices found yet (Click Rescan above)")
        fi

        local disc_mesg="<b>󰥈 Discovered Devices</b>  <span alpha='65%'>(${count} available nearby)</span>
<span alpha='60%'>Select any device below to pair and connect immediately</span>"

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Discover & Connect" -mesg "$disc_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        if [[ "$selection" == *"Back"* ]]; then
            break
        fi

        if [[ "$selection" == *"Scan"* || "$selection" == *"Rescan"* ]]; then
            notify "Bluetooth Discovery" "Scanning for nearby devices (4s)..." "bluetooth"
            bluetoothctl --timeout 4 scan on >/dev/null 2>&1
            notify "Bluetooth Discovery" "Scan completed." "bluetooth-active"
            continue
        fi

        local sel_mac="${dev_mac_by_item[$selection]}"
        local sel_name="${dev_name_by_item[$selection]}"

        if [[ -z "$sel_mac" ]]; then
            sel_mac=$(echo "$selection" | grep -o -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
            sel_name=$(echo "$selection" | sed -E 's/^[^\ ]+\ +//; s/\ +\([0-9A-Fa-f:]+\).*$//')
        fi

        if [[ -n "$sel_mac" ]]; then
            show_device_menu "$sel_mac" "$sel_name"
        fi
    done
}

# -------------------------------------------------------------
# Adapter Settings & Controls Submenu
# -------------------------------------------------------------
show_settings_menu() {
    while true; do
        local ctrl_info
        ctrl_info=$(bluetoothctl show 2>/dev/null)
        local ctrl_name
        ctrl_name=$(echo "$ctrl_info" | grep -m1 "Alias:" | sed 's/^[ \t]*Alias:[ \t]*//')
        [[ -z "$ctrl_name" ]] && ctrl_name="Bluetooth Controller"
        local safe_ctrl
        safe_ctrl=$(pango_escape "$ctrl_name")

        local discoverable
        discoverable=$(echo "$ctrl_info" | grep -m1 "Discoverable:" | awk '{print $2}')
        local pairable
        pairable=$(echo "$ctrl_info" | grep -m1 "Pairable:" | awk '{print $2}')

        local disc_color="#888888"
        [[ "$discoverable" == "yes" ]] && disc_color="#00CCF5"
        local pair_color="#888888"
        [[ "$pairable" == "yes" ]] && pair_color="#00CCF5"

        local set_mesg="<b>󰒓 Adapter Settings:</b> ${safe_ctrl}
<span alpha='70%'>Discoverable:</span> <span color='${disc_color}'><b>${discoverable^^}</b></span>   <span alpha='70%'>Pairable:</span> <span color='${pair_color}'><b>${pairable^^}</b></span>"

        local items=()
        items+=("󰂲  Turn Bluetooth OFF")
        if [[ "$discoverable" == "yes" ]]; then
            items+=("󰂰  Discoverable Mode: ON  (Click to Disable)")
        else
            items+=("󰂰  Discoverable Mode: OFF (Click to Enable)")
        fi

        if [[ "$pairable" == "yes" ]]; then
            items+=("󰂱  Pairable Mode: ON     (Click to Disable)")
        else
            items+=("󰂱  Pairable Mode: OFF    (Click to Enable)")
        fi

        items+=("󰚥  Unblock RFKill &amp; Reload Daemon")
        items+=("󰋽  Show Controller Full Details")
        items+=("󰌍  Back to Main Menu")

        local choice
        choice=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Settings" -mesg "$set_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$choice" ]]; then
            exit 0
        fi

        if [[ "$choice" == *"Back"* ]]; then
            break
        fi

        case "$choice" in
            *"Turn Bluetooth OFF"*)
                bluetoothctl power off >/dev/null 2>&1
                notify "Bluetooth" "Bluetooth has been powered OFF" "bluetooth-disabled"
                exit 0
                ;;
            *"Discoverable Mode:"*)
                if [[ "$discoverable" == "yes" ]]; then
                    bluetoothctl discoverable off >/dev/null 2>&1
                    notify "Bluetooth" "Discoverable mode DISABLED" "bluetooth"
                else
                    bluetoothctl discoverable on >/dev/null 2>&1
                    notify "Bluetooth" "Discoverable mode ENABLED" "bluetooth-active"
                fi
                ;;
            *"Pairable Mode:"*)
                if [[ "$pairable" == "yes" ]]; then
                    bluetoothctl pairable off >/dev/null 2>&1
                    notify "Bluetooth" "Pairable mode DISABLED" "bluetooth"
                else
                    bluetoothctl pairable on >/dev/null 2>&1
                    notify "Bluetooth" "Pairable mode ENABLED" "bluetooth-active"
                fi
                ;;
            *"Unblock RFKill"*)
                rfkill unblock bluetooth >/dev/null 2>&1
                notify "Bluetooth" "Unblocked RFKill" "bluetooth"
                ;;
            *"Show Controller Full Details"*)
                echo "$ctrl_info" | rofi -dmenu -theme "$theme_path" -p "Controller Info" -mesg "<b>Controller Details for ${safe_ctrl}</b>"
                local info_exit=$?
                if [[ $info_exit -ne 0 ]]; then
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
        if ! is_powered; then
            local off_mesg="<b>Bluetooth Status:</b> <span color='#DF5296'><b>Powered OFF</b></span>
<span alpha='65%'>Enable Bluetooth to scan and connect devices</span>"
            local items=()
            items+=("󰂯  Turn Bluetooth ON")
            items+=("󰚥  Unblock RFKill &amp; Reload Service")
            items+=("󰈆  Exit")
            
            local chosen_off
            chosen_off=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Bluetooth (OFF)" -mesg "$off_mesg" -markup-rows)
            local rofi_exit=$?

            if [[ $rofi_exit -ne 0 || -z "$chosen_off" || "$chosen_off" == *"Exit"* ]]; then
                exit 0
            fi

            case "$chosen_off" in
                *"Turn Bluetooth ON"*)
                    rfkill unblock bluetooth >/dev/null 2>&1
                    bluetoothctl power on >/dev/null 2>&1
                    sleep 0.5
                    notify "Bluetooth" "Bluetooth is now powered ON" "bluetooth-active"
                    ;;
                *"Unblock RFKill"*)
                    rfkill unblock bluetooth >/dev/null 2>&1
                    notify "Bluetooth" "Unblocked RFKill for Bluetooth" "bluetooth"
                    ;;
                *)
                    exit 0
                    ;;
            esac
            continue
        fi

        local ctrl_info
        ctrl_info=$(bluetoothctl show 2>/dev/null)
        local ctrl_name
        ctrl_name=$(echo "$ctrl_info" | grep -m1 "Alias:" | sed 's/^[ \t]*Alias:[ \t]*//')
        [[ -z "$ctrl_name" ]] && ctrl_name="Bluetooth Controller"
        local safe_ctrl
        safe_ctrl=$(pango_escape "$ctrl_name")

        local discoverable
        discoverable=$(echo "$ctrl_info" | grep -m1 "Discoverable:" | awk '{print $2}')
        local pairable
        pairable=$(echo "$ctrl_info" | grep -m1 "Pairable:" | awk '{print $2}')

        local disc_color="#888888"
        [[ "$discoverable" == "yes" ]] && disc_color="#00CCF5"
        local pair_color="#888888"
        [[ "$pairable" == "yes" ]] && pair_color="#00CCF5"

        local main_mesg="<b>󰂯 ${safe_ctrl}</b>  <span color='#00CCF5'><b>[Active]</b></span>   <span alpha='70%'>Discoverable:</span> <span color='${disc_color}'><b>${discoverable^^}</b></span>   <span alpha='70%'>Pairable:</span> <span color='${pair_color}'><b>${pairable^^}</b></span>"

        local items=()
        items+=("󰂲  Turn Bluetooth OFF")
        items+=("󰥈  Scan &amp; Connect New Devices")
        items+=("󰒓  Adapter Settings &amp; Controls")

        local paired_list
        paired_list=$(bluetoothctl devices Paired 2>/dev/null)
        [[ -z "$paired_list" ]] && paired_list=$(bluetoothctl devices 2>/dev/null)

        local dev_count=0
        declare -A pdev_mac_by_item
        declare -A pdev_name_by_item

        if [[ -n "$paired_list" ]]; then
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local dev_mac
                dev_mac=$(echo "$line" | awk '{print $2}')
                local dev_name
                dev_name=$(echo "$line" | cut -d ' ' -f 3-)
                [[ -z "$dev_mac" ]] && continue
                
                local d_info
                d_info=$(bluetoothctl info "$dev_mac" 2>/dev/null)
                local d_icon_type
                d_icon_type=$(echo "$d_info" | grep -m1 "Icon:" | awk '{print $2}')
                local icon
                icon=$(get_device_icon "$d_icon_type")

                local d_conn
                d_conn=$(echo "$d_info" | grep -m1 "Connected:" | awk '{print $2}')
                local d_battery
                d_battery=$(echo "$d_info" | grep -m1 "Battery Percentage:" | awk -F '[()]' '{print $2}' | tr -d ' ')
                [[ -z "$d_battery" ]] && d_battery=$(echo "$d_info" | grep -m1 "Battery Percentage:" | awk '{print $3}')

                local safe_name
                safe_name=$(pango_escape "$dev_name")

                local d_badge=""
                if [[ "$d_conn" == "yes" ]]; then
                    local batt_tag=""
                    [[ -n "$d_battery" ]] && batt_tag="  󰥉 <span color='#00CCF5'><b>${d_battery}%</b></span>"
                    d_badge="<span color='#00CCF5'><b>● Connected</b></span>${batt_tag}"
                else
                    d_badge="<span alpha='45%'>○ Paired</span>"
                fi

                local item_line="${icon}  ${safe_name}  <span size='small' alpha='50%'>(${dev_mac})</span>  ${d_badge}"
                items+=("$item_line")
                pdev_mac_by_item["$item_line"]="$dev_mac"
                pdev_name_by_item["$item_line"]="$dev_name"
                ((dev_count++))
            done <<< "$paired_list"
        fi

        if [[ "$dev_count" -eq 0 ]]; then
            items+=("󰂲  No paired devices (Click Scan above to pair)")
        fi

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Bluetooth" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Turn Bluetooth OFF"*)
                bluetoothctl power off >/dev/null 2>&1
                notify "Bluetooth" "Bluetooth has been powered OFF" "bluetooth-disabled"
                exit 0
                ;;
            *"Scan"*)
                show_discovery_menu
                ;;
            *"Settings"*)
                show_settings_menu
                ;;
            *"No paired devices"*)
                show_discovery_menu
                ;;
            *)
                local selected_mac="${pdev_mac_by_item[$selection]}"
                local selected_name="${pdev_name_by_item[$selection]}"

                if [[ -z "$selected_mac" ]]; then
                    selected_mac=$(echo "$selection" | grep -o -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
                    selected_name=$(echo "$selection" | sed -E 's/^[^\ ]+\ +//; s/\ +\([0-9A-Fa-f:]+\).*$//')
                fi
                
                if [[ -n "$selected_mac" ]]; then
                    show_device_menu "$selected_mac" "$selected_name"
                fi
                ;;
        esac
    done
}

main "$@"
