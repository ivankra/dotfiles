#!/usr/bin/env python3

import json
import os

class JsonWrapper:
    def __init__(self, path):
        self.path = os.path.expanduser(path)

    def __enter__(self):
        try:
            self.obj = json.load(open(self.path, 'r'))
            self.dump1 = json.dumps(self.obj)
        except:
            self.obj = dict()
            self.dump1 = ''
            print("Warning: %s doesn't exist" % self.path)
        return self

    def __exit__(self, et, ev, tb):
        if self.modified() and self.dump1 != '':
            with open(self.path + '.tmp', 'w') as fp:
                json.dump(self.obj, fp, indent=3)
            os.rename(self.path + '.tmp', self.path)
            print('Updated %s' % self.path)
            if os.path.exists(self.path + '.bak'):
                os.remove(self.path + '.bak')

    def modified(self):
        return json.dumps(self.obj) != self.dump1

    def __getitem__(self, keys):
        return self.get(keys)

    def get(self, keys, def_val=None):
        if type(keys) is str:
            keys = keys.split('.')
        x = self.obj
        for key in keys[:-1]:
            x = x.setdefault(key, dict())
        return x.get(keys[-1], def_val)

    def __setitem__(self, keys, val):
        if type(keys) is str:
            keys = keys.split('.')
        x = self.obj
        for key in keys[:-1]:
            x = x.setdefault(key, dict())
        key = keys[-1]
        if key in x and x[key] == val:
            return
        print('Setting %s = %s' % ('.'.join(keys), val))
        x[key] = val

    def setdefault(self, keys, val=None):
        if type(keys) is str:
            keys = keys.split('.')
        x = self.obj
        for key in keys[:-1]:
            x = x.setdefault(key, dict())
        return x.setdefault(keys[-1], val)

    def __delitem__(self, keys):
        if type(keys) is str:
            keys = keys.split('.')
        x = self.obj
        for key in keys[:-1]:
            if key not in x: return
            x = x[key]
        key = keys[-1]
        if key in x:
            del x[key]
            print('Deleting %s' % '.'.join(keys))


with JsonWrapper('~/.config/chromium/Default/Preferences') as w:
    w['alternate_error_pages.enabled'] = False
    w['bookmark_bar.show_on_all_tabs'] = False
    w['browser.check_default_browser'] = False
    w['browser.has_seen_welcome_page'] = True
    w['enable_do_not_track'] = True
    w['intl.accept_languages'] = 'en-US,en'
    w['net.network_prediction_options'] = 2
    w['profile.default_content_setting_values.background_sync'] = 2
    w['search.suggest_enabled'] = False
    w['signin.allowed'] = False
    w['signin.allowed_on_next_startup'] = False
    w['translate.enabled'] = False
    if 'debian' in w.get('homepage', ''):
        w['homepage'] = ''
        del w['protection.macs.homepage']

with JsonWrapper('~/.config/chromium/Local State') as w:
    l = w.setdefault('browser.enabled_labs_experiments', [])
    if 'smooth-scrolling@2' not in l:
        print('Disabling smooth scrolling')
        l.append('smooth-scrolling@2')

with JsonWrapper('~/.config/chromium/Default/Bookmarks') as w:
    if w['roots'] is not None:
        for root in w['roots'].values():
            if 'children' not in root: continue
            filt = []
            for ch in root['children']:
                if 'debian.org' in ch['url']:
                    print('Removing bookmark %s' % ch['url'])
                    continue
                filt.append(ch)
            root['children'] = filt

    if w.modified() and w['checksum'] is not None:
        del w['checksum']
