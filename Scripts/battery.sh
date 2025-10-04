#!/bin/bash
# battery.sh
# Outputs battery percentage and charging status

BAT_PATH="/sys/class/power_supply/BAT0"

if [ -d "$BAT_PATH" ]; then
    CAPACITY=$(cat $BAT_PATH/capacity)
    STATUS=$(cat $BAT_PATH/status)
    if [ "$STATUS" = "Charging" ]; then
        ICON="⚡"
    else
        ICON="🔋"
    fi
    echo "$ICON $CAPACITY%"
else
    echo "🔋 N/A"
fi
