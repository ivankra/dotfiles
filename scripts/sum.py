#!/usr/bin/env python
# Sums numbers from stdin

import sys, optparse

def main():
    parser = optparse.OptionParser()
    parser.add_option('-f', '--float', dest='float', action='store_true', default=False)
    (options, args) = parser.parse_args()

    if options.float:
        result = 0.0
    else:
        result = 0

    for line_no, line in enumerate(sys.stdin):
        for field in line.split():
            try:
                if options.float:
                    result += float(field)
                else:
                    result += int(field)
            except:
                sys.stderr.write('Error at line %d: not a number - "%s"\n' % (line_no + 1, field))
                sys.exit(1)

    if options.float:
        print '%.15g' % result
    else:
        print result

if __name__ == '__main__':
    main()

