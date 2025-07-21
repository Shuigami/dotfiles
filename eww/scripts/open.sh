popup="$(eww get popup)"
echo $popup

if [ "$popup" = "true" ]; then
  echo "popup is true"
  eww update popup=false && sleep 0 && eww close popup-window
else
  echo "popup is false"
  eww open popup-window && sleep 0 && eww update popup=true
fi
