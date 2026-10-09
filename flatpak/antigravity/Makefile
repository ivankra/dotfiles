# Thin wrapper: the build logic lives in ../flatpak.sh (this dir: manifest, optional download.sh)
ALIAS := $(notdir $(CURDIR))

default:
	../flatpak.sh $(ALIAS)

bundle clean uninstall:
	../flatpak.sh $@ $(ALIAS)

.PHONY: default bundle clean uninstall
