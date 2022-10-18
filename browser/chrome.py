#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path


class JsonWrapper:
    def __init__(self, obj, parent=None, name=None):
        self._obj = obj
        self._parent = parent
        self._name = name

    def _materialize(self):
        if self._obj is None:
            self._obj = {}
            if self._parent:
                self._parent._materialize()
                self._parent._obj[self._name] = self._obj

    def __getattr__(self, key):
        obj = self._obj
        if obj is not None:
            if hasattr(obj, key):
                return getattr(obj, key)
            else:
                obj = obj.get(key)
        if obj is None or type(obj) is dict:
            return JsonWrapper(obj, parent=self, name=key)
        else:
            return obj

    def __setattr__(self, key, val):
        if key.startswith('_'):
            self.__dict__[key] = val
        else:
            self._materialize()
            self._obj[key] = val

    def __delattr__(self, key):
        if self._obj is not None and key in self._obj:
            del self._obj[key]

    def __getitem__(self, key):
        return self._obj.__getitem__(key)

    def __setitem__(self, key, val):
        return self._obj.__setitem__(key, val)

    def __contains__(self, key):
        return self._obj.__contains__(key)

    def __nonzero__(self):
        return bool(self._obj)

    def __repr__(self):
        return '<JsonWrapper %s>' % json.dumps(self._obj)

    def get(self, key, default=None):
        if self._obj is None:
            return default
        return self._obj.get(key, default)

    def setdefault(self, key, default=None):
        self._materialize()
        return self._obj.setdefault(key, default)


class JsonIO(JsonWrapper):
    def __init__(self, path):
        self._path = path
        try:
            self._obj = json.load(open(self._path, 'r'))
            self._orig_dump = json.dumps(self._obj)
        except:
            self._obj = {}
            self._orig_dump = ''
            print("Warning: %s doesn't exist" % self.path)

    def __enter__(self):
        return self

    def __exit__(self, et, ev, tb):
        return
        if et is None and json.dumps(self._obj) != self._orig_dump:
            path_tmp = self._path.with_suffix('.tmp')
            with open(path_tmp, 'w') as fp:
                json.dump(self._obj, fp, indent=3)
            os.rename(path_tmp, self._path)
            print('Updated %s' % self._path)

            path_bak = self._path.with_suffix('.bak')
            if os.path.exists(path_bak):
                os.remove(path_bak)


def tweak_profile(profile_path):
    print('Profile: %s' % profile_path)

    if not (profile_path / 'Default' / 'Preferences').exists():
        print('Error: profile directory is not initialized')
        return

    with JsonIO(profile_path / 'Default' / 'Preferences') as prefs:
        prefs.alternate_error_pages.enabled = False
        prefs.bookmark_bar.show_on_all_tabs = False
        prefs.browser.check_default_browser = False
        prefs.browser.has_seen_welcome_page = True
        prefs.dns_prefetching.enabled = False
        #prefs.enable_do_not_track = True
        prefs.intl.accept_languages = 'en-US,en'
        del prefs.invalidator.client_id
        del prefs.gaia_cookie
        del prefs.google
        del prefs.protection.macs.google
        del prefs.media.device_id_salt
        del prefs.protection.macs.media
        prefs.net.network_prediction_options = 2
        prefs.profile.default_content_setting_values.background_sync = 2
        prefs.safebrowsing.enabled = False
        del prefs.protection.macs.safebrowsing
        prefs.search.suggest_enabled = False
        prefs.signin.allowed = False
        prefs.signin.allowed_on_next_startup = False
        prefs.translate.enabled = False
        if 'debian' in prefs.get('homepage', ''):
            prefs.homepage = ''
            del prefs.protection.macs.homepage

    with JsonIO(profile_path / 'Local State') as ls:
        ls.browser.enabled_labs_experiments = ['enable-webrtc-hide-local-ips-with-mdns@1', 'smooth-scrolling@2']

    path = profile_path / 'Default' / 'Bookmarks'
    if path.exists():
        with JsonIO(path) as bookmarks:
            for root in bookmarks.roots.values():
                if 'children' not in root: continue
                filt = []
                for ch in root['children']:
                    if 'debian.org' in ch['url']:
                        print('Removing bookmark %s' % ch['url'])
                        del bookmarks.checksum
                    else:
                        filt.append(ch)
                root['children'] = filt


if __name__ == '__main__':
    tweak_profile(Path('~/.config/chromium').expanduser())
    tweak_profile(Path('~/.config/google-chrome').expanduser())
