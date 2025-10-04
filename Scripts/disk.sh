#!/bin/bash
# disk.sh
# Outputs root partition usage

USAGE=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
echo "💽 $USAGE"
