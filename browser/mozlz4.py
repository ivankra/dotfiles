#!/usr/bin/env python3
# Decompress firefox's search.json.mozlz4 files and similar

import sys

try:
    from lz4.block import compress as lz4_compress
    from lz4.block import decompress as lz4_decompress
except:
    raise Exception('Error: lz4 python module missing. Install python3-lz4')

def mozlz4_decompress(data):
    if len(data) < 8 or data[:8] != b'mozLz40\0':
        raise Exception('Invalid mozlz4 header')
    return lz4_decompress(data[8:])

def mozlz4_compress(data):
    return b'mozLz40\0' + lz4_compress(data)

def main():
    data = sys.stdin.buffer.read()
    if '-d' in sys.argv:
        data = mozlz4_decompress(data)
    else:
        data = mozlz4_compress(data)
    sys.stdout.buffer.write(data)

if __name__ == '__main__':
    main()
