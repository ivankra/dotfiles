APP_ID := com.cursor.Cursor
MANIFEST := $(APP_ID).yaml
RUNTIME_VERSION = $(shell sed -En 's/^ *"?runtime-version"?: *//p' $(MANIFEST) | tr -d " '\",")
DOWNLOAD_DIR := download-dir
BUILD_DIR := build-dir
REPO_DIR := /tmp/flatpak-repo-$(APP_ID)-$(USER)

default: local
local: install config

download:
	@mkdir -p $(DOWNLOAD_DIR); \
	if [ -f "$(DOWNLOAD_DIR)/cursor.AppImage" ]; then \
	  echo "Using existing $(DOWNLOAD_DIR)/cursor.AppImage"; \
	  exit 0; \
	fi; \
	arch=$$(dpkg --print-architecture 2>/dev/null || uname -m | sed -e 's/^amd64$$/x64/' -e 's/^x86_64$$/x64/' -e 's/^aarch64$$/arm64/' -e 's/^arm64$$/arm64/'); \
	url="https://api2.cursor.sh/updates/download/golden/linux-$$arch/cursor/2.3"; \
	tmp="$(DOWNLOAD_DIR)/cursor.AppImage.tmp.$$"; \
	echo "Downloading $$url"; \
	curl -fL -o "$$tmp" "$$url"; \
	mv "$$tmp" "$(DOWNLOAD_DIR)/cursor.AppImage"

deps: download
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --user flathub \
	  org.freedesktop.Platform//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk//$(RUNTIME_VERSION) \
	  org.electronjs.Electron2.BaseApp//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk.Extension.golang//$(RUNTIME_VERSION)

build: deps
	flatpak-builder --user --force-clean $(BUILD_DIR) $(MANIFEST)

install: deps
	flatpak-builder --user --force-clean --install $(BUILD_DIR) $(MANIFEST)

config:
	../install-launcher.sh $(APP_ID)

uninstall:
	flatpak uninstall -y --user $(APP_ID) || true
	../install-launcher.sh uninstall $(APP_ID)

bundle: build
	mkdir -p $(REPO_DIR)
	flatpak build-export --disable-fsync $(REPO_DIR) $(BUILD_DIR)
	flatpak build-bundle $(REPO_DIR) ../$(APP_ID).flatpak $(APP_ID)
	rm -rf $(REPO_DIR)
	@echo "Bundle created: ../$(APP_ID).flatpak"

run:
	flatpak run $(APP_ID)

clean:
	rm -rf .flatpak-builder $(BUILD_DIR) $(REPO_DIR) $(DOWNLOAD_DIR)

.PHONY: upstream
