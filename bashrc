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

# work environment
if [ -d "/Berkanavt" -o -d "/hol" ]; then
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  export TMPDIR=/var/tmp
  export CVSROOT=tree.yandex.ru:/opt/CVSROOT
  export DEF_MR_SERVER=sdf200:8013
  export PATH=$HOME/git/ya/scripts:$PATH:/Berkanavt/bin
  if [ "$(uname)" = "FreeBSD" ]; then
    LOCAL=$HOME/.local
    export PATH=$LOCAL/bin:$PATH
    export PKG_CONFIG_PATH=$LOCAL/lib/pkgconfig:$LOCAL/share/pkgconfig
    export CPATH=$LOCAL/include
    export LIBRARY_PATH=$LOCAL/lib
    export LD_LIBRARY_PATH=$LOCAL/lib
    if [ which gdb66 >/dev/null 2>/dev/null ]; then
      alias gdb=/usr/local/bin/gdb66
    fi
    if [ which g++44 >/dev/null 2>/dev/null ]; then
      export CC=$(which gcc44)
      export CXX=$(which g++44)
    fi
    export DISPLAY=:42
  fi
  if [ "$(hostname)" = "dagobah" ]; then
    PS1COL=32;  # green, home
  elif [ "$(uname)" = "FreeBSD" ]; then
    PS1COL=31;  # red, bsd
  else
    PS1COL=35;  # purple, linux
  fi
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
  PS1="${debian_chroot:+($debian_chroot)}\[\033[01;${PS1COL}m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ "
else
  PS1='\u@\h:\w\\$ '
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

if [ -f ~/.gdb_history ]; then
  chmod 0600 ~/.gdb_history
fi

if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi
