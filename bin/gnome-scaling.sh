#!/bin/bash
set -ex
case $1 in
  "")
    dconf read /org/gnome/desktop/interface/scaling-factor
    dconf read /org/gnome/desktop/interface/text-scaling-factor
    dconf read /org/gnome/settings-daemon/plugins/xsettings/overrides;;
  1)
    dconf write /org/gnome/desktop/interface/scaling-factor 'uint32 1'
    dconf reset /org/gnome/settings-daemon/plugins/xsettings/overrides;;
  1.*)
    dconf write /org/gnome/desktop/interface/scaling-factor 'uint32 1'
    dconf write /org/gnome/desktop/interface/text-scaling-factor $1
    dconf reset /org/gnome/settings-daemon/plugins/xsettings/overrides;;
  2)
    dconf write /org/gnome/desktop/interface/scaling-factor 'uint32 2'
    dconf reset /org/gnome/desktop/interface/text-scaling-factor
    dconf write /org/gnome/settings-daemon/plugins/xsettings/overrides "[{'Gdk/WindowScalingFactor', <2>}]";;
  *)
    echo "Unknown scaling factor $1"
    exit 1
esac
