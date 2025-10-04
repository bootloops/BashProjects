#!/bin/bash
# cpu_temp.sh
# Outputs CPU temperature in °C

# Works for Linux with /sys/class/thermal/thermal_zone*/temp
# Adjust thermal_zone0 if necessary
temp_file="/sys/class/thermal/thermal_zone0/temp"

if [ -f "$temp_file" ]; then
    temp=$(cat $temp_file)
    temp_c=$(echo "scale=1; $temp / 1000" | bc)
    echo "🌡 $temp_c°C"
else
    echo "🌡 N/A"
fi
