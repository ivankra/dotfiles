#!/usr/bin/env python3
# Erases duplicates from command line history files with timestamps.

import argparse
import datetime
import os
import re
import sys

TIMESTAMP_RE = re.compile("^# *[0-9]+$")


def process_file(filename, quiet=False):
    hashmap = dict()
    history = []
    ts = None
    entry = []

    def add():
        if len(entry) > 0:
            if ts is None:
                if quiet:
                    sys.exit(0)
                sys.stderr.write("Error: need history file with timestamps\n")
                sys.exit(1)
            e = tuple(entry)
            hashmap[e] = len(history)
            history.append((ts, e))

    if filename:
        if not os.path.exists(filename):
            return
        if os.path.islink(filename):
            filename = os.readlink(filename)
        f = open(filename, "r")
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
                f = open(filename + ".tmp", "w")
            except IOError:
                sys.exit(0)
        else:
            f = open(filename + ".tmp", "w")
    else:
        f = sys.stdout

    for i, (ts, entry) in enumerate(history):
        if hashmap[entry] == i:
            f.write(ts)
            for l in entry:
                f.write(l)

    f.close()

    if filename:
        os.rename(filename + ".tmp", filename)


def process_for_bashrc(pattern):
    today = datetime.date.today()
    Y, m = today.year, today.month
    expanded = []

    for i in range(12):
        expanded.append(pattern.replace("%Y", str(Y)).replace("%m", "%02d" % m))
        m -= 1
        if m == 0:
            Y -= 1
            m = 12

    current_path = expanded[0]

    for path in sorted(set(expanded)):
        if path == current_path:
            continue
        try:
            st = os.stat(path)
        except:
            continue
        if st.st_mode & 0222:
            process_file(path, quiet=True)
            os.chmod(path, 0600)
        print(path)

    try:
        st = os.stat(current_path)
    except FileNotFoundError:
        try:
            with open(current_path, 'w+') as fp:
                pass
            st = os.stat(current_path)
        except:
            st = None

    if st:
        if (st.st_mode & 0777) != 0600:
            os.chmod(current_path, 0600)
        process_file(current_path, quiet=True)

    histdir = os.path.dirname(current_path)
    try:
        st = os.stat(histdir)
        if (st.st_mode & 0777) != 0700:
            os.chmod(histdir, 0700)
    except FileNotFoundError:
        pass

    print(current_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-q", "--quiet", help="be quiet", action="store_true")
    parser.add_argument("--bashrc", action="store_true", help="Logic for bashrc")
    parser.add_argument("filename", nargs="?")
    args = parser.parse_args()

    processed_filename = set()

    if args.bashrc:
        process_for_bashrc(args.filename)
    else:
        process_file(args.filename, args.quiet)


if __name__ == "__main__":
    main()
