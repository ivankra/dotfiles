#!/usr/bin/env python
# Filters svn log output for usernames matching a given regex
# ./svn-log-for-user.py -u username [-o] [-v] [svn+ssh://foo/bar]
import os, re, sys, subprocess, optparse

def parse_svn_log(input_file):
    res = None
    separator = '-' * 72

    regex = re.compile(r'^r([0-9]+) \| ([^|]+) \| ([^|]+) \| ([^|]+)$')

    for line in input_file:
        line = line.rstrip()

        if line == separator:
            if res is not None:
                yield res
                res = None
            continue

        if len(line) == 0:
            continue

        if res is None:
            match = regex.match(line)
            if match is None:
                sys.stderr.write('Failed to this line of svn log: %s\n' % line)
                return

            res = dict(
                    revision=int(match.group(1)),
                    username=match.group(2),
                    date=match.group(3),
                    other=match.group(4),
                    message=[])
        else:
            res['message'].append(line)

    if res is not None:
        yield res


def doit(input_file, output_file, options):
    username_regex = re.compile(options.username)
    sep = '-' * 72 + '\n'

    for commit in parse_svn_log(input_file):
        if username_regex.match(commit['username']) is None:
            continue

        if options.oneline:
            if len(commit['message']) == 0:
                commit['message'].append('(no message)')
            output_file.write('r%s | %s | %s | %s\n' % (commit['revision'], commit['username'], commit['date'][:10], commit['message'][0]))
        else:
            output_file.write(sep)
            output_file.write('r%s | %s | %s | %s\n' % (commit['revision'], commit['username'], commit['date'], commit['other']))
            for l in commit['message']:
                output_file.write(l + '\n')
    if not options.oneline:
        output_file.write(sep)


def main():
    parser = optparse.OptionParser(usage='%prog -u <username> [options] [-v] [svn repository URL]')
    parser.add_option('-u', '--user', dest='username', default='', help='username regex')
    parser.add_option('-o', '--oneline', action='store_true', dest='oneline', help='print jsut the first line of a commit message')
    parser.add_option('-v', action='store_true', dest='svn_verbose', help='invoke svn log -v')
    (options, args) = parser.parse_args()

    if options.username == '':
        parser.print_help()
        return

    if len(args) == 0:
        if os.isatty(0):
            print 'You should either pass an svn repository URL as a command line argument or use this script to filter the output of svn log.'
            return

        inf = sys.stdin
        outf = sys.stdout

    else:
        extra_args = ''
        if options.svn_verbose:
            extra_args = '-v'
        inf = subprocess.Popen("svn log %s --non-interactive '%s'" % (extra_args, args[0]), shell=True, stdout=subprocess.PIPE).stdout
        outf = sys.stdout

    doit(inf, outf, options)


if __name__ == '__main__':
    main()
