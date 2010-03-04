#!/usr/bin/env python
import os, sys

home = os.environ['HOME']

machine = None
if len(sys.argv) > 1:
    machine = sys.argv[1]
else:
    machine = file('/etc/x11tunnel.machine', 'r').readline().strip()

cmd = """socat 'exec:"ssh """ + machine + ' ' + home + """/git/configs/scripts/x11tunnel.py -m /tmp/.X11-unix/X42"' 'EXEC:""" + home + """/git/configs/scripts/x11tunnel.py -d /tmp/.X11-unix/X0'"""
sys.stderr.write(cmd + '\n')
os.system(cmd)
