import os
import re
import sys

sys.path.append(os.path.expanduser('~/.dotfiles/python'))
import dotfiles.dracula

def parent_process_cmdline_matches(pattern):
    pid = os.getpid()
    for i in range(10):
        try:
            pid = int(open('/proc/%d/stat' % pid).read().split()[3])
            cmdline = open('/proc/%d/cmdline' % pid).read().replace('\0', ' ')
        except:
            break
        if re.match(pattern, cmdline):
            return True
    return False

# Use a good legible dark theme if running under Guake
dark = (os.environ.get('COLORFGBG', '').endswith(';0') or
        os.environ.get('GUAKE_TAB_UUID', '') != '' or
        parent_process_cmdline_matches('.*guake.*'))

if dark:
    dotfiles.dracula.set_ipython(c)
else:
    from pygments.token import Name
    c.TerminalInteractiveShell.colors = 'lightbg'
    c.TerminalInteractiveShell.highlighting_style = 'manni'
    c.TerminalInteractiveShell.highlighting_style_overrides = {
        Name.Namespace: 'bold #00ABD6',
    }

c.TerminalInteractiveShell.confirm_exit = False
c.TerminalInteractiveShell.banner1 = ''
c.TerminalInteractiveShell.banner2 = ''
c.TerminalIPythonApp.display_banner = False
