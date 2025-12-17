#!/usr/bin/env python3
import socket
import sys

s = socket.socket()
try:
    s.bind(('127.0.0.1', int(sys.argv[1])))
except:
    s.bind(('127.0.0.1', 0))
print(s.getsockname()[1])
s.close()
