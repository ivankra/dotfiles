# If not running interactively, don't do anything
[ -z "$PS1" ] && return

if [ -z "$HOME" ]; then
  export HOME=/home/$(whoami);
fi

export PATH=$HOME/git/configs/scripts:$PATH
if [ -d $HOME/bin ]; then
  export PATH=$HOME/bin:$PATH
fi

export EDITOR=vim
export PAGER=less
export LESSHISTFILE=-

__git_ps1 () { return; }

# work environment
if [ -d /Berkanavt -o -d /hol ]; then
  source ~/git/configs/bashrc-arc
fi

# History control: do not write to disk, ignore all duplicates and commands starting with space
HISTFILE=
HISTCONTROL=ignoreboth
HISTSIZE=1000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

if [ "$TERM" != "dumb" ]; then
  if [ -z "$PS1COL" ]; then
    PS1COL=32
  fi
  PS1='${debian_chroot:+($debian_chroot)}'
  #PS1+='\[\033[36m\]\A '  # time
  PS1+='\[\033[01;${PS1COL}m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'  # user@host:workdir
  PS1+='\[\033[35m\]$(__git_ps1)\[\033[00m\]'  # git branch
  PS1+='\$ '
else
  PS1='\u@\h:\w\$ '
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

if [ "$(uname)" = "FreeBSD" ]; then
  alias ls='/bin/ls -G'
  alias free='vmstat'
else
  # enable color support of ls
  if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
  fi
  alias l='ls -CF'
  alias la='ls -A'
fi

alias ll='ls -l'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias bc='bc -q'
alias gdb='gdb --quiet'
alias ssh='ssh -AX'
alias R='R --no-save --no-restore --quiet'

if [ -f ~/.gdb_history ]; then
  chmod 0600 ~/.gdb_history
fi

if [[ ! -d /cygdrive ]]; then
  if [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
  elif [[ -f ~/git/configs/bash-completion-git ]]; then
    . ~/git/configs/bash-completion-git
  fi
fi
