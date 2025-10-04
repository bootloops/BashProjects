#!/bin/bash
# net_speed.sh
# Outputs upload/download speed for a specific interface

IFACE="enp3s0"  # change to your interface (check with `ip a`)
RX_PREV=0
TX_PREV=0

while true; do
    RX_NOW=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX_NOW=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

    RX_SPEED=$(( (RX_NOW - RX_PREV) / 1024 ))
    TX_SPEED=$(( (TX_NOW - TX_PREV) / 1024 ))

    RX_PREV=$RX_NOW
    TX_PREV=$TX_NOW

    echo "⬇ ${RX_SPEED}KB/s ⬆ ${TX_SPEED}KB/s"
    sleep 1
done
