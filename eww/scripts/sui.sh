choice=$1

if [ -z "$choice" ]; then
  read -p "Continue (y/n)?" choice
fi

case "$choice" in
  y|Y ) eww close popup-upgrade && alacritty -e bash -c 'sudo pacman -Syu --noconfirm && yay -Syu --noconfirm && sleep 5';;
  * ) eww close popup-upgrade;;
esac
