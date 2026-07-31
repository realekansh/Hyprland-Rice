threshhold_green=0
threshhold_yellow=15
threshhold_red=100

# -------------------------------------------------------
# Calculate available updates from pacman and AUR (using yay)
# -------------------------------------------------------
list_updates_arch=$(checkupdates | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g");
list_updates_aur=$(yay -Qua | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g");

if ! updates_arch=$(checkupdates | wc -l); then
    updates_arch=0
fi

if ! updates_aur=$(yay -Qua | wc -l); then
    updtates_aur=0
fi

list_updates=""

if [ "$updates_arch" -gt 0 ]; then
    list_updates+="${list_updates_arch}"
    if [ "$updates_aur" -gt 0 ]; then ## TODO: clean this up
        list_updates+="\n"
    fi
fi

if [ "$updates_aur" -gt 0 ]; then
    list_updates+="${list_updates_aur}"
fi

# -------------------------------------------------------
# Output JSON for the Waybar custom-updates module
# -------------------------------------------------------
updates=$(("$updates_arch" + "$updates_aur"))
tooltip="Update the system (<span size=\"small\">${updates} package(s)):"$'\n'"${list_updates}</span>"

if [ "$updates" -lt $threshhold_yellow ]; then
    css_class="green"
elif [ "$updates" -lt $threshhold_red ]; then
    css_class="yellow"
else
    css_class="red"
fi

jq -nc \
    --arg text "$updates" \
    --arg tooltip "$tooltip" \
    --arg class "$css_class" \
    '{
        text: $text,
        tooltip: $tooltip,
        class: $class
    }'