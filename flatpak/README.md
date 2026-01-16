# Flatpak

This directory contains customized apps from Flathub, as well as some custom packaged apps from scratch.

## Building

Main make targets in each subdirectory:

  * `make`: defaults to `local`, sometimes `flathub` for large projects
  * `make local`: build app locally, install and configure
  * `make flathub`: install pre-built app from flathub and configure
  * `make bundle`: build the app without installing it and export a .flatpak bundle for distribution.
    * Install bundle with a command like: `flatpak install -y --user ./net.ankiweb.Anki.flatpak`
  * `make config`: add overrides, menu launcher, symlink to `~/.local/bin/`

## Configuration

Dangerous permissions (especially `--filesystem=home` and `--talk-name=org.freedesktop.Flatpak`) are by default disabled - both via a patched build config and a runtime override as a fail-safe.

IDE apps are using Sdk runtime rather than Platform (for standard build tools: gcc, python, git etc) and `--env=FLATPAK_ENABLE_SDK_EXT=*` -> any installed `org.freedesktop.Sdk.Extension.*` should be automatically available in the sandbox. Installing an extra SDK ([list](https://github.com/orgs/flathub/repositories?language=&q=extension&sort=&type=all)):

```sh
flatpak install -y --user flathub org.freedesktop.Sdk.Extension.typescript//25.08
```

Run `make sdk` in this directory to install common SDK extensions.
