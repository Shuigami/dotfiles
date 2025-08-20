#!/bin/sh

# Function to output Wi-Fi icon based on signal strength
symbol() {
    # Check if WiFi interface is up/enabled
    interface_state=$(ip link show wlo1 2>/dev/null | grep -o "state [A-Z]*" | awk '{print $2}')
    
    # If interface is DOWN, WiFi is disabled/off
    if [ "$interface_state" = "DOWN" ]; then
        echo "wifi-off"  # WiFi disabled/off
        exit
    fi
    
    # Get the current connection info
    status=$(iw dev wlo1 link 2>/dev/null)
    
    # If WiFi is enabled but not connected
    if [ "$status" = "Not connected" ] || [ -z "$status" ]; then
        echo "wifi-disconnected"  # WiFi enabled but disconnected
        exit
    fi

    # Extract signal strength in dBm (example: "signal: -45 dBm")
    strength=$(echo "$status" | grep 'signal:' | awk '{print $2}')

    # Convert to positive value for easier handling
    abs_strength=$(( -1 * strength ))

    # Choose icon based on signal strength
    if [ "$abs_strength" -lt 50 ]; then
        echo "wifi-excellent"  # Excellent
    elif [ "$abs_strength" -lt 60 ]; then
        echo "wifi-good"  # Good
    elif [ "$abs_strength" -lt 70 ]; then
        echo "wifi-fair"  # Fair
    else
        echo "wifi-weak"  # Weak
    fi
}

# Function to print SSID
name() {
    # Check if WiFi interface is up/enabled
    interface_state=$(ip link show wlo1 2>/dev/null | grep -o "state [A-Z]*" | awk '{print $2}')
    
    # If interface is DOWN, WiFi is disabled/off
    if [ "$interface_state" = "DOWN" ]; then
        echo "WiFi Off"
        exit
    fi
    
    # Get SSID if connected
    ssid=$(iwgetid -r 2>/dev/null)
    
    if [ -z "$ssid" ]; then
        echo "Disconnected"
    else
        echo "$ssid"
    fi
}

[ "$1" = "icon" ] && symbol && exit
[ "$1" = "name" ] && name && exit
