DOCKER := $(or $(shell command -v podman docker 2>/dev/null | head -1),docker)
PLATFORM ?= linux/arm64

wezterm: Dockerfile $(wildcard *.patch)
	$(DOCKER) build --platform=$(PLATFORM) -f Dockerfile -t wezterm-builder .
	rm -f wezterm.cid
	$(DOCKER) run --cidfile wezterm.cid wezterm-builder
	$(DOCKER) cp "`cat wezterm.cid`:/dist/." .
	$(DOCKER) rm "`cat wezterm.cid`" && rm -f wezterm.cid

sh:
	$(DOCKER) run -it wezterm-builder /bin/bash

clean:
	$(DOCKER) image rm -f wezterm-builder
	rm -f wezterm_*.deb

.PHONY: wezterm sh clean
