APP_ID := com.antigravity.Antigravity
MANIFEST := $(APP_ID).yaml
RUNTIME_VERSION = $(shell sed -En 's/^ *"?runtime-version"?: *//p' $(MANIFEST) | tr -d " '\",")
DOWNLOAD_DIR := download-dir
BUILD_DIR := build-dir
REPO_DIR := /tmp/flatpak-repo-$(APP_ID)-$(USER)

default: local
local: install config

# https://antigravity.google/download/linux
download:
	@mkdir -p $(DOWNLOAD_DIR); \
	if [ -f "$(DOWNLOAD_DIR)/antigravity.deb" ]; then \
	  echo "Using existing $(DOWNLOAD_DIR)/antigravity.deb"; \
	  exit 0; \
	fi; \
	repo_url="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"; \
	arch=$$(dpkg --print-architecture 2>/dev/null || uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/'); \
	packages_url="$$repo_url/dists/antigravity-debian/main/binary-$$arch/Packages"; \
	deb_path=$$(curl -fsSL $$packages_url | \
	  awk '/^Package: antigravity$$/{p=1} p && /^Filename:/{print $$2} p && /^$$/{p=0}' | \
	  sort -V | tail -n 1); \
	test -n "$$deb_path" || (echo "No antigravity package found for $$arch" >&2; exit 1); \
	tmp="$(DOWNLOAD_DIR)/antigravity.deb.tmp.$$"; \
	url="$$repo_url/$$deb_path"; \
	echo "Downloading $$url"; \
	curl -fL -o "$$tmp" "$$url"; \
	mv "$$tmp" "$(DOWNLOAD_DIR)/antigravity.deb"

deps: download
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak install -y --user flathub \
	  org.freedesktop.Platform//$(RUNTIME_VERSION) \
	  org.freedesktop.Sdk//$(RUNTIME_VERSION) \
	  org.electronjs.Electron2.BaseApp//$(RUNTIME_VERSION)

build: deps
	flatpak-builder --user --force-clean $(BUILD_DIR) $(MANIFEST)

bundle: build
	mkdir -p $(REPO_DIR)
	flatpak build-export --disable-fsync $(REPO_DIR) $(BUILD_DIR)
	flatpak build-bundle $(REPO_DIR) ../$(APP_ID).flatpak $(APP_ID)
	rm -rf $(REPO_DIR)
	@echo "Bundle created: ../$(APP_ID).flatpak"

clean:
	rm -rf .flatpak-builder $(BUILD_DIR) $(REPO_DIR) $(DOWNLOAD_DIR)

install: deps
	flatpak-builder --user --force-clean --install $(BUILD_DIR) $(MANIFEST)

uninstall:
	flatpak uninstall -y --user $(APP_ID) || true
	../install-launcher.sh uninstall $(APP_ID)

config:
	../install-launcher.sh $(APP_ID)

run:
	flatpak run $(APP_ID)

.PHONY: upstream
