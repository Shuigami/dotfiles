#!/bin/bash

icon() {
  if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]; then
    echo "󰂲"
  else
    if bluetoothctl info | grep -q "Device"; then
      echo "󰂱"
    else
      echo "󰂯"
    fi
  fi
}

status() {
  if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]; then
    echo "off"
  else
    if bluetoothctl info | grep -q "Device"; then
      echo "connected"
    else
      echo "disconnected"
    fi
  fi
}

name() {
  bluetoothctl info | grep "Name:" | awk '{for(i=2;i<=NF;i++) printf $i " "; print ""}' | sed 's/ $//'
}

[ "$1" = "icon" ] && icon && exit
[ "$1" = "status" ] && status && exit
[ "$1" = "name" ] && name && exit