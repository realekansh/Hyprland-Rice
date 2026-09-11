#!/usr/bin/env bash

## Rofi   : Unified Network Dashboard
## Themes : style-1 to style-10

dir="$HOME/.config/rofi/network"
theme='style-1'
theme_path="${dir}/${theme}.rasi"

wifi_script="$HOME/.config/rofi/wifi/wifi.sh"
eth_script="$HOME/.config/rofi/ethernet/ethernet.sh"
vpn_script="$HOME/.config/rofi/vpn/vpn.sh"

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
    local icon="${3:-network-workgroup}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Network Manager" -i "$icon" "$summary" "$msg"
    fi
}

main() {
    while true; do
        local wifi_radio
        wifi_radio=$(nmcli radio wifi 2>/dev/null)
        local wifi_active_ssid=""
        if [[ "$wifi_radio" == "enabled" ]]; then
            wifi_active_ssid=$(nmcli -t -f DEVICE,NAME,TYPE connection show --active | grep ":802-11-wireless$" | head -n1 | cut -d':' -f2)
            [[ -z "$wifi_active_ssid" ]] && wifi_active_ssid="Disconnected"
        else
            wifi_active_ssid="OFF"
        fi

        local eth_dev
        eth_dev=$(nmcli -t -f DEVICE,TYPE device | grep ":ethernet$" | grep -v "veth" | head -n1 | cut -d':' -f1)
        [[ -z "$eth_dev" ]] && eth_dev="eno1"
        local eth_state
        eth_state=$(nmcli -t -f DEVICE,STATE device | grep "^${eth_dev}:" | cut -d':' -f2)
        [[ -z "$eth_state" ]] && eth_state="unavailable"

        local active_vpn
        active_vpn=$(nmcli -t -f NAME,TYPE,STATE connection show --active | grep -E ":(vpn|wireguard|tun):" | head -n1 | cut -d':' -f1)
        [[ -z "$active_vpn" ]] && active_vpn="None"

        local net_state
        net_state=$(nmcli -t -f STATE general status 2>/dev/null)
        local net_badge="<span alpha='45%'>○ Offline</span>"
        [[ "$net_state" == "connected" ]] && net_badge="<span color='#00CCF5'><b>● Connected</b></span>"

        local safe_wifi
        safe_wifi=$(pango_escape "$wifi_active_ssid")
        local safe_vpn
        safe_vpn=$(pango_escape "$active_vpn")

        local main_mesg="<b>󰖩 Network Hub</b>   ${net_badge}   <span alpha='70%'>Wi-Fi:</span> <b>${safe_wifi}</b>   <span alpha='70%'>Eth:</span> <b>${eth_state}</b>   <span alpha='70%'>VPN:</span> <b>${safe_vpn}</b>"

        local items=()
        items+=("󰤨  Wi-Fi Control Center (${safe_wifi})")
        items+=("󰈀  Ethernet Control Center (${eth_dev}: ${eth_state})")
        items+=("󰌾  VPN &amp; Security Tunnels (${safe_vpn})")

        local nm_net_state
        nm_net_state=$(nmcli networking 2>/dev/null)
        if [[ "$nm_net_state" == "enabled" ]]; then
            items+=("󰤮  Toggle Networking / Flight Mode [Active: ON]")
        else
            items+=("󰤮  Toggle Networking / Flight Mode [Active: OFF]")
        fi

        items+=("󰋽  Full Network Diagnostics &amp; IP Routing")

        local selection
        selection=$(printf '%s\n' "${items[@]}" | rofi -dmenu -theme "$theme_path" -p "Network" -mesg "$main_mesg" -markup-rows)
        local rofi_exit=$?

        if [[ $rofi_exit -ne 0 || -z "$selection" ]]; then
            exit 0
        fi

        case "$selection" in
            *"Wi-Fi Control Center"*)
                if [[ -x "$wifi_script" ]]; then
                    "$wifi_script"
                fi
                ;;
            *"Ethernet Control Center"*)
                if [[ -x "$eth_script" ]]; then
                    "$eth_script"
                fi
                ;;
            *"VPN & Security Tunnels"*|*"VPN"*)
                if [[ -x "$vpn_script" ]]; then
                    "$vpn_script"
                fi
                ;;
            *"Toggle Networking"*)
                if [[ "$nm_net_state" == "enabled" ]]; then
                    nmcli networking off >/dev/null 2>&1
                    notify "Airplane Mode" "All networking disabled" "network-offline"
                else
                    nmcli networking on >/dev/null 2>&1
                    notify "Networking Enabled" "Networking enabled" "network-workgroup"
                fi
                ;;
            *"Full Network Diagnostics"*)
                local net_diag
                net_diag=$(ip -br addr 2>/dev/null)
                local routes
                routes=$(ip route show 2>/dev/null)
                local dns
                dns=$(cat /etc/resolv.conf 2>/dev/null | grep "nameserver")
                echo -e "=== Interfaces ===\n${net_diag}\n\n=== DNS Nameservers ===\n${dns}\n\n=== Routing Table ===\n${routes}" | rofi -dmenu -theme "$theme_path" -p "Diagnostics" -mesg "<b>System Network Diagnostics</b>"
                local d_exit=$?
                if [[ $d_exit -ne 0 ]]; then
                    exit 0
                fi
                ;;
        esac
    done
}

main "$@"
