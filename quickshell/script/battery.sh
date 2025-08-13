#!/bin/sh

battery=$(cat /sys/class/power_supply/BAT0/capacity)
charging=$(cat /sys/class/power_supply/BAT0/status)


icon() {
    if [ "$battery" -ge 99 ]; then
        echo "󰁹"
    elif [ "$battery" -ge 90 ]; then
        echo "󰂂"
    elif [ "$battery" -ge 80 ]; then
        echo "󰂁"
    elif [ "$battery" -ge 70 ]; then
        echo "󰂀"
    elif [ "$battery" -ge 60 ]; then
        echo "󰁿"
    elif [ "$battery" -ge 50 ]; then
        echo "󰁾"
    elif [ "$battery" -ge 40 ]; then
        echo "󰁽"
    elif [ "$battery" -ge 30 ]; then
        echo "󰁼"
    elif [ "$battery" -ge 20 ]; then
        echo "󰁻"
    elif [ "$battery" -ge 10 ]; then
        echo "󰁺"
    else
        echo "󰂎"
    fi
}

num() {
    echo "$battery"
}

charging() {
    echo "$charging"
}

[ "$1" = "icon" ] && icon && exit
[ "$1" = "num" ] && num && exit
[ "$1" = "charging" ] && charging && exit
