APP_ID := org.libreoffice.LibreOffice

default: flathub
flathub: install-flathub config

install-flathub:
	flatpak install -y --user flathub $(APP_ID)

uninstall:
	flatpak uninstall -y --user $(APP_ID) || true
	../install-launcher.sh uninstall $(APP_ID)

config:
	flatpak override --user \
	  --filesystem=host-os:ro \
	  --filesystem=xdg-documents \
	  --filesystem=xdg-download \
	  --nofilesystem=home \
	  --nofilesystem=host \
	  --unshare=network \
	  $(APP_ID)
	../install-launcher.sh $(APP_ID)

run:
	flatpak run $(APP_ID)
