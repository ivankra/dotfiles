# Files that the dotfiles repo loads or runs from ~/.config/theme/
FILES = alacritty.toml gnome-terminal.dconf guake.dconf kitty.conf nvim.lua setup.sh tmux.conf vim.vim wezterm.lua

THEMES = $(patsubst %/,%,$(wildcard */))

# Check that every theme has all files, and none are broken symlinks
lint:
	@rc=0; \
	for theme in $(THEMES); do \
	  for file in $(FILES); do \
	    if ! [ -e "$$theme/$$file" ] && ! [ -L "$$theme/$$file" ]; then \
	      echo "$$theme/$$file: missing"; rc=1; \
	    fi; \
	  done; \
	done; \
	for link in $$(find . -type l ! -exec test -e {} \; -print | sed 's|^\./||' | LC_ALL=C sort); do \
	  echo "$$link: broken symlink -> $$(readlink "$$link")"; rc=1; \
	done; \
	if [ $$rc = 0 ]; then echo OK; fi; \
	exit $$rc

# Collect license URLs from ([upstream](...), [license](...)).
licenses: $(addsuffix /LICENSE,$(THEMES))

%/LICENSE: %/README.md Makefile
	@set -e; \
	tmp=$$(mktemp "$@.tmp.XXXXXX"); \
	trap 'rm -f "$$tmp"' 0; \
	sed -nE 's/.*, \[[^]]+\]\((https:\/\/[^)]+)\)\).*/\1/p' "$<" | LC_ALL=C sort -u | \
	while IFS= read -r url; do \
	  raw=$$(printf '%s\n' "$$url" | sed -E \
	    -e 's|https://github.com/([^/]+/[^/]+)/blob/|https://raw.githubusercontent.com/\1/|' \
	    -e 's|/-/blob/|/-/raw/|'); \
	  printf '%s\n\n' "$$url"; \
	  curl --fail --silent --show-error --location --retry 2 \
	    --connect-timeout 15 --max-time 60 "$$raw"; \
	  printf '\n\n'; \
	done >"$$tmp"; \
	mv "$$tmp" "$@"; \
	echo "Generated $@"

.PHONY: lint licenses
