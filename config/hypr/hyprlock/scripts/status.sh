#!/usr/bin/env bash

############ Variables ############
enable_battery=false
battery_charging=false

####### Check availability ########
for battery in /sys/class/power_supply/*BAT*; do
  if [[ -f "$battery/uevent" ]]; then
    enable_battery=true
    if [[ -f "$battery/status" ]] && [[ $(cat "$battery/status") == "Charging" ]]; then
      battery_charging=true
    fi
    break
  fi
done

############# Output #############
if [[ $enable_battery == true ]]; then
  if [[ $battery_charging == true ]]; then
    echo -n "(+) "
  fi
  if [[ -f "$battery/capacity" ]]; then
    echo -n "$(cat "$battery/capacity")"%
  fi
  if [[ $battery_charging == false ]]; then
    echo -n " remaining"
  fi
fi

echo ''
