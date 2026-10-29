#!/bin/bash
# Entrypoint: runs the agent as a job of an interactive bash. An agent that
# suspends itself on ctrl+z (Claude Code does) would otherwise hang the session
# for good, with no shell to `fg` it from; here ctrl+z lands at a prompt.
# If the agent exits without having been suspended, so does the shell.

# Re-run this file as the rcfile of an interactive bash.
if [[ $- != *i* ]]; then
    [ -t 0 ] || exec "$@"
    exec bash --rcfile "$0" -is -- "$@"
fi

[ -f ~/.bashrc ] && . ~/.bashrc
# Bash only turns job control on after the rcfile, though $- already shows m.
set -m
"$@"
s=$?
[ -n "$(jobs -s)" ] || exit $s
