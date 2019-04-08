#!/bin/bash

cat <<EOF
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/airy.conf
custom_palette=false
icon_theme=Humanity
standard_dialogs=default
style=Adwaita

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
menus_have_icons=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

EOF

if [[ "$HIDPI" == "1" ]]; then
  cat <<'EOF'
[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\"\0I\0o\0s\0\x65\0v\0k\0\x61\0 \0T\0\x65\0r\0m\0 \0S\0S\0\x30\0\x34@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x39\x10)
general=@Variant(\0\0\0@\0\0\0\f\0R\0o\0\x62\0o\0t\0o@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
EOF
fi
