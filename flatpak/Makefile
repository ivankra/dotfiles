SUBDIRS := $(patsubst %/,%,$(dir $(wildcard */Makefile)))
RUNTIME_VERSION := 25.08

# Disable any sensitive permissions by default
OVERRIDES=--no-talk-name=org.freedesktop.Flatpak \
	  --no-talk-name=org.freedesktop.PowerManagement \
	  --no-talk-name=org.freedesktop.secrets \
	  --no-talk-name=org.gnome.SessionManager \
	  --no-talk-name=org.kde.kwalletd5 \
	  --nofilesystem=home \
	  --nofilesystem=host \
	  --nofilesystem=xdg-run/gnupg \
	  --nosocket=ssh-auth \
	  --system-no-talk-name=org.freedesktop.UPower \
	  --system-no-talk-name=org.freedesktop.login1

all: user-config system-config sdk base

user-config:
	flatpak override --user $(OVERRIDES)

system-config:
	@if flatpak override --show --system | fgrep -qx 'org.freedesktop.Flatpak=none'; then \
	  echo "System overrides already applied"; \
	else \
	  (set -x; sudo flatpak override --system $(OVERRIDES)); \
	fi

# https://github.com/orgs/flathub/repositories?language=&q=sdk.extension&sort=&type=all
sdk:
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --user flathub \
	  org.freedesktop.Platform//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.dotnet10//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.golang//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.llvm21//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.openjdk25//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.rust-stable//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.texlive//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.typescript//$(RUNTIME_VERSION) \
	  org.electronjs.Electron2.BaseApp//$(RUNTIME_VERSION)

BASE=flatseal mpv

base:
	for d in $(BASE); do $(MAKE) -C $$d; done

bundle config clean upstream:
	@for d in $(SUBDIRS); do $(MAKE) -C $$d $@; done
