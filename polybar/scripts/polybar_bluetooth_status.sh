#!/bin/bash

# Check if bluetooth is on or off
if [ $(bluetoothctl show | grep "Powered: yes" | wc -c) -eq 0 ]; then
  # Bluetooth is off
  echo "%{F#707880}󰂲%{F-}" # Using 'disabled' color from your config
else
  # Bluetooth is on
  if bluetoothctl info | grep -q "Device"; then
    # A device is connected
    device_name=$(bluetoothctl info | grep "Name:" | awk '{for(i=2;i<=NF;i++) printf $i " "; print ""}' | sed 's/ $//')
    echo "%{F#8fdbbb}󰂱%{F-} $device_name" # Using 'primary' color
  else
    # No device is connected
    echo "%{F#8fdbbb}󰂯%{F-}" # Using 'primary' color
  fi
fi
