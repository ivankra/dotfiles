#!/usr/bin/env python3
# Erases duplicates from command line history files with timestamps.

import argparse
import datetime
import fcntl
import os
import re
import sys

TIMESTAMP_RE = re.compile(b"^# *[0-9]+$")


def process_file(filename):
    if not os.path.exists(filename):
        return
    if os.path.islink(filename):
        filename = os.readlink(filename)

    # One run at a time: shells started together would write the same .tmp
    lock_path = os.path.join(os.path.dirname(filename), ".erasedups.lock")
    with open(lock_path, "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # released on close

        # Kept open past the rename: shells append without locking, and late
        # appends to the old file are copied over.
        with open(filename, "rb") as f:
            data = f.read()

            # Dedup up to the last timestamp: that entry may still be being
            # written, so it's copied as is, with anything appended since.
            end = pos = 0
            for line in data.splitlines(True):
                if TIMESTAMP_RE.match(line):
                    end = pos
                pos += len(line)

            hashmap = dict()
            history = []
            ts = None
            entry = []
            for line in data[:end].splitlines(True) + [None]:
                if line is not None and not TIMESTAMP_RE.match(line):
                    entry.append(line)
                    continue
                if entry:
                    if ts is None:
                        raise Exception("Need history file with timestamps")
                    e = tuple(entry)
                    hashmap[e] = len(history)
                    history.append((ts, e))
                    entry = []
                ts = line

            if len(history) == len(hashmap):
                return

            with open(filename + ".tmp", "wb") as out:
                for i, (ts, entry) in enumerate(history):
                    if hashmap[entry] == i:
                        out.write(ts)
                        out.writelines(entry)
                out.write(data[end:])
                out.write(f.read())  # appended since our read

            os.chmod(filename + ".tmp", os.fstat(f.fileno()).st_mode & 0o777)
            os.rename(filename + ".tmp", filename)
            rest = f.read()  # appended to the old file during the rename
            if rest:
                with open(filename, "ab") as out:
                    out.write(rest)


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

    # Dedup still writeable older history files and mark them read-only, but
    # last month's only from the month after: shells started then may still
    # append to it (HISTFILE is set at startup and by h).
    for path in sorted(set(expanded)):
        if path == current_path:
            continue
        mode = 0o600 if path == expanded[1] else 0o400
        try:
            st = os.stat(path)
        except:
            continue
        if st.st_mode & 0o222:
            try:
                process_file(path)
                os.chmod(path, mode)
            except:
                pass
        print(path)

    if not os.path.exists(current_path):
        try:
            # 'a': another shell may have just created it, don't truncate
            with open(current_path, 'a') as fp:
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
