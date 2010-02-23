#!/usr/bin/env python
# Gets rid of Ubuntu's default multimedia file associations with totem in favor of VLC player
import os, sys

DEFAULTS_LIST = '/usr/share/applications/defaults.list'
LOCAL_LIST = os.path.join(os.environ['HOME'], '.local/share/applications/mimeapps.list')

def assoc_reader(filename):
    for line in file(filename):
        if '=' in line:
            line = line.strip().split('=')
            assert len(line) == 2
            yield line

def main():
    targets = set()
    for key, val in assoc_reader(DEFAULTS_LIST):
        if val == 'totem.desktop' and key != 'x-totem-stream':
            targets.add(key)

    if not os.path.exists(LOCAL_LIST):
        dir = os.path.dirname(LOCAL_LIST)
        if not os.path.exists(dir):
            os.makedirs(dir)
        f = file(LOCAL_LIST, 'w')
        f.write('[Added Associations]\n')
    else:
        for key, val in assoc_reader(LOCAL_LIST):
            if key in targets:
                targets.remove(key)

        if len(targets) == 0:
            print 'Changes to your file associations have already been made.'
            sys.exit(0)

        f = file(LOCAL_LIST, 'a')

    for s in targets:
        f.write('%s=vlc.desktop\n' % s)
    f.close()

    print 'Successfully added %d file associations with VLC.' % len(targets)

if __name__ == '__main__':
    main()
