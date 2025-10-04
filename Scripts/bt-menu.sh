#!/bin/bash
# Rofi-based Bluetooth control with Scan Menu

scan_menu() {
    # Run scan in background for 10 seconds
    bluetoothctl scan on >/dev/null &
    SCAN_PID=$!
    notify-send "Bluetooth" "Scanning for devices"
    sleep 10
    kill $SCAN_PID
    bluetoothctl scan off >/dev/null

    # Get discovered devices (including unpaired)
    DEVICES=$(bluetoothctl devices | awk '{print $2 " " substr($0,index($0,$3))}')
    [[ -z "$DEVICES" ]] && notify-send "Bluetooth Scan" "No devices found" && exit 0

    # Show scan results in rofi
    SELECTED=$(echo "$DEVICES" | rofi -dmenu -p "Discovered Devices:")
    [[ -z "$SELECTED" ]] && exit 0

    DEVICE_MAC=$(echo "$SELECTED" | awk '{print $1}')

    # Ask action: Pair/Connect
    ACTION=$(printf "Connect\nPair\nInfo" | rofi -dmenu -p "$SELECTED")
    case "$ACTION" in
        Connect)
            OUTPUT=$(bluetoothctl connect "$DEVICE_MAC" 2>&1)
            notify-send "Bluetooth: Connect" "$OUTPUT"
            ;;
        Pair)
            OUTPUT=$(bluetoothctl pair "$DEVICE_MAC" 2>&1)
            notify-send "Bluetooth: Pair" "$OUTPUT"
            ;;
        Info)
            INFO=$(bluetoothctl info "$DEVICE_MAC" 2>&1)
            rofi -e "$INFO"
            ;;
    esac
}

# ======================== MAIN MENU ========================
DEVICES=$(bluetoothctl devices | awk '{print $2 " " substr($0,index($0,$3))}')
SELECTED=$(echo -e "Controller Options\nScan for Devices\n$DEVICES" | rofi -dmenu -p "Bluetooth:")
[[ -z "$SELECTED" ]] && exit 0

# ======================== CONTROLLER OPTIONS ========================
if [[ "$SELECTED" == "Controller Options" ]]; then
    ACTION=$(cat <<EOF | rofi -dmenu -p "Controller Action:"
power on
power off
pairable on
pairable off
discoverable on
discoverable off
scan on
scan off
devices
list
show
quit
EOF
)
    [[ -z "$ACTION" ]] && exit 0
    OUTPUT=$(bluetoothctl $ACTION 2>&1)
    notify-send "Bluetooth: $ACTION" "$OUTPUT"
    exit 0
fi

# ======================== SCAN MENU ========================
if [[ "$SELECTED" == "Scan for Devices" ]]; then
    scan_menu
    exit 0
fi

# ======================== PER-DEVICE ACTIONS ========================
DEVICE_MAC=$(echo "$SELECTED" | awk '{print $1}')

if bluetoothctl info "$DEVICE_MAC" | grep -q "Connected: yes"; then
    ACTION=$(cat <<EOF | rofi -dmenu -p "$SELECTED"
Disconnect
Info
Trust
Untrust
Remove
Block
Unblock
EOF
)
else
    ACTION=$(cat <<EOF | rofi -dmenu -p "$SELECTED"
Connect
Info
Pair
Trust
Remove
EOF
)
fi

case "$ACTION" in
    Connect)
        OUTPUT=$(bluetoothctl connect "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Connect" "$OUTPUT"
        ;;
    Disconnect)
        OUTPUT=$(bluetoothctl disconnect "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Disconnect" "$OUTPUT"
        ;;
    Pair)
        OUTPUT=$(bluetoothctl pair "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Pair" "$OUTPUT"
        ;;
    Trust)
        OUTPUT=$(bluetoothctl trust "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Trust" "$OUTPUT"
        ;;
    Untrust)
        OUTPUT=$(bluetoothctl untrust "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Untrust" "$OUTPUT"
        ;;
    Remove)
        OUTPUT=$(bluetoothctl remove "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Remove" "$OUTPUT"
        ;;
    Block)
        OUTPUT=$(bluetoothctl block "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Block" "$OUTPUT"
        ;;
    Unblock)
        OUTPUT=$(bluetoothctl unblock "$DEVICE_MAC" 2>&1)
        notify-send "Bluetooth: Unblock" "$OUTPUT"
        ;;
    Info)
        INFO=$(bluetoothctl info "$DEVICE_MAC" 2>&1)
        rofi -e "$INFO"
        ;;
esac
