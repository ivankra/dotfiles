APP_ID := org.gnome.Papers
UPSTREAM_REPO := https://github.com/flathub/$(APP_ID).git
UPSTREAM_DIR := upstream
PATCH_FILE := upstream.patch
MANIFEST := $(UPSTREAM_DIR)/$(APP_ID).json
RUNTIME_VERSION = $(shell sed -En 's/^ *"?runtime-version"?: *//p' $(MANIFEST) | tr -d " '\",")
BUILD_DIR := build-dir
REPO_DIR := /tmp/flatpak-repo-$(APP_ID)-$(USER)

default: local
local: install config
flathub: install-flathub config

upstream:
	@if ! [ -d "$(UPSTREAM_DIR)/.git" ]; then \
	  echo "Cloning $(UPSTREAM_REPO) into $(UPSTREAM_DIR)"; \
	  git clone "$(UPSTREAM_REPO)" "$(UPSTREAM_DIR)"; \
	fi
	@if ! [ -f "$(UPSTREAM_DIR)/shared-modules/.git" ]; then \
	  echo "Cloning submodules"; \
	  cd "$(UPSTREAM_DIR)" && git submodule update --init; \
	fi

deps: upstream
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --user flathub \
	  org.gnome.Platform//$(RUNTIME_VERSION) \
	  org.gnome.Sdk//$(RUNTIME_VERSION)

build: deps
	cd $(UPSTREAM_DIR) && flatpak-builder --user --force-clean ../$(BUILD_DIR) $(notdir $(MANIFEST))

bundle: build
	mkdir -p $(REPO_DIR)
	flatpak build-export --disable-fsync $(REPO_DIR) $(BUILD_DIR)
	flatpak build-bundle $(REPO_DIR) ../$(APP_ID).flatpak $(APP_ID)
	rm -rf $(REPO_DIR)
	@echo "Bundle created: ../$(APP_ID).flatpak"

clean:
	rm -rf .flatpak-builder $(BUILD_DIR) $(REPO_DIR) $(UPSTREAM_DIR)

install: deps
	cd $(UPSTREAM_DIR) && flatpak-builder --user --force-clean --install ../$(BUILD_DIR) $(notdir $(MANIFEST))

install-flathub:
	flatpak install -y --user flathub $(APP_ID)

uninstall:
	flatpak uninstall -y --user $(APP_ID) || true
	../install-launcher.sh uninstall $(APP_ID)

config:
	../install-launcher.sh --name="Papers (Flatpak)" $(APP_ID)
	# ../install-launcher.sh --name="Papers (Flatpak)" --binary=evince --launcher=evince.desktop $(APP_ID)

run:
	flatpak run $(APP_ID)

.PHONY: upstream
