APP_ID := com.github.tchx84.Flatseal
UPSTREAM_REPO := https://github.com/tchx84/Flatseal.git
UPSTREAM_DIR := upstream
PATCH_FILE := upstream.patch
MANIFEST := $(UPSTREAM_DIR)/com.github.tchx84.Flatseal.json
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

deps: upstream
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	#flatpak install -y --user flathub org.freedesktop.Platform//$(RUNTIME_VERSION)

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
	../install-launcher.sh $(APP_ID)

run:
	flatpak run $(APP_ID)

.PHONY: upstream
