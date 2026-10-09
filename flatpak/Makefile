# Thin wrapper over flatpak.sh so that `make <TAB>` completes app names.
APPS := $(shell ./flatpak.sh list)

.PHONY: $(APPS) sdk update
$(APPS) sdk update:
	./flatpak.sh $@

.DEFAULT_GOAL := help
help:
	@./flatpak.sh help
.PHONY: help
