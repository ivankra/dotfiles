#!/bin/bash
# Usage: setup.sh [--dark|--light] [--hi-dpi|--low-dpi]
# Defaults to a light theme on a hi-dpi display

# Initialization and flags {{{
set -e -o pipefail

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

HIDPI=${HIDPI:-}
DARK_THEME=${DARK_THEME:-}

while [[ $# -gt 0 ]]; do
  key="$1"
  case "$1" in
    --hi-dpi)  HIDPI=1;;
    --low-dpi) HIDPI=0;;
    --dark)    DARK_THEME=1;;
    --light)   DARK_THEME=0;;
    *)         echo "Unknown parameter: $1"; exit 1;;
  esac
  shift
done

if [[ $UID == 0 ]]; then
  # Doesn't normally make sense to run GUI setup under root.
  # Check if we can infer target user from script's path and if so, run under it.
  SCRIPT_USER=$(stat -c %U "$SCRIPT_PATH")
  if [[ "$SCRIPT_PATH" == "/home/$SCRIPT_USER/"* ]]; then
    (set -x; sudo -u "$SCRIPT_USER" --preserve-env=HIDPI,DARK_THEME "$SCRIPT_PATH" "$@")
    exit $?
  fi
  echo "Refusing to run under root" 2>&1
  exit 1
fi

cd "$SCRIPT_DIR"
mkdir -p ~/.config
# }}}
# Helpers {{{

# Prints the full path of an installed .desktop file, if any
desktop_file() {
  local dir
  for dir in "$HOME/.local/share/applications" /usr/local/share/applications /usr/share/applications; do
    if [[ -f "$dir/$1" ]]; then
      echo "$dir/$1"
      return 0
    fi
  done
  return 1
}

# Prints the installed apps among its arguments, dropping the rest. An argument
# may list fallbacks separated by "|", of which only the first installed one is
# printed, e.g. 'google-chrome.desktop|chromium.desktop'
filter_apps() {
  local arg app
  for arg in "$@"; do
    for app in ${arg//|/ }; do
      if desktop_file "$app" >/dev/null || [[ -x "/usr/bin/${app/.desktop}" ]]; then
        echo "$app"
        break
      fi
    done
  done
}

# Prints the first value of a key in a section of an ini-like file (a .desktop
# file, mimeapps.list, ...), if any
# Usage: ini_get <file> <section> <key>
ini_get() {
  local out
  out=$(sed -n -e "/^\[$2\]/,/^\[/ { s|^$3=||p }" "$1" 2>/dev/null) || true
  echo "${out%%$'\n'*}"
}

# Prints the elements of a dconf array of strings, one per line
dconf_list() {
  dconf read "$1" | tr -d "[]'" | tr ',' '\n' | sed -e 's/^ *//; s/ *$//' | grep -v '^$' || true
}

# Formats its input lines as a dconf array of strings
dconf_array() {
  local line out=''
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      out+="${out:+, }'$line'"
    fi
  done
  if [[ -z "$out" ]]; then
    # dconf has no schemas to go by and can't infer the type of a bare []
    echo '@as []'
  else
    echo "[$out]"
  fi
}

# }}}
# Bookmarks and home subdirs/symlinks {{{

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

# }}}
# dconf {{{

if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
  # Start dbus daemon if not running inside an existing GUI session
  export $(dbus-launch)
fi

cat dconf.json | bin/json2dconf | dconf load /
cat dconf-terminal.json | bin/json2dconf | dconf load /

for theme in Yaru Adwaita; do
  if [[ -d "/usr/share/themes/$theme" ]]; then
    if [[ "$DARK_THEME" == 1 ]]; then
      theme+="-dark"
    fi
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

if [[ "$DARK_THEME" == 1 ]]; then
  dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
  dconf write /org/x/apps/portal/color-scheme "'prefer-dark'"
else
  dconf write /org/gnome/desktop/interface/color-scheme "'default'"
  dconf write /org/x/apps/portal/color-scheme "'default'"
fi

interface_font="Noto Sans 9"
doc_font="Noto Sans 11"
desktop_font="Noto Sans 11"

if [[ "$HIDPI" == "0" ]]; then
  dconf write /org/cinnamon/desktop/interface/scaling-factor 'uint32 1'
  dconf write /org/gnome/desktop/interface/scaling-factor 'uint32 1'
  dconf write /org/gnome/desktop/interface/text-scaling-factor 1.15
  dconf write /org/mate/desktop/interface/window-scaling-factor 1
  dconf write /org/gnome/gnome-panel/layout/toplevels/top-panel/size 32
  interface_font="Noto Sans 11"
else
  dconf write /org/cinnamon/desktop/interface/scaling-factor 'uint32 2'
  dconf write /org/gnome/desktop/interface/scaling-factor 'uint32 2'
  dconf write /org/gnome/desktop/interface/text-scaling-factor 1.0
  dconf write /org/mate/desktop/interface/window-scaling-factor 2
  # The panel scales with the display here, so it keeps the size dconf.json
  # gives it; only the low-dpi branch above has to bump it
fi

dconf write /org/cinnamon/desktop/interface/font-name "'$interface_font'"
dconf write /org/gnome/desktop/interface/font-name "'$interface_font'"
dconf write /org/mate/desktop/interface/font-name "'$interface_font'"

dconf write /org/gnome/desktop/interface/document-font-name "'$doc_font'"
dconf write /org/mate/desktop/interface/document-font-name "'$doc_font'"

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
  dconf write /org/cinnamon/desktop/session/idle-delay 'uint32 900'
  dconf write /org/gnome/desktop/session/idle-delay 'uint32 900'
  dconf write /org/mate/desktop/session/idle-delay 15  # in minutes

  dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout 7200
  dconf write /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type "'blank'"
  #dconf write /org/mate/power-manager/sleep-computer-ac 1200

  # multiload (a load graph) is pointless in a VM. The launcher objects are
  # appended to this list by the panel launchers section further down
  dconf write /org/gnome/gnome-panel/layout/object-id-list "['menu-bar', 'notification-area', 'system-indicators', 'clock', 'user-menu', 'window-list', 'multiload', 'workspace-switcher']"
fi

# }}}
# Default apps {{{

python3 ./mimeapps.py

# }}}
# Preferred terminal app {{{

# Get whatever mimeapps.py just made the default for the (non-standard)
# x-scheme-handler/terminal, and the command out of its .desktop file
terminal_desktop=$(ini_get ~/.config/mimeapps.list 'Default Applications' x-scheme-handler/terminal)
terminal_desktop="${terminal_desktop%%;*}"
terminal_exec=

if [[ -n "$terminal_desktop" ]] && terminal_path=$(desktop_file "$terminal_desktop"); then
  terminal_exec=$(ini_get "$terminal_path" 'Desktop Entry' Exec)
  terminal_exec="${terminal_exec// %[a-zA-Z]/}"  # drop the %u/%F field codes
  if [[ "$terminal_desktop" == *Ptyxis.desktop ]]; then
    terminal_exec+=" --new-window"
  fi
else
  terminal_desktop=
fi

if [[ -n "$terminal_exec" ]]; then
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings \
    "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Control><Alt>t'"
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'$terminal_exec'"
  dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'$terminal_exec'"

  dconf write /org/cinnamon/desktop/applications/terminal/exec "'$terminal_exec'"
  dconf write /org/mate/desktop/applications/terminal/exec "'$terminal_exec'"
fi

if [[ -n "$terminal_desktop" ]]; then
  echo "$terminal_desktop" >~/.config/xdg-terminals.list
fi
rm -f ~/.config/X-Cinnamon-xdg-terminals.list

# }}}
# Panel launchers and applets {{{

# Link cinnamon applets into ~/.local/share/cinnamon/applets,
# install their configs, reload applets if needed.
if [[ -x /usr/bin/cinnamon-session ]]; then
  ./cinnamon/install.sh
fi

# The apps to put everywhere, in order. Same "|" fallbacks as filter_apps
launcher_apps=(
  'google-chrome.desktop|chromium.desktop'
  'firefox-bwrap.desktop|firefox.desktop|firefox-esr.desktop'
  "$terminal_desktop|org.gnome.Terminal.desktop"
  'nemo.desktop|org.gnome.Nautilus.desktop'
)
# Added to those on a panel, which has room for more than a handful of icons
extra_apps=(
  virt-manager.desktop
  org.keepassxc.KeePassXC.desktop
)
# Usage: merge_panel_launchers <desktop-env> [<.desktop already on the panel>...]
# Prints one .desktop name per line: the installed launcher_apps first, then
# whatever else is on the panel already, i.e. what the user put there by hand.
# Arguments may be paths, only their basename is printed.
merge_panel_launchers() {
  local de="$1"; shift
  local apps=("${launcher_apps[@]}")
  case "$de" in
    # Panel launchers, and gnome's dash, which is the same thing
    cinnamon|flashback|gnome) apps+=("${extra_apps[@]}");;
    # Favorites in cinnamon's main menu, which only shows a few before it
    # starts scrolling. Every app is a search away there anyway
    cinnamon-menu) ;;
    *) echo "merge_panel_launchers: unknown desktop environment: $de" >&2; return 1;;
  esac

  local -A known=() printed=()
  local entry app desktops
  # The alternatives of an entry count as known even when we didn't pick them,
  # so that a chromium the user pinned doesn't sit next to the chrome we chose
  for entry in "${apps[@]}"; do
    for app in ${entry//|/ }; do
      known[$app]=1
    done
  done

  while read -r app; do
    if [[ -n "$app" && -z "${printed[$app]:-}" ]]; then
      printed[$app]=1
      echo "$app"
    fi
  done < <(filter_apps "${apps[@]}")

  for app in "$@"; do
    app="${app##*/}"
    if [[ -n "$app" && -z "${known[$app]:-}" && -z "${printed[$app]:-}" ]]; then
      printed[$app]=1
      echo "$app"
    fi
  done
}

# Launchers in cinnamon's main menu. An empty list means nothing we know of is
# installed and the menu had no favorites of its own, so leave it be
mapfile -t cinnamon_favorites < <(dconf_list /org/cinnamon/favorite-apps)
mapfile -t cinnamon_favorites < <(merge_panel_launchers cinnamon-menu "${cinnamon_favorites[@]}")
if [[ ${#cinnamon_favorites[@]} -gt 0 ]]; then
  dconf write /org/cinnamon/favorite-apps \
    "$(printf '%s\n' "${cinnamon_favorites[@]}" | dconf_array)"
fi

# Gnome dash pinned apps
mapfile -t gnome_favorites < <(dconf_list /org/gnome/shell/favorite-apps)
mapfile -t gnome_favorites < <(merge_panel_launchers gnome "${gnome_favorites[@]}")
if [[ ${#gnome_favorites[@]} -gt 0 ]]; then
  dconf write /org/gnome/shell/favorite-apps \
    "$(printf '%s\n' "${gnome_favorites[@]}" | dconf_array)"
fi

# Rewrites the launcher objects on the gnome-flashback panel from scratch,
# leaving every other object on it alone
write_flashback_launchers() {
  local path=/org/gnome/gnome-panel/layout
  local obj entry location app app_path launcher n=0 id=0
  local objects=() found=() locations=() old_ids=()
  local -A paths=() custom=() written=()

  # Objects other than the launchers, in the order the panel has them
  for obj in $(dconf_list "$path/object-id-list"); do
    if [[ "$obj" != launcher && "$obj" != launcher-* ]]; then
      objects+=("$obj")
    fi
  done

  # The launchers currently on the panel. They are looked up in dconf rather
  # than in object-id-list above because dconf.json has just dropped
  # them from it, and gnome-panel names them launcher-<n> whether they came
  # from here or from the user, so there is no telling the two apart anyway
  # pack-index leads so that sort puts them in panel order
  mapfile -t found < <(
    for obj in $(dconf list "$path/objects/" | tr -d /); do
      if [[ "$(dconf read "$path/objects/$obj/object-iid")" == *launcher* ]]; then
        location=$(dconf read "$path/objects/$obj/instance-config/location" | tr -d "'")
        echo "$(dconf read "$path/objects/$obj/pack-index")|$obj|$location"
      fi
    done | sort -t'|' -k1,1n -k2,2)

  for entry in "${found[@]}"; do
    IFS='|' read -r _ obj location <<<"$entry"
    if [[ -z "$location" ]]; then
      # A launcher without one is a custom launcher (its own command and icon),
      # which we know nothing about: keep it, and keep off its object id
      objects+=("$obj")
      custom[$obj]=1
      continue
    fi
    locations+=("$location")
    old_ids+=("$obj")
    paths["${location##*/}"]="$location"
  done

  for app in $(merge_panel_launchers flashback "${locations[@]}"); do
    # For a launcher that was on the panel already keep the path it points at:
    # it may live somewhere desktop_file doesn't look, e.g. a flatpak export
    app_path=$(desktop_file "$app") || app_path="${paths[$app]:-}"
    if [[ ! -f "$app_path" ]]; then
      continue
    fi
    n=$((n+1))
    # The first launcher is plain "launcher", the rest are launcher-<n>
    while :; do
      if [[ "$((++id))" == "1" ]]; then
        launcher="launcher"
      else
        launcher="launcher-$((id-2))"
      fi
      if [[ -z "${custom[$launcher]:-}" ]]; then
        break
      fi
    done
    dconf write "$path/objects/$launcher/instance-config/location" "'$app_path'"
    dconf write "$path/objects/$launcher/object-iid" "'org.gnome.gnome-panel.launcher::launcher'"
    dconf write "$path/objects/$launcher/pack-index" "$n"
    dconf write "$path/objects/$launcher/pack-type" "'start'"
    dconf write "$path/objects/$launcher/toplevel-id" "'top-panel'"
    written[$launcher]=1
    objects+=("$launcher")
  done

  # Whatever the merged list didn't reuse holds a duplicate of a launcher we
  # just wrote, so drop it rather than leave it for the next run to pick up
  for obj in "${old_ids[@]}"; do
    if [[ -z "${written[$obj]:-}" ]]; then
      dconf reset -f "$path/objects/$obj/"
    fi
  done

  # Not something that happens on a panel that has a menu and a clock on it,
  # but an empty list here would take everything off the panel
  if [[ ${#objects[@]} -gt 0 ]]; then
    dconf write "$path/object-id-list" "$(printf '%s\n' "${objects[@]}" | dconf_array)"
  fi
}

# Flashback panel launchers
write_flashback_launchers

# Cinnamon panel launchers
# Prints the launchers a panel-launchers applet config holds, one per line
launcher_list() {
  python3 -c '
import json, sys

with open(sys.argv[1]) as f:
    conf = json.load(f)
for app in conf.get("launcherList", {}).get("value", []):
    print(app)
' "$1" 2>/dev/null || true
}
# Patch launcherList in place rather than regenerating the file: the applet
# instance id isn't always 1, and cinnamon resets the config to the schema
# defaults (which include gnome-terminal) when __md5__ doesn't match the
# settings-schema.json of the installed applet.
# Leaves the file alone when it already holds the right list, so that a
# non-zero exit means the config is broken (malformed, unwritable, ...)
patch_cinnamon_launcher_list() {
  python3 -c '
import json, sys

path, apps = sys.argv[1], sys.argv[2:]
with open(path) as f:
    conf = json.load(f)
entry = conf.setdefault("launcherList", {"type": "generic", "default": apps})
if entry.get("value") != apps:
    entry["value"] = apps
    with open(path, "w") as f:
        json.dump(conf, f, indent=4)
        f.write("\n")
' "$@"
}

for cfg in ~/.config/cinnamon/spices/panel-launchers@cinnamon.org/*.json \
           ~/.cinnamon/configs/panel-launchers@cinnamon.org/*.json; do
  if [[ -f "$cfg" ]]; then
    mapfile -t cinnamon_launchers < <(launcher_list "$cfg")
    mapfile -t cinnamon_launchers < <(merge_panel_launchers cinnamon "${cinnamon_launchers[@]}")
    if [[ ${#cinnamon_launchers[@]} -gt 0 ]] && \
       ! patch_cinnamon_launcher_list "$cfg" "${cinnamon_launchers[@]}"; then
      echo "Warning: could not set the launchers in $cfg" >&2
    fi
    # The applet caches its settings in memory, so tell cinnamon to reload it.
    # Do so even when the file already had the right list: it may well be a
    # running cinnamon that is out of date, not the file. Fails harmlessly
    # when cinnamon isn't running or is too old to have ReloadXlet.
    if command -v dbus-send >/dev/null 2>&1; then
      dbus-send --session --dest=org.Cinnamon --type=method_call \
        /org/Cinnamon org.Cinnamon.ReloadXlet string:panel-launchers@cinnamon.org string:APPLET \
        >/dev/null 2>&1 || true
    fi
  fi
done

if [[ -x /usr/bin/cinnamon-session ]] && \
   ! dconf read /org/cinnamon/enabled-applets | fgrep -q 'panel-launchers@cinnamon.org'; then
  echo "Note: panel-launchers@cinnamon.org is not in /org/cinnamon/enabled-applets;" \
       "the launchers on your panel come from some other applet" >&2
fi

# }}}
# Desktop icons {{{

mkdir -p ~/Desktop
for x in \
  $(filter_apps \
      'google-chrome.desktop|chromium.desktop' \
      'firefox-bwrap.desktop|firefox.desktop|firefox-esr.desktop' \
      "$terminal_desktop" \
    | uniq); do
  x_path=$(desktop_file "$x") || continue
  if ! [[ -f ~/Desktop/"$x" ]]; then
    cat "$x_path" >~/Desktop/"$x"
  fi
  if [[ -f ~/Desktop/"$x" ]]; then
    tmp=$(mktemp)  # avoid spurious sedXXXXXX files on desktop from sed -i
    sed -e 's/Name=Chromium Web Browser/Name=Chromium/; s/Name=Google Chrome/Name=Chrome/' <~/Desktop/"$x" >"$tmp"
    if ! cmp -s "$tmp" ~/Desktop/"$x" >/dev/null 2>&1; then
      cat "$tmp" >~/Desktop/"$x"
    fi
    rm -f "$tmp"
  fi
  # Mark as trusted
  chmod a+x ~/Desktop/"$x"
  gio set ~/Desktop/"$x" metadata::trusted true || true
done

# }}}
# Autostart {{{

if [[ -f /usr/share/applications/guake.desktop && ! -f ~/.config/autostart/guake.desktop ]]; then
  mkdir -p ~/.config/autostart
  rm -f ~/.config/autostart/guake.desktop
  cp -f /usr/share/applications/guake.desktop ~/.config/autostart/guake.desktop
fi

# }}}
# nvim-qt launcher {{{

# Launch nvim-qt through the qvim wrapper. The user copy shadows the system one
nvim_qt_desktop="$HOME/.local/share/applications/nvim-qt.desktop"
nvim_qt_system=
for dir in /usr/local/share/applications /usr/share/applications; do
  if [[ -f "$dir/nvim-qt.desktop" ]]; then
    nvim_qt_system="$dir/nvim-qt.desktop"
    break
  fi
done
if [[ -n "$nvim_qt_system" ]]; then
  mkdir -p "$(dirname "$nvim_qt_desktop")"
  tmp=$(mktemp)
  sed -e "s|^Exec=nvim-qt\\b|Exec=$HOME/.dotfiles/bin/qvim|" <"$nvim_qt_system" >"$tmp"
  if ! cmp -s "$tmp" "$nvim_qt_desktop"; then
    cat "$tmp" >"$nvim_qt_desktop"
  fi
  rm -f "$tmp"
elif grep -qs '/\.dotfiles/bin/qvim' "$nvim_qt_desktop"; then
  # nvim-qt got uninstalled, don't leave a launcher for it behind
  rm -f "$nvim_qt_desktop"
fi

# }}}
# Misc {{{

# wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
if [[ -x /usr/bin/gedit ]]; then
  mkdir -p ~/.local/share/gedit/styles
  cp -f gedit-dracula.xml ~/.local/share/gedit/styles/gedit-dracula.xml
  dconf write /org/gnome/gedit/preferences/editor/scheme "'dracula'"
fi

rm -f ~/.face ~/.face.icon
echo yes >~/.config/gnome-initial-setup-done

# }}}
# Password-less login keyring when autologin is enabled {{{
# To avoid annoying password prompts to unlock/create keyring.
# If keyring already exists, it will be backed up and replaced
# with an empty one.

autologin_enabled=0
if grep -qsx "autologin-user=$USER" /etc/lightdm/lightdm.conf ||
   { grep -qsx "AutomaticLoginEnable = true" /etc/gdm3/daemon.conf &&
     grep -qsx "AutomaticLogin = $USER" /etc/gdm3/daemon.conf; }; then
  autologin_enabled=1
fi

login_keyring="$HOME/.local/share/keyrings/login.keyring"
if (( autologin_enabled )) && [[ "$(head -c 9 "$login_keyring" 2>/dev/null)" != '[keyring]' ]]; then
  keyring_dir="$(dirname "$login_keyring")"
  mkdir -p "$keyring_dir"
  chmod 700 "$keyring_dir"
  if [[ -e "$login_keyring" ]]; then
    backup_keyring="$login_keyring.$(date +%Y%m%d%H%M%S).bak"
    mv -f "$login_keyring" "$backup_keyring"
    echo "Backed up old login keyring: $login_keyring -> $backup_keyring"
  fi
  rm -f "$login_keyring"
  cat >"$login_keyring" <<EOF
[keyring]
display-name=login
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-timeout=0
EOF
  chmod 600 "$login_keyring"
  # Without this apps get prompted to create a "Default keyring" instead
  if [[ ! -s "$keyring_dir/default" ]]; then
    echo login >"$keyring_dir/default"
  fi
  echo "Created password-less $login_keyring"
fi

# }}}

# vim: fdm=marker
