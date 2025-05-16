#!/bin/bash
set -e -o pipefail

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

if [[ $UID == 0 ]]; then
  # Doesn't normally make sense to run GUI setup under root.
  # Check if we can infer target user from script's path and if so, run under it.
  SCRIPT_USER=$(stat -c %U "$SCRIPT_PATH")
  if [[ "$SCRIPT_PATH" == "/home/$SCRIPT_USER/"* ]]; then
    echo "Will run GUI setup under $SCRIPT_USER"
    (set -x; sudo -u "$SCRIPT_USER" "$SCRIPT_PATH")
    exit $?
  fi
  echo "Refusing to run under root"
  exit 1
fi

cd "$SCRIPT_DIR"


# Bookmarks and home subdirs/symlinks

mkdir -p ~/.config/gtk-3.0

# Remove empty dirs and broken symlinks
for name in Music Pictures Public Templates Videos; do
  dir="$HOME/$name"
  if [[ -d "$dir" && ! -L "$dir" ]]; then
    rmdir "$dir" >/dev/null 2>&1 || true
  fi
  if [[ -L "$dir" && ! -d "$dir" ]]; then
    rm -f "$dir" || true
  fi
  if ! [[ -d "$dir" ]] && egrep -q "/$name\\b" ~/.config/gtk-3.0/bookmarks >/dev/null 2>&1; then
    sed -i -E -e "/\\/$name\\b/d" ~/.config/gtk-3.0/bookmarks
  fi
done

# ~/share -> /mnt/share, etc
# ~/Downloads -> /mnt/share/Downloads, etc
for name in share Documents Downloads Music Videos; do
  dir="/mnt/${name,}"  # lowercased
  lnk="$HOME/$name"
  if [[ -d "$dir" && ! -d "$lnk" ]] && mountpoint -q "$dir"; then
    rmdir "$lnk" >/dev/null 2>&1 || true
    if [[ -L "$lnk" ]]; then
      rm -f "$lnk" || true
    fi
    if ! [[ -e "$lnk" ]]; then
      ln -s "$dir" "$lnk"
    fi
  fi

  dir="$HOME/share/$name"
  lnk="$HOME/$name"
  if [[ -d "$dir" && ! "$dir" -ef "$lnk" ]]; then
    rmdir "$lnk" >/dev/null 2>&1 || true
    if [[ -L "$lnk" ]]; then
      rm -f "$lnk" || true
    fi
    if ! [[ -e "$lnk" ]]; then
      ln -s "share/$name" "$lnk"
    fi
  fi
done

for dir in ~/Documents ~/Downloads ~/Music ~/Videos ~/share; do
  name=$(basename "$dir")
  if [[ -d "$dir" ]] && ! fgrep -x "file://$dir $name" ~/.config/gtk-3.0/bookmarks >/dev/null 2>&1; then
    mkdir -p ~/.config/gtk-3.0
    touch ~/.config/gtk-3.0/bookmarks
    sed -i -E -e "/\\/$name\\b/d" ~/.config/gtk-3.0/bookmarks
    echo "file://$dir $name" >>~/.config/gtk-3.0/bookmarks
  fi
done

echo en_US >~/.config/user-dirs.locale
if [[ -f ~/.config/user-dirs.dirs ]]; then
  sed -i -e 's|XDG_DOWNLOAD_DIR=.*|XDG_DOWNLOAD_DIR="$HOME/Downloads"|' ~/.config/user-dirs.dirs
  if [[ -d ~/Music ]]; then
    sed -i -e 's|XDG_MUSIC_DIR=.*|XDG_MUSIC_DIR="$HOME/Music"|' ~/.config/user-dirs.dirs
  fi
  if [[ -d ~/Videos ]]; then
    sed -i -e 's|XDG_VIDEOS_DIR=.*|XDG_VIDEOS_DIR="$HOME/Videos"|' ~/.config/user-dirs.dirs
  fi
  if [[ -d ~/share ]]; then
    sed -i -e 's|XDG_PUBLICSHARE_DIR=.*|XDG_PUBLICSHARE_DIR="$HOME/share"|' ~/.config/user-dirs.dirs
  fi
fi


# DBUS settings

if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
  # Start dbus daemon if not running inside an existing GUI session
  export $(dbus-launch)
fi

cat dconf.json | ../bin/json2dconf | dconf load /
cat dconf-panels.json | ../bin/json2dconf | dconf load /
cat dconf-terminal.json | ../bin/json2dconf | dconf load /

for theme in Yaru Adwaita; do
  if [[ -d "/usr/share/themes/$theme" ]]; then
    dconf write /org/cinnamon/desktop/interface/gtk-theme "'$theme'"
    dconf write /org/gnome/desktop/interface/gtk-theme "'$theme'"
    dconf write /org/mate/desktop/interface/gtk-theme "'$theme'"
    break
  fi
done

for theme in Humanity suru gnome-human Adwaita Moka; do
  if [[ -d "/usr/share/icons/$theme" ]]; then
    dconf write /org/cinnamon/desktop/interface/icon-theme "'$theme'"
    dconf write /org/gnome/desktop/interface/icon-theme "'$theme'"
    dconf write /org/mate/desktop/interface/icon-theme "'$theme'"
    break
  fi
done

interface_font="Noto Sans 9"
dconf write /org/cinnamon/desktop/interface/font-name "'$interface_font'"
dconf write /org/gnome/desktop/interface/font-name "'$interface_font'"
dconf write /org/mate/desktop/interface/font-name "'$interface_font'"

doc_font="Noto Sans 11"
dconf write /org/gnome/desktop/interface/document-font-name "'$doc_font'"
dconf write /org/mate/desktop/interface/document-font-name "'$doc_font'"

desktop_font="Noto Sans 11"
dconf write /org/nemo/desktop/font "'$desktop_font'"
dconf write /org/mate/caja/desktop/font "'$desktop_font'"

if [[ -d /usr/share/fonts/truetype/roboto ]]; then
  titlebar_font="Roboto Medium 11"
  dconf write /org/cinnamon/desktop/wm/preferences/titlebar-font "'$titlebar_font'"
  dconf write /org/gnome/desktop/wm/preferences/titlebar-font "'$titlebar_font'"
  dconf write /org/mate/marco/general/titlebar-font "'$titlebar_font'"
fi

if [[ -d /usr/share/fonts/truetype/iosevka ]]; then
  mono_font="Iosevka Medium 12"
  dconf write /org/gnome/desktop/interface/monospace-font-name "'$mono_font'"
  dconf write /org/mate/desktop/interface/monospace-font-name "'$mono_font'"
fi

#  "org/cinnamon/desktop/keybindings/custom-list": "['custom0']",
#  "org/cinnamon/desktop/keybindings/custom-keybindings/custom0/binding": "['Print']",
#  "org/cinnamon/desktop/keybindings/custom-keybindings/custom0/command": "'scrot'",
#  "org/cinnamon/desktop/keybindings/custom-keybindings/custom0/name": "'scrot'",
#  "org/cinnamon/desktop/background/picture-options": "'zoom'",
#  "org/cinnamon/desktop/background/picture-uri": "'file:///usr/share/desktop-base/emerald-theme/wallpaper/gnome-background.xml'",
#  "org/cinnamon/desktop/background/slideshow/delay": "15",
#  "org/cinnamon/desktop/background/slideshow/image-source": "'xml:///usr/share/gnome-background-properties/pixels.xml'",
#  "org/gnome/desktop/background/color-shading-type": "'solid'",
#  "org/gnome/desktop/background/picture-options": "'zoom'",
#  "org/gnome/desktop/background/picture-uri": "'file:///usr/share/backgrounds/gnome/dune-l.svg'",
#  "org/gnome/desktop/background/picture-uri-dark": "'file:///usr/share/backgrounds/gnome/dune-d.svg'",
#  "org/gnome/desktop/background/primary-color": "'#f7a957'",
#  "org/gnome/desktop/background/secondary-color": "'#000000'",
#  "org/mate/desktop/background/color-shading-type": "'vertical-gradient'",
#  "org/mate/desktop/background/picture-filename": "'/usr/share/backgrounds/mate/nature/FreshFlower.jpg'",
#  "org/mate/desktop/background/picture-options": "'zoom'",
#  "org/mate/desktop/background/primary-color": "'rgb(88,145,188)'",
#  "org/mate/desktop/background/secondary-color": "'rgb(60,143,37)'",

virt="$(systemd-detect-virt || true)"
if ! systemd-detect-virt -q || [[ "$virt" == "" ]]; then
  virt="none"
fi

if [[ "$virt" == "apple" ]]; then  # Apple's Virtualizaton Framework
  dconf write /org/cinnamon/desktop/peripherals/mouse/natural-scroll true
  dconf write /org/gnome/desktop/peripherals/mouse/natural-scroll true
else
  dconf write /org/cinnamon/desktop/peripherals/mouse/natural-scroll false
  dconf write /org/gnome/desktop/peripherals/mouse/natural-scroll false
fi

if [[ "$virt" == "none" ]]; then
  # Turn off the screen when inactive for: 30 min
  dconf write /org/cinnamon/settings-daemon/plugins/power/sleep-display-ac 1800
  dconf write /org/mate/power-manager/sleep-display-ac 1800
  # Time before session is considered idle (starting screensaver / blank screen): 15 min
  dconf write /org/cinnamon/desktop/session/idle-delay '"uint32 900"'
  dconf write /org/gnome/desktop/session/idle-delay '"uint32 900"'
  dconf write /org/mate/desktop/session/idle-delay 15  # in minutes
  dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout 7200
  dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type "'blank'"
  #dconf write /org/mate/power-manager/sleep-computer-ac 1200
fi

# Cinnamon applets' configs
if [[ -x /usr/bin/cinnamon-session ]]; then
  # System Monitor by orcuscz
  # https://cinnamon-spices.linuxmint.com/applets/view/88
  # https://github.com/linuxmint/cinnamon-spices-applets/tree/master/sysmonitor%40orcus
  if ! [[ sysmonitor@orcus -ef ~/.local/share/cinnamon/applets/sysmonitor@orcus ]]; then
    rm -rf ~/.local/share/cinnamon/applets/sysmonitor@orcus
    mkdir -p ~/.local/share/cinnamon/applets
    ln -sfT ../../../../.dotfiles/gui/sysmonitor@orcus ~/.local/share/cinnamon/applets/sysmonitor@orcus
  fi

  # Configs for cinnamon applets
  # <n>.json must match trailing numbers in org/cinnamon/enabled-applets
  mkdir -p ~/.config/cinnamon/spices
  cp -r config-cinnamon-spices/* ~/.config/cinnamon/spices/
fi


filter_apps() {
  for app in $*; do
    if [[ -f "/usr/share/applications/$app" || -x "/usr/bin/${app/.desktop}" ]]; then
      echo "$app"
    elif [[ "$app" == nemo.desktop && -x /usr/bin/nautilus ]]; then
      echo org.gnome.Nautilus.desktop
    elif [[ "$app" == firefox-bwrap.desktop && -f /usr/share/applications/firefox.desktop ]]; then
      echo firefox.desktop
    elif [[ "$app" == firefox-bwrap.desktop && -f /usr/share/applications/firefox-esr.desktop ]]; then
      echo firefox-esr.desktop
    elif [[ "$app" == google-chrome.desktop && -x /usr/bin/chromium ]]; then
      echo chromium.desktop
    fi
  done
}

# Launchers in cinnamon's main menu
dconf write /org/cinnamon/favorite-apps \
  "$(filter_apps \
       google-chrome.desktop \
       firefox-bwrap.desktop \
       org.gnome.Terminal.desktop \
       nemo.desktop \
     | tr '\n' ' ' | sed -e "s/ $/']/; s/^/['/; s/ /', '/g")"

# Gnome dash pinned apps
dconf write /org/gnome/shell/favorite-apps \
  "$(filter_apps \
       google-chrome.desktop \
       chromium.desktop \
       firefox-bwrap.desktop \
       firefox-esr.desktop \
       org.gnome.Terminal.desktop \
       nemo.desktop \
     | tr '\n' ' ' | sed -e "s/ $/']/; s/^/['/; s/ /', '/g")"

# Desktop icons
mkdir -p ~/Desktop
for x in $(filter_apps \
       google-chrome.desktop \
       chromium.desktop \
       firefox-bwrap.desktop \
       firefox-esr.desktop \
       org.gnome.Terminal.desktop \
     ); do
  if ! [[ -f ~/Desktop/"$x" && -f /usr/share/applications/"$x" ]]; then
    cp /usr/share/applications/"$x" ~/Desktop/"$x"
    # Mark as trusted
    chmod a+x ~/Desktop/"$x"
    gio set ~/Desktop/"$x" metadata::trusted true || true
  fi
  if [[ -f ~/Desktop/"$x" ]]; then
    sed -i -e 's/Name=Chromium Web Browser/Name=Chromium/' ~/Desktop/"$x"
  fi
done

# Autostart
if [[ -f /usr/share/applications/guake.desktop && ! -f ~/.config/autostart/guake.desktop ]]; then
  mkdir -p ~/.config/autostart
  cp -af /usr/share/applications/guake.desktop ~/.config/autostart/guake.desktop
fi

# TODO cinnamon/flashback panel lauchers
# TODO default apps ~/.config/mimelist

rm -f ~/.face ~/.face.icon
echo yes >~/.config/gnome-initial-setup-done
if [[ -x /usr/bin/gnome-terminal ]]; then
  echo org.gnome.Terminal.desktop >~/.config/X-Cinnamon-xdg-terminals.list
  echo org.gnome.Terminal.desktop >~/.config/xdg-terminals.list
fi
