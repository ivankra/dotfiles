# Flatpak

Install curated Flatpak apps and lock down their permissions with a single command:

  * `make`: list apps; `make <TAB>` completes app names
  * `make anki` or `./flatpak.sh anki`: install app
  * `./flatpak.sh uninstall anki`
  * `make update`: update all apps and refresh launchers (launchers are copies of the exported .desktop files)
  * `make sdk`: install most SDK runtimes/extensions

Flathub apps are listed in `apps.tsv` (tab-separated: alias, app-id, optional menu name);
the alias is also the `~/.local/bin` command.
Locally built apps need no entry: a `<alias>/<app-id>.yaml` manifest makes one
(`cursor`, `antigravity`, `tine`), with optional `download.sh`;
its runtime/SDK/extensions are installed from the manifest. Build state lives in
`~/.local/share/dotfiles-flatpak/` (`./flatpak.sh clean <app>` wipes an app's).
Apps are always installed for the *current user only*, not system-wide.

## SDKs

IDE apps use `FLATPAK_ENABLE_SDK_EXT=*` (set in their override file) ->
any installed `org.freedesktop.Sdk.Extension.*` is available in the sandbox.

Run `make sdk` to install a default set of SDKs.
Installing an [extra SDK](https://github.com/orgs/flathub/repositories?language=&q=extension&sort=&type=all):

```sh
flatpak install -y --user flathub org.freedesktop.Sdk.Extension.typescript//25.08
```

## Configuration

Permissions are tightened with plain flatpak override files in `overrides/`,
automatically installed as a symlink at `~/.local/share/flatpak/`.

Edit `overrides/<app-id>` directly or via Flatseal (it will write through
the symlink to dotfiles repo).

Dangerous permissions (`--filesystem=home`,
`--talk-name=org.freedesktop.Flatpak` etc) are disabled globally
via `overrides/global` file, which applies to every app.
Per-app files are optional: create `overrides/<app-id>` only when an app needs
something tightened (or re-granted) beyond `global`.

## Tips

Flatpak stores per-app data in `~/.var/app/`.

Anki's database is in `~/.var/app/net.ankiweb.Anki/data/Anki2`.
