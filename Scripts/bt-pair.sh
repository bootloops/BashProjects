#!/bin/bash
# bt-pair.sh — connect/disconnect Bluetooth devices via rofi

# Get list of devices (MAC and Name)
DEVICES=$(bluetoothctl devices | awk '{print $2 " " substr($0,index($0,$3))}')

CONNECTED_ITEMS=""
DISCONNECTED_ITEMS=""

# Annotate and separate connected vs disconnected devices
while IFS= read -r line; do
    MAC=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{ $1=""; print substr($0,2) }')

    if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
        CONNECTED_ITEMS+="$MAC $NAME [connected]"$'\n'
    else
        DISCONNECTED_ITEMS+="$MAC $NAME"$'\n'
    fi
done <<< "$DEVICES"

# Merge lists so connected devices are shown first
MENU_ITEMS="$CONNECTED_ITEMS$DISCONNECTED_ITEMS"

# Show menu via rofi
SELECTED=$(echo -e "$MENU_ITEMS" | rofi -dmenu -p "Toggle Bluetooth:")
[[ -z "$SELECTED" ]] && exit 0

# Extract MAC from selected line
MAC_SELECTED=$(echo "$SELECTED" | awk '{print $1}')

# Toggle connection
if bluetoothctl info "$MAC_SELECTED" | grep -q "Connected: yes"; then
    echo "Disconnecting $MAC_SELECTED..."
    bluetoothctl disconnect "$MAC_SELECTED"
else
    echo "Connecting $MAC_SELECTED..."
    bluetoothctl connect "$MAC_SELECTED"
fi
