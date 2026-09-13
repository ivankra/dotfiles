# Source to make X11 apps launched afterwards request a dark title bar.
#
# Qt doesn't set _GTK_THEME_VARIANT, so muffin draws a light title bar;
# preload a shim that sets it before the window is mapped.

__xcb_dark_src="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/xcb-dark-variant.c"
__xcb_dark_so="$HOME/.cache/xcb-dark-variant.so"

if command -v gcc >/dev/null 2>&1 && [[ -f "$__xcb_dark_src" && ( ! -f "$__xcb_dark_so" || "$__xcb_dark_src" -nt "$__xcb_dark_so" ) ]]; then
  mkdir -p "$(dirname "$__xcb_dark_so")"
  gcc -O2 -Wall -shared -fPIC -o "$__xcb_dark_so" "$__xcb_dark_src" -ldl || rm -f "$__xcb_dark_so"
fi

if [[ -n "$DISPLAY" && -f "$__xcb_dark_so" ]]; then
  export LD_PRELOAD="$__xcb_dark_so${LD_PRELOAD:+:$LD_PRELOAD}"
fi

unset __xcb_dark_src __xcb_dark_so
