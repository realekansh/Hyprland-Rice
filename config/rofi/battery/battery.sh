#!/usr/bin/env bash

## Rofi   : Battery & Power Profile Manager
## Themes : style-1 to style-10 (2-Column Info & Modes Layout)

dir="$HOME/.config/rofi/battery"
theme='style-1'
theme_path="${dir}/${theme}.rasi"
state_file="${dir}/current_profile"

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
    local icon="${3:-battery}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Power Manager" -i "$icon" "$summary" "$msg"
    fi
}

# Dynamic Battery Icon based on charge level
get_battery_icon() {
    local pct="${1:-100}"
    if [[ "$pct" -ge 95 ]]; then echo "󰁹"
    elif [[ "$pct" -ge 85 ]]; then echo "󰂂"
    elif [[ "$pct" -ge 75 ]]; then echo "󰂁"
    elif [[ "$pct" -ge 65 ]]; then echo "󰂀"
    elif [[ "$pct" -ge 55 ]]; then echo "󰁿"
    elif [[ "$pct" -ge 45 ]]; then echo "󰁾"
    elif [[ "$pct" -ge 35 ]]; then echo "󰁽"
    elif [[ "$pct" -ge 25 ]]; then echo "󰁼"
    elif [[ "$pct" -ge 15 ]]; then echo "󰁻"
    elif [[ "$pct" -ge 10 ]]; then echo "󰁺"
    else echo "󰂎"
    fi
}

# Apply power mode
set_power_mode() {
    local mode="$1"
    local epp=""
    local gov=""
    local label=""

    case "$mode" in
        performance)
            epp="performance"
            gov="performance"
            label="Performance Mode"
            ;;
        balanced)
            epp="balance_performance"
            gov="powersave"
            label="Balanced Mode"
            ;;
        power_saver)
            epp="balance_power"
            gov="powersave"
            label="Power Saver Mode"
            ;;
        ultra_saver)
            epp="power"
            gov="powersave"
            label="Ultra Eco Saver"
            ;;
    esac

    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -w "$f" ]]; then
            echo "$epp" > "$f" 2>/dev/null
        fi
    done

    for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -w "$g" ]]; then
            echo "$gov" > "$g" 2>/dev/null
        fi
    done

    echo "$mode" > "$state_file"
    notify "Power Profile Changed" "Switched to ${label}" "battery-good"
}

# Get currently active mode
get_current_power_mode() {
    if [[ -f "$state_file" ]]; then
        cat "$state_file"
        return
    fi

    local sys_epp
    sys_epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
    case "$sys_epp" in
        performance) echo "performance" ;;
        balance_performance|default) echo "balanced" ;;
        balance_power) echo "power_saver" ;;
        power) echo "ultra_saver" ;;
        *) echo "balanced" ;;
    esac
}

# Build the persistent Telemetry Info Card (Left Side)
build_info_card() {
    local bat_dev
    bat_dev=$(upower -e 2>/dev/null | grep -E "battery|DisplayDevice" | head -n1)
    local bat_info=""
    [[ -n "$bat_dev" ]] && bat_info=$(upower -i "$bat_dev" 2>/dev/null)

    local pct
    pct=$(echo "$bat_info" | grep -m1 "percentage:" | awk '{print $2}' | tr -d '%')
    if [[ -z "$pct" ]]; then
        pct=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
        [[ -z "$pct" ]] && pct="100"
    fi

    local state
    state=$(echo "$bat_info" | grep -m1 "state:" | awk '{print $2}')
    if [[ -z "$state" ]]; then
        state=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
        [[ -z "$state" ]] && state="fully-charged"
    fi

    local ac_online="no"
    local ac_dev
    ac_dev=$(upower -e 2>/dev/null | grep -E "line_power|AC" | head -n1)
    if [[ -n "$ac_dev" ]]; then
        local ac_val
        ac_val=$(upower -i "$ac_dev" 2>/dev/null | grep -m1 "online:" | awk '{print $2}')
        [[ "$ac_val" == "yes" ]] && ac_online="yes"
    else
        local sys_ac
        sys_ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)
        [[ "$sys_ac" == "1" ]] && ac_online="yes"
    fi

    local energy_rate
    energy_rate=$(echo "$bat_info" | grep -m1 "energy-rate:" | awk '{print $2, $3}')
    [[ -z "$energy_rate" ]] && energy_rate="0.0 W"

    local voltage
    voltage=$(echo "$bat_info" | grep -m1 "voltage:" | awk '{print $2, $3}')
    [[ -z "$voltage" ]] && voltage="12.8 V"

    local capacity
    capacity=$(echo "$bat_info" | grep -m1 "capacity:" | awk '{print $2}')
    [[ -z "$capacity" ]] && capacity="100%"

    local time_str=""
    if [[ "$state" == "discharging" ]]; then
        local t_rem
        t_rem=$(echo "$bat_info" | grep -m1 "time to empty:" | cut -d':' -f2- | sed 's/^[ \t]*//')
        [[ -n "$t_rem" ]] && time_str="<b>Remaining:</b>   <span color='#00CCF5'><b>${t_rem}</b></span>"
    elif [[ "$state" == "charging" ]]; then
        local t_full
        t_full=$(echo "$bat_info" | grep -m1 "time to full:" | cut -d':' -f2- | sed 's/^[ \t]*//')
        [[ -n "$t_full" ]] && time_str="<b>Until Full:</b>   <span color='#00CCF5'><b>${t_full}</b></span>"
    fi

    local state_tag="<span color='#00CCF5'><b>● Fully Charged (Plugged In)</b></span>"
    if [[ "$state" == "charging" ]]; then
        state_tag="<span color='#00CCF5'><b>● Charging (Plugged In)</b></span>"
    elif [[ "$state" == "discharging" ]]; then
        state_tag="<span color='#E25F3E'><b>● Discharging (Battery)</b></span>"
    fi

    local bat_icon
    bat_icon=$(get_battery_icon "$pct")

    local header_line=""
    if [[ "$ac_online" == "yes" ]]; then
        header_line="<span size='xx-large'><b>${bat_icon} <span color='#00CCF5'></span> ${pct}%</b></span>"
    else
        header_line="<span size='xx-large'><b>${bat_icon} ${pct}%</b></span>"
    fi

    local current_mode
    current_mode=$(get_current_power_mode)
    local mode_label="${current_mode^^}"

    local card="${header_line}
${state_tag}

<b>Health:</b>      <span color='#00CCF5'><b>${capacity}</b></span>
<b>Power Draw:</b>  <span color='#00CCF5'><b>${energy_rate}</b></span>
<b>Voltage:</b>     <span color='#00CCF5'><b>${voltage}</b></span>"

    [[ -n "$time_str" ]] && card+="
${time_str}"

    card+="

<b>Active Profile:</b>
<span color='#DF5296'><b>[ ${mode_label} ]</b></span>"

    echo "$card"
}

# -------------------------------------------------------------
# UPower Diagnostics Submenu
# -------------------------------------------------------------
show_upower_diagnostics() {
    local bat_dev
    bat_dev=$(upower -e 2>/dev/null | grep -E "battery|DisplayDevice" | head -n1)
    local raw_info
    raw_info=$(upower -i "$bat_dev" 2>/dev/null)

    local items=()
    items+=("󰌍  Back to Power Modes")

    if [[ -n "$raw_info" ]]; then
        while IFS= read -r line; do
            line=$(echo "$line" | sed 's/^[ \t]*//')
            [[ -z "$line" || "$line" =~ ^has\  || "$line" == "battery" ]] && continue
            if [[ "$line" == *":"* ]]; then
                local k v
                k=$(echo "$line" | cut -d':' -f1 | sed 's/^[ \t]*//; s/[ \t]*$//')
                v=$(echo "$line" | cut -d':' -f2- | sed 's/^[ \t]*//; s/[ \t]*$//')
                [[ -z "$v" ]] && continue
                local safe_k
                safe_k=$(pango_escape "$k")
                local safe_v
                safe_v=$(pango_escape "$v")
                items+=("󰋽  ${safe_k}  <span color='#00CCF5'><b>${safe_v}</b></span>")
            fi
        done <<< "$raw_info"
    fi

    local info_card
    info_card=$(build_info_card)

    local chosen
    chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Diagnostics" -mesg "$info_card" -markup-rows)
    local rofi_exit=$?

    if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
        exit 0
    fi
}

# -------------------------------------------------------------
# Hardware Specs Submenu
# -------------------------------------------------------------
show_hardware_specs() {
    local sysfs_info
    sysfs_info=$(cat /sys/class/power_supply/BAT*/uevent 2>/dev/null)

    local items=()
    items+=("󰌍  Back to Power Modes")

    if [[ -n "$sysfs_info" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" == *"="* ]]; then
                local k v
                k=$(echo "$line" | cut -d'=' -f1 | sed 's/^POWER_SUPPLY_//')
                v=$(echo "$line" | cut -d'=' -f2-)
                local safe_k
                safe_k=$(pango_escape "$k")
                local safe_v
                safe_v=$(pango_escape "$v")
                items+=("󰚥  ${safe_k}  <span color='#00CCF5'><b>${safe_v}</b></span>")
            fi
        done <<< "$sysfs_info"
    fi

    local info_card
    info_card=$(build_info_card)

    local chosen
    chosen=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Hardware Specs" -mesg "$info_card" -markup-rows)
    local rofi_exit=$?

    if [[ $rofi_exit -ne 0 || -z "$chosen" ]]; then
        exit 0
    fi
}

# -------------------------------------------------------------
# Main Application Loop
# -------------------------------------------------------------
main() {
    while true; do
        local main_mesg
        main_mesg=$(build_info_card)

        local current_mode
        current_mode=$(get_current_power_mode)

        local items=()
        
        # 1. Performance
        if [[ "$current_mode" == "performance" ]]; then
            items+=("  Performance Mode         <span color='#DF5296'>● Active Max Speed</span>")
        else
            items+=("  Performance Mode         <span alpha='45%'>○ Switch Max Speed</span>")
        fi

        # 2. Balanced
        if [[ "$current_mode" == "balanced" ]]; then
            items+=("  Balanced Mode            <span color='#DF5296'>● Active Balanced</span>")
        else
            items+=("  Balanced Mode            <span alpha='45%'>○ Switch Balanced</span>")
        fi

        # 3. Power Saver
        if [[ "$current_mode" == "power_saver" ]]; then
            items+=("  Power Saver Mode         <span color='#DF5296'>● Active Power Saver</span>")
        else
            items+=("  Power Saver Mode         <span alpha='45%'>○ Switch Power Saver</span>")
        fi

        # 4. Ultra Eco Saver
        if [[ "$current_mode" == "ultra_saver" ]]; then
            items+=("󰾆  Ultra Eco Saver          <span color='#DF5296'>● Active Ultra Eco</span>")
        else
            items+=("󰾆  Ultra Eco Saver          <span alpha='45%'>○ Switch Ultra Eco</span>")
        fi

        items+=("󰋽  Show Full UPower Battery Diagnostics")
        items+=("󰚥  Battery Hardware &amp; Health Specifications")

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Power Modes" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Performance Mode"*)
                set_power_mode "performance"
                ;;
            *"Balanced Mode"*)
                set_power_mode "balanced"
                ;;
            *"Power Saver Mode"*)
                set_power_mode "power_saver"
                ;;
            *"Ultra Eco Saver"*)
                set_power_mode "ultra_saver"
                ;;
            *"Show Full UPower"*)
                show_upower_diagnostics
                ;;
            *"Battery Hardware & Health"*)
                show_hardware_specs
                ;;
        esac
    done
}

main "$@"
