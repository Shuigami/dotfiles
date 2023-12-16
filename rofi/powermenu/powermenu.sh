#!/usr/bin/env bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# Current Theme
dir="$HOME/.config/rofi/powermenu"
theme='style-1'

# CMDs
lastlogin="`last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7`"
uptime="`uptime -p | sed -e 's/up //g'`"
host="shuiarch"

# Options
hibernate='  Hibernate'
shutdown='󰐥 Turn Off'
reboot='󰆷  Reboot'
lock=' Lock'
suspend='󰤄 Sleep'
logout='󰗼 Log out'
yes='󰄬 Yes'
no=' No'

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "  $USER@$host" \
		-mesg "   Uptime: $uptime" \
		-theme ${dir}/${theme}.rasi
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 400px;}' \
		-theme-str 'mainbox {padding: 0px 0px 0px 60px; orientation: horizontal; children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5; width: 50px;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme ${dir}/${theme}.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--hibernate' ]]; then
			systemctl hibernate
		elif [[ $1 == '--suspend' ]]; then
            mpc -q pause
            amixer set Master mute
            systemctl suspend
            swaylock
		elif [[ $1 == '--logout' ]]; then
            run_logout
		fi
	else
		exit 0
	fi
}

run_logout() {
    hyprctl dispatch exit
    i3-msg exit	
    bspc quit
}
run_logout_true() {
    if [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
        openbox --exit
    elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
        bspc quit
    elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
        i3-msg exit	
    elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
        qdbus org.kde.ksmserver /KSMServer logout 0 0 0
    elif [[ "$DESKTOP_SESSION" == 'hyprland' ]]; then
		hyprctl dispatch exit
    fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $hibernate)
		run_cmd --hibernate
        ;;
    $lock)
        swaylock
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac
