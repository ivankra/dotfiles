if [ -z "$USER" ]; then export USER=$(whoami); fi
if [ -z "$HOME" ]; then export HOME=/home/$USER; fi
if [ -z "$HOSTNAME" ]; then export HOSTNAME=$(hostname); fi

export PATH=$HOME/git/configs/scripts:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:$PATH

if [ -d "/Berkanavt" -o -d "/hol" ]; then
  export LANG=en_US.UTF-8
  export TMPDIR=/var/tmp
  export CVSROOT=tree.yandex.ru:/opt/CVSROOT
  export DEF_MR_SERVER=sdf200:8013
  LOCAL=$HOME/.local
  export PATH=$HOME/git/ya/bin:$HOME/git/configs/scripts:$LOCAL/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/Berkanavt/bin
  if [ "$(uname)" = "FreeBSD" ]; then
    export PKG_CONFIG_PATH=$LOCAL/lib/pkgconfig:$LOCAL/share/pkgconfig
    export CPATH=$LOCAL/include
    export LIBRARY_PATH=$LOCAL/lib
    export LD_LIBRARY_PATH=$LOCAL/lib
    if [ -x /usr/local/bin/gdb66 ]; then
      alias gdb=/usr/local/bin/gdb66
    fi
  fi
  if [ -z "$DISPLAY" ] && [ -e "/tmp/.X11-unix/X42" ]; then export DISPLAY=:42; fi
  if [ "$HOSTNAME" = "dagobah" ]; then
    PS1COL=32;  # green, home
  elif [ "$(uname)" = "FreeBSD" ]; then
    PS1COL=31;  # red, bsd
  else
    PS1COL=35;  # purple, linux
  fi
fi

# quit now if not running interactively
[ -z "$PS1" ] && return

export PAGER=less
export EDITOR=vim
export SVN_EDITOR=vim

export LESSHISTFILE="-"

# History control: do not write to disk, ignore all dups
export HISTFILE=
export HISTCONTROL=ignoreboth

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

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
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
    ;;
*)
    ;;
esac

if [ "$(uname)" = "FreeBSD" ]; then
  alias ls='/bin/ls -G'
  alias free='vmstat'
elif [ "$TERM" != "dumb" ]; then
  #eval "`dircolors -b`"
  LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.svgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:';
  export LS_COLORS
  alias ls='ls --color=auto'
fi

alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias bc='bc -q'
alias du='du -h'
alias df='df -h'
alias bc='bc -q'
alias ssh='ssh -AX'
alias gdb='gdb --quiet'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
#alias gvim='gvim 2>>~/.xsession-errors'

if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

if [ -f ~/.gdb_history ]; then
  chmod 0600 ~/.gdb_history
fi
