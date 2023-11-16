#!/bin/sh

battery=$(cat /sys/class/power_supply/BAT0/capacity)

if [ $battery -le 20 ]
then
    notify-send "Battery low" "Battery level is ${battery}%!"
fi
