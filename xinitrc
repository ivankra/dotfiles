#!/bin/bash
setxkbmap -option compose:caps
if [ -d /sys/devices/platform/applesmc.768 ]; then
  ~/src/configs/bin/keyboard-backlight 0
fi
