#!/usr/bin/env python
# Erases duplicates from command line history files with timestamps.
# Usage:
#   erasedups [<history files>]
#   or: erasedups <input >output

import os
import re
import sys

TIMESTAMP_RE = re.compile('^# *[0-9]+$')


def Process(filename):
  hashmap = dict()
  history = []
  ts = None
  entry = []

  def add():
    if len(entry) > 0:
      if ts is None:
        sys.stderr.write('Error: need history file with timestamps\n')
        sys.exit(1)
      e = tuple(entry)
      hashmap[e] = len(history)
      history.append((ts, e))

  if filename:
    if not os.path.exists(filename):
      return
    if os.path.islink(filename):
      filename = os.readlink(filename)
    f = open(filename, 'r')
  else:
    f = sys.stdin

  for line in f:
    if TIMESTAMP_RE.match(line):
      add()
      ts = line
      entry = []
    else:
      entry.append(line)

  add()
  f.close()

  if len(history) == len(hashmap) and filename:
    return

  if filename:
    try:
      f = open(filename + '.tmp', 'w')
    except IOError:
      return
  else:
    f = sys.stdout

  for i, (ts, entry) in enumerate(history):
    if hashmap[entry] == i:
      f.write(ts)
      for l in entry: f.write(l)

  f.close()

  if filename:
    os.rename(filename + '.tmp', filename)


if len(sys.argv) > 1:
  for filename in sys.argv[1:]:
    Process(filename)
else:
  Process(None)
