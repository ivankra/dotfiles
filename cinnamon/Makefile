# Cinnamon applets and their configs
#
#   make, make install  install from here into the system (same as ./install.sh)
#   make update         copy tracked configs from ~/.config/cinnamon/spices back here

SPICES_DIR := $(HOME)/.config/cinnamon/spices
CONFIGS := $(wildcard spices/*/*.json)

all: install

install:
	./install.sh

# Only files already tracked in spices/ are pulled: new applet instances also
# need org/cinnamon/enabled-applets adjusted in ../dconf.json, so add those by hand
update:
	@for src in $(CONFIGS); do \
	  sys="$(SPICES_DIR)/$${src#spices/}"; \
	  if [ -f "$$sys" ] && ! cmp -s "$$sys" "$$src"; then \
	    cp -f "$$sys" "$$src"; \
	    echo "$$sys -> $$src"; \
	  fi; \
	done

.PHONY: all install update
