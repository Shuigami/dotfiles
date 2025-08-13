#!/bin/sh

mute=$(pactl get-sink-mute @DEFAULT_SINK@ | cut -d ' ' -f 2)
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | tr -s ' ' | cut -d ' ' -f 5 | sed 's/%//')

icon() {
    if [ "$mute" = "yes" ]; then
        echo "󰝟"
    elif [ "$volume" -eq 0 ]; then
        echo ""
    elif [ "$volume" -le 50 ]; then
        echo ""
    else
        echo ""
    fi
}

num() {
    echo "$volume"
}

[ "$1" = "icon" ] && icon && exit
[ "$1" = "num" ] && num && exit
