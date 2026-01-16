APP_ID := org.chromium.Chromium

default: local
local: install-flathub config

install-flathub:
	flatpak install -y --user flathub $(APP_ID)

uninstall:
	flatpak uninstall -y --user $(APP_ID) || true
	../install-launcher.sh uninstall $(APP_ID)

config:
	flatpak override --user \
	  --system-no-talk-name=org.bluez \
	  --system-no-talk-name=org.freedesktop.Avahi \
	  --system-no-talk-name=org.freedesktop.UPower \
	  --no-talk-name=org.freedesktop.FileManager1 \
	  --no-talk-name=org.freedesktop.ScreenSaver \
	  --no-talk-name=org.freedesktop.secrets \
	  --no-talk-name=org.gnome.SessionManage \
	  --nofilesystem=home \
	  --nofilesystem=host \
	  $(APP_ID)
	../install-launcher.sh $(APP_ID)

run:
	flatpak run $(APP_ID)
