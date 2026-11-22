# Themes

Color themes shared by the editors and terminals. Each subdirectory is one theme
and provides the same set of files (see `FILES` in the `Makefile`),
plus a `setup.sh` for settings that can't be loaded from a file. Each theme's
`README.md` lists its sources and local tweaks.

The active theme is the `~/.config/theme` symlink.
App configs load their theme file from there, e.g. `~/.config/theme/kitty.conf`.

## Switching themes

```sh
~/.dotfiles/themes/<name>/setup.sh
```

A theme's `setup.sh` repoints `~/.config/theme` to itself, then applies
settings stored in dconf (gnome-terminal, guake, ptyxis).

The theme can also be switched as part of a full setup run:

```sh
~/.dotfiles/setup.sh --theme=<name>      # only repoints ~/.config/theme (works without a GUI)
~/.dotfiles/gui-setup.sh --theme=<name>  # runs the theme's setup.sh
```

## Neovim

Unlike the other apps, nvim has no theme file. Everything is in
`nvim/lua/plugins/colorscheme.lua`:

- **Scheme:** the theme's directory name, e.g. `:colorscheme dracula-dark`, with
  `background=dark`. A new theme's directory must be named after an nvim
  colorscheme that comes from a plugin spec in that file or from `nvim/colors/`.
- **Options** (e.g. no italics) are set there per scheme, so they apply however the
  scheme gets chosen.
- **Sticky `:colorscheme`:** the last `:colorscheme` (and `'background'`) is
  saved to `~/.local/state/nvim/colorscheme` and used instead of the theme's
  scheme at startup. Switching themes either way above deletes that file. You
  can also delete it by hand to go back to the theme.

## Maintenance

- `make lint`: check that every theme has all files and no broken symlinks.
- `make licenses`: regenerate each theme's `LICENSE` from the upstream links in its `README.md`.
