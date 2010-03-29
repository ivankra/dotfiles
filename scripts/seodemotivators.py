#!/usr/bin/env python
# Checks seodemotivator's rss feed for new pictures and downloads them to a specified file.
# You can use this script to automatically update your wallpaper.
import os, re, sys, urllib2, optparse, time, traceback

last_url = None

def check(url, filename):
    global last_url

    dir = os.path.dirname(filename)
    if not os.path.exists(dir):
        os.makedirs(dir)

    feed = urllib2.urlopen(url).read()
    matches = re.findall('<img .*?title="([^"]*)" src="([^"]*)"', feed)

    if len(matches) == 0:
        sys.stderr.write('Failed to find a picture URL at %s' % url)
        return

    title, pic_url = matches[0]
    if pic_url == last_url:
        return

    sys.stderr.write('New picture: %s (%s)\n' % (pic_url, title))

    data = urllib2.urlopen(pic_url).read()
    file(filename, 'wb').write(data)

    last_url = pic_url

def main(argv):
    parser = optparse.OptionParser(usage='%prog [options]')
    parser.add_option('-i', '--interval', dest='interval', default=3600,
        help='Number of seconds between feed downloads. Enter 0 to check the feed just once at start.')
    parser.add_option('-f', '--file', dest='filename',
        help='Where to store the new picture.  (default: ~/.local/share/backgrounds/seodemotivators.jpg)',
        default='~/.local/share/backgrounds/seodemotivators.jpg')
    parser.add_option('-u', '--url', dest='url', help='Feed\'s url.',
        default='http://seodemotivators.ru/?feed=rss2')
    (options, args) = parser.parse_args()

    options.filename = os.path.expanduser(os.path.expandvars(options.filename))

    while True:
        try:
            check(options.url, options.filename)
        except:
            traceback.print_exc()

        i = float(options.interval)
        if i <= 0:
            break
        time.sleep(i)

if __name__ == '__main__':
    main(sys.argv)
