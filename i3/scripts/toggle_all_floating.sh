#!/bin/bash

# Function to toggle floating for all existing windows
toggle_existing_windows() {
    # Get all window IDs
    windows=$(i3-msg -t get_tree | jq -r '.. | objects | select(.window? != null) | .window')
    
    # Toggle each window's floating state
    for win_id in $windows; do
        i3-msg "[id=$win_id]" floating toggle > /dev/null
    done
}

# Function to set up automatic floating for new windows
setup_auto_float() {
    local config_file="$HOME/.config/i3/config"
    local rule="for_window [class=\".*\"] floating enable"
    
    # Check if rule already exists
    if ! grep -q "for_window \[class=\"\.\*\"\] floating enable" "$config_file" 2>/dev/null; then
        echo "$rule" >> "$config_file"
        i3-msg reload > /dev/null
        echo "Auto-float rule added to config and reloaded"
        return 0
    else
        echo "Auto-float rule already exists in config"
        return 1
    fi
}

# Function to remove auto-float rule
remove_auto_float() {
    local config_file="$HOME/.config/i3/config"
    
    # Remove the auto-float rule from config
    if grep -q "for_window \[class=\"\.\*\"\] floating enable" "$config_file" 2>/dev/null; then
        sed -i '/for_window \[class="\..*"\] floating enable/d' "$config_file"
        i3-msg reload > /dev/null
        echo "Auto-float rule removed from config and reloaded"
    else
        echo "Auto-float rule not found in config"
    fi
}

# Main logic
case "${1:-toggle}" in
    "on")
        toggle_existing_windows
        setup_auto_float
        echo "All existing windows toggled to floating, new windows will auto-float"
        ;;
    "off") 
        toggle_existing_windows
        remove_auto_float
        echo "All existing windows toggled to tiling, new windows will be tiled"
        ;;
    "toggle"|*)
        toggle_existing_windows
        b=setup_auto_float
        if $b; then
            echo "All existing windows toggled to floating, new windows will auto-float"
        else
            remove_auto_float
            echo "All existing windows toggled to tiling, new windows will be tiled"
        fi
        echo "All existing windows toggled, new windows will auto-float"
        ;;
esac
