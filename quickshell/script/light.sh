#!/bin/sh

light=$(light -G | sed 's/\.00//g')

icon() {
    if [ "$light" -ge 99 ]; then
        echo "󰛨"
    elif [ "$light" -ge 90 ]; then
        echo "󱩖"
    elif [ "$light" -ge 80 ]; then
        echo "󱩕"
    elif [ "$light" -ge 70 ]; then
        echo "󱩔"
    elif [ "$light" -ge 60 ]; then
        echo "󱩓"
    elif [ "$light" -ge 50 ]; then
        echo "󱩒"
    elif [ "$light" -ge 40 ]; then
        echo "󱩑"
    elif [ "$light" -ge 30 ]; then
        echo "󱩐"
    elif [ "$light" -ge 20 ]; then
        echo "󱩏"
    elif [ "$light" -ge 10 ]; then
        echo "󱩎"
    else
        echo "󰛩"
    fi
}

num() {
    echo "$light"
}

[ "$1" = "icon" ] && icon && exit
[ "$1" = "num" ] && num && exit
