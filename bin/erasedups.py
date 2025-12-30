#!/usr/bin/env python3
# Erases duplicates from command line history files with timestamps.

import argparse
import datetime
import os
import re
import sys

TIMESTAMP_RE = re.compile("^# *[0-9]+$")


def process_file(filename):
    if not os.path.exists(filename):
        return
    if os.path.islink(filename):
        filename = os.readlink(filename)
    f = open(filename, "r")

    f_iter = iter(f)
    hashmap = dict()
    history = []
    ts = None
    entry = []

    while True:
        line = next(f_iter, None)
        if line is not None and not TIMESTAMP_RE.match(line):
            entry.append(line)
            continue

        if len(entry) > 0:
            if ts is None:
                raise Exception("Need history file with timestamps")
            e = tuple(entry)
            hashmap[e] = len(history)
            history.append((ts, e))
            entry = []

        ts = line
        if line is None:
            break

    if len(history) == len(hashmap):
        return

    with open(filename + ".tmp", "w") as f:
        for i, (ts, entry) in enumerate(history):
            if hashmap[entry] == i:
                f.write(ts)
                for l in entry:
                    f.write(l)
        f.flush()

    os.rename(filename + ".tmp", filename)


def process_pattern(pattern, N=12):
    today = datetime.date.today()
    Y, m = today.year, today.month
    expanded = []

    for i in range(N):
        expanded.append(pattern.replace("%Y", str(Y)).replace("%m", "%02d" % m))
        m -= 1
        if m == 0:
            Y -= 1
            m = 12

    current_path = expanded[0]

    # Create history directory / fix its permissions
    histdir = os.path.dirname(current_path)
    try:
        if not os.path.exists(histdir):
            os.mkdir(histdir, mode=0o700)
        st = os.stat(histdir)
        if (st.st_mode & 0o777) != 0o700:
            os.chmod(histdir, 0o700)
    except:
        pass

    # Dedup still writeable older history files and mark them read-only
    for path in sorted(set(expanded)):
        if path == current_path:
            continue
        try:
            st = os.stat(path)
        except:
            continue
        if st.st_mode & 0o222:
            try:
                process_file(path)
                os.chmod(path, 0o600)
            except:
                pass
        print(path)

    if not os.path.exists(current_path):
        try:
            with open(current_path, 'w+') as fp:
                pass
        except:
            pass

    # Dedup current month's history file
    try:
        st = os.stat(current_path)
        if (st.st_mode & 0o777) != 0o600:
            os.chmod(current_path, 0o600)
        process_file(current_path)
    except:
        pass

    print(current_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--expand", type=int, metavar="N",
        help="Expand date placeholders with last 12 months, dedup and print filenames")
    parser.add_argument("filename")
    args = parser.parse_args()

    processed_filename = set()

    if args.expand:
        process_pattern(args.filename, args.expand)
    else:
        process_file(args.filename)


if __name__ == "__main__":
    main()
