#!/bin/bash
# polybar-bluetooth-status.sh
connected=$(bluetoothctl info | grep "Connected: yes")
device=$(bluetoothctl info | grep "Name" | awk -F':' '{print $2}')


if [[ -n "$connected" ]]; then
    echo " $device"   # Connected icon
else
    echo ""          # Disconnected icon
fi
