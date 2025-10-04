#!/bin/bash
DEVICE="/sys/class/backlight/intel_backlight"
BRIGHTNESS="$DEVICE/brightness"
MAX="$DEVICE/max_brightness"

b=$(cat "$BRIGHTNESS")
max=$(cat "$MAX")

# Action
case "$1" in
  set)
    n=$2
    [[ -z $n ]] && n=$b
    [[ $n -gt $max ]] && n=$max
    [[ $n -lt 0 ]] && n=0
    echo $n | sudo tee "$BRIGHTNESS" > /dev/null
    ;;
  +)
    new=$((b + max/10))
    [[ $new -gt $max ]] && new=$max
    echo $new | sudo tee "$BRIGHTNESS" > /dev/null
    ;;
  -)
    new=$((b - max/10))
    [[ $new -lt 0 ]] && new=0
    echo $new | sudo tee "$BRIGHTNESS" > /dev/null
    ;;
  *)
    ;;
esac

# Recalculate after action
x=$(cat "$BRIGHTNESS")
perc=$((x*100/max))

# Icon set
iset=( "🌑" "🌒" "🌓" "🌔" "🌕" )
if   [ "$perc" -le 10 ]; then icon="${iset[0]}"
elif [ "$perc" -le 40 ]; then icon="${iset[1]}"
elif [ "$perc" -le 70 ]; then icon="${iset[2]}"
elif [ "$perc" -le 90 ]; then icon="${iset[3]}"
else icon="${iset[4]}"; fi

# Show icon and percentage
echo "$icon $perc%"
