# Cinnamon

Cinnamon applets and their configs:

- `applets/<name>`: symlinks to vendored applets in `../third_party/cinnamon-spices-applets/`
- `spices/<id>/<n>.json`: applet configs; `<n>` matches `org/cinnamon/enabled-applets` in `../dconf.json`
- `Makefile`:
  - `make` / `make install` / `install.sh`: links applets into `~/.local/share/cinnamon/applets`, installs configs, reloads them if needed; normally called by `../gui-setup.sh`
  - `make update`: copies configs from the system back here

Rest of cinnamon config lives in `../dconf.json` and `../gui-setup.sh`.
