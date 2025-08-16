#!/bin/sh

MUSIC_DESK="MUSIC"
CIDER_CLASS="Cider"

# Function to move Cider to correct desktop
move_cider_if_needed() {
    window_id="$1"
    
    # Validate window ID format and ensure it exists
    if ! echo "$window_id" | grep -q '^0x[0-9A-Fa-f]\+$' || ! bspc query -N -n "$window_id" > /dev/null 2>&1; then
        return
    fi
    
    # Check if this is a Cider window
    class_name=$(bspc query -T -n "$window_id" 2>/dev/null | jq -r '.client.className // empty')
    
    if [ "$class_name" = "$CIDER_CLASS" ]; then
        current_desktop=$(bspc query -D -n "$window_id" --names 2>/dev/null)
        
        if [ -n "$current_desktop" ] && [ "$current_desktop" != "$MUSIC_DESK" ]; then
            echo "Moving Cider window $window_id from $current_desktop to $MUSIC_DESK"
            bspc node "$window_id" -d "$MUSIC_DESK"
        fi
    fi
}

echo "Starting Cider auto-mover with event monitoring..."

# Listen to bspwm events
bspc subscribe node_add node_transfer | while read -r event monitor desktop node; do
    case "$event" in
        node_add|node_transfer)
            # The node field might contain multiple IDs, process each one
            for window_id in $node; do
                move_cider_if_needed "$window_id"
            done
            ;;
    esac
done
