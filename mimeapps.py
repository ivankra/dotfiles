#!/usr/bin/env python3
# Merges the entries of ./mimeapps.list into ~/.config/mimeapps.list.

import argparse
import configparser
import difflib
import io
import os
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent

# .desktop file -> alternatives to use when it isn't installed,
# in order of preference. Resolved recursively if needed.
FALLBACKS = {
    'google-chrome.desktop': ['chromium.desktop', 'firefox-bwrap.desktop'],
    'firefox-bwrap.desktop': ['firefox.desktop', 'firefox-esr.desktop'],
    'mpv.desktop': ['vlc.desktop'],
    'nemo.desktop': ['org.gnome.Nautilus.desktop', 'nautilus.desktop'],
    'nvim-qt.desktop': ['gvim.desktop'],
    'org.gnome.eog.desktop': ['eog.desktop', 'org.gnome.Loupe.desktop'],
    # A non-standard x-scheme-handler/terminal is added for our gui-setup.sh
    'org.gnome.Ptyxis.desktop': ['org.gnome.Terminal.desktop', 'org.kde.konsole.desktop', 'xterm.desktop'],
}


def resolve_app(app):
    data_home = os.environ.get('XDG_DATA_HOME') or Path.home() / '.local/share'
    data_dirs = os.environ.get('XDG_DATA_DIRS') or '/usr/local/share:/usr/share'
    dirs = [Path(d) / 'applications' for d in [data_home] + data_dirs.split(':') if d]
    seen = set()
    stack = [app]
    while stack:
        candidate = stack.pop()
        if candidate in seen:
            continue
        seen.add(candidate)
        if any((d / candidate).is_file() for d in dirs):
            return candidate
        stack += reversed(FALLBACKS.get(candidate, []))
    return None


class MimeApps:
    # Sections whose value is a ";"-terminated list of apps, the way gio writes
    # them. The default app of a type is written plain instead
    LIST_SECTIONS = ('Added Associations', 'Removed Associations')

    def __init__(self, path):
        self.path = Path(path)
        try:
            self.lines = self.path.read_text(encoding='utf-8').splitlines(keepends=True)
        except FileNotFoundError:
            self.lines = []
        self.cfg = configparser.RawConfigParser(delimiters=('=',), strict=False)
        self.cfg.optionxform = str
        self.cfg.read_string(''.join(self.lines), source=str(self.path))

    @staticmethod
    def apps(value):
        """Splits an entry's value, tolerating stray, missing and trailing ";"."""
        return [x.strip() for x in value.split(';') if x.strip()]

    def entries(self):
        """Yields (section, mime type, value) for every entry."""
        for section in self.cfg.sections():
            for key, value in self.cfg.items(section):
                yield section, key, value

    def update(self, other):
        """Replaces/creates other's entries here, like dict.update(). Returns
        whether anything changed.

        An entry that already lists the same apps is left alone, spelling and
        all, so that a file written by hand (no trailing ";", say) isn't
        rewritten for the sake of it.
        """
        changed = False
        for section, key, value in other.entries():
            if not self.cfg.has_section(section):
                self.cfg.add_section(section)
            if self.apps(self.cfg[section].get(key, '')) != self.apps(value):
                self.cfg[section][key] = value
                changed = True
        return changed

    def resolve_apps(self):
        """Rewrites every entry's apps to the installed ones, dropping the
        entries left with no app at all."""
        for section, key, value in list(self.entries()):
            apps = []
            for app in self.apps(value):
                app = resolve_app(app)
                if app and app not in apps:  # dedup, preserving order
                    apps.append(app)
            if apps:
                value = ';'.join(apps)
                if section in self.LIST_SECTIONS:
                    value += ';'
                self.cfg[section][key] = value
            else:
                self.cfg.remove_option(section, key)

    def format(self):
        """Formats the file as a list of lines."""
        out = io.StringIO()
        self.cfg.write(out, space_around_delimiters=False)
        return out.getvalue().splitlines(keepends=True)


def main():
    parser = argparse.ArgumentParser(
        description='Merges mimeapps.list next to this script into ~/.config/mimeapps.list.')
    parser.add_argument('-d', '--dry-run', action='store_true',
                        help='print a diff of the changes instead of making them')
    args = parser.parse_args()

    src = MimeApps(SCRIPT_DIR / 'mimeapps.list')
    src.resolve_apps()

    config_dir = Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config')
    dst = MimeApps(config_dir / 'mimeapps.list')
    changed = dst.update(src)
    merged = dst.format()

    if not changed or merged == dst.lines:
        if args.dry_run:
            print('%s is up to date' % dst.path)
        return

    if args.dry_run:
        sys.stdout.writelines(difflib.unified_diff(
            dst.lines, merged, fromfile=str(dst.path), tofile='%s (merged)' % dst.path))
        return

    dst.path.parent.mkdir(parents=True, exist_ok=True)
    dst.path.write_text(''.join(merged), encoding='utf-8')
    print('Updated %s' % dst.path)


if __name__ == '__main__':
    sys.exit(main())
