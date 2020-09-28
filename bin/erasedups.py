#!/usr/bin/env python3
# Erases duplicates from command line history files with timestamps.

import argparse
import os
import re
import sys

TIMESTAMP_RE = re.compile('^# *[0-9]+$')


def Process(filename, quiet=False):
  hashmap = dict()
  history = []
  ts = None
  entry = []

  def add():
    if len(entry) > 0:
      if ts is None:
        if quiet:
          sys.exit(0)
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
    if quiet:
      try:
        f = open(filename + '.tmp', 'w')
      except IOError:
        sys.exit(0)
    else:
      f = open(filename + '.tmp', 'w')
  else:
    f = sys.stdout

  for i, (ts, entry) in enumerate(history):
    if hashmap[entry] == i:
      f.write(ts)
      for l in entry: f.write(l)

  f.close()

  if filename:
    os.rename(filename + '.tmp', filename)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('-q', '--quiet', help='be quiet', action='store_true')
  parser.add_argument('filename', nargs='?')
  args = parser.parse_args()
  Process(args.filename, args.quiet)


if __name__ == '__main__':
  main()
