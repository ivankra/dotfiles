#!/usr/bin/env python
import os, sys

if len(sys.argv) != 2:
    sys.stderr.write('Usage: x11tunnel-run.py <machine>\n')
    sys.exit(1)

home = os.environ['HOME']
machine = sys.argv[1]

cmd = """socat 'exec:"ssh %(machine)s %(home)s/git/configs/scripts/x11tunnel.py -m /tmp/.X11-unix/X42"' 'EXEC:git/configs/scripts/x11tunnel.py -d /tmp/.X11-unix/X0'""" % locals()
sys.stderr.write(cmd + '\n')

os.system(cmd)
