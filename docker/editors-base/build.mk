# Shared rules for the editor images.
#
# A per-editor Makefile is just:
#
#     BASE := nvim-lazy          # optional, defaults to editors-base
#     include ../editors-base/build.mk
#
# `make build` builds the image and symlinks $(BINDIR)/$(IMAGE) to this
# directory's run script, so the containerised editor sits on $PATH. A symlink
# rather than a generated wrapper: the run scripts carry the XDG/X11/GPU
# plumbing these images need, and edits to them take effect immediately.
#
# Nothing outside this directory is referenced, so it can be copied anywhere
# and still build.

IMAGE  := $(notdir $(CURDIR))
BASE   ?= editors-base
BINDIR ?= $(HOME)/.local/bin

LAUNCHER := $(BINDIR)/$(IMAGE)
RUN      := $(CURDIR)/run.sh

# Warn if the launcher will not be reachable.
define warn-unless-on-path
	case ":$$PATH:" in \
	  *":$(BINDIR):"*) ;; \
	  *) echo "warning: $(BINDIR) is not on your PATH; add it with" >&2; \
	     echo "  echo 'export PATH=\"$(BINDIR):\$$PATH\"' >>~/.bashrc" >&2 ;; \
	esac
endef

.PHONY: all deps build image image-nocache rebuild launcher

all: deps build

# BASE is empty for images that build straight from a distro tag.
deps:
	@test -z "$(BASE)" || $(MAKE) -C ../$(BASE)

build: image launcher

rebuild: image-nocache launcher

image:
	podman build -t $(IMAGE) .

image-nocache:
	podman build -t $(IMAGE) --no-cache .

# Refuse to clobber anything that is not already a launcher symlink.
launcher:
	@test -f $(RUN) || { echo "$(RUN) is missing, nothing to link" >&2; exit 1; }
	@mkdir -p $(BINDIR)
	@if { [ -e $(LAUNCHER) ] || [ -L $(LAUNCHER) ]; } && \
	    [ "$$(readlink $(LAUNCHER))" != "$(RUN)" ]; then \
		echo "$(LAUNCHER) exists and is not a launcher symlink; refusing to replace it" >&2; \
		exit 1; \
	fi
	@ln -sfn $(RUN) $(LAUNCHER)
	@echo "linked $(LAUNCHER) -> $(RUN)"
	@$(warn-unless-on-path)
