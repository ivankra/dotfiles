#!/bin/bash
# Note: this file is also sourced from ~/.profile by non-bash shells

export EDITOR=vim
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_COLLATE=C
export LESS=-FRSXi
export LESSHISTFILE=-
export PAGER=less
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# Paths {{{

if [ -z "$CUDA_ROOT$CUDA_PATH" ] && [ -d /usr/local/cuda ]; then
  export CUDA_ROOT=/usr/local/cuda
  export CUDA_PATH=/usr/local/cuda
fi

if [ -z "$GOPATH" ]; then
  export GOPATH=~/.go
fi

if [ -z "$CONDA_ROOT" ]; then
  if [ -x ~/.conda/bin/conda ] && ! [ ~/.conda/bin/conda -ef /opt/conda/bin/conda ]; then
    export CONDA_ROOT=~/.conda
  elif [ -x /opt/conda/bin/conda ]; then
    export CONDA_ROOT=/opt/conda
  fi
fi

__maybe_prepend_path() {
  case :$PATH: in *:$1:*) return;; esac  # for dash
  if [ -d "$1" ]; then PATH="$1:$PATH"; fi
}

# higher priority last
__maybe_prepend_path /bin
__maybe_prepend_path /usr/bin
__maybe_prepend_path /usr/local/bin
__maybe_prepend_path "$CUDA_ROOT/bin"
__maybe_prepend_path "$CONDA_ROOT/bin"
__maybe_prepend_path "$GOPATH/bin"
__maybe_prepend_path ~/.dotfiles/bin
__maybe_prepend_path ~/.local/dotfiles/bin
__maybe_prepend_path ~/.local/bin
__maybe_prepend_path ~/.bin
__maybe_prepend_path ~/bin

# }}}

if [ -z "$BASH_VERSION" ]; then
  return
fi

if [[ -z "$PS1" || -z "$HOME" ]]; then
  # non interactive
  return
fi

shopt -s checkhash checkwinsize no_empty_cmd_completion
if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
  shopt -s autocd
fi

# Aliases {{{

alias ...='cd ...'
alias ..='cd ..'
alias R='R --no-save --no-restore --quiet'
alias b=byobu-tmux
alias bat=batcat
alias bc='bc -q'
alias cd..='cd ..'
alias cd3='cd "$(scm-root)"'
alias cp='cp -i'
alias cx='chmod a+x'
alias df='df -h'
alias diff='diff -u'
alias dokcer=docker
alias du='du -h'
alias e=egrep
alias eg=egrep
alias egrep='egrep --color=auto'
alias elapsed='echo $__PS0_ELAPSED'  # last foreground command's elapsed time in seconds
alias fgrep='fgrep --color=auto'
alias free='free -h'
alias g=grep
alias gdb='gdb --quiet'
alias got=git
alias grep='grep --color=auto'
alias gt=git
alias gti=git
alias issh='ssh -F ~/.dotfiles/ssh-config-insecure'
alias json_pp='python3 -m json.tool'
alias l='ls -l'
alias la='ls -la'
alias le='less'
alias ll='ls -l -h'
alias ls='ls --color=auto --group-directories-first'
alias mtr='mtr -bt'  # --show-ips --curses
alias mv='mv -i'
alias nb=jupyter-notebook
alias nvidia-mon='nvidia-smi dmon -s pucvmet -o T'
alias octave='octave -q'
alias parallel='parallel --will-cite'
alias py2=ipython
alias py3=ipython3
alias py=ipython3
alias rm='rm -i'
alias rsync='rsync --info=progress2'
alias rsyncp='rsync --info=progress2'
alias sqlite3='sqlite3 -header -column'
alias susl='sort | uniq -c | sort -nr | less'
alias venv='python3 -m venv'
alias virt-manager='GDK_SCALE=1 virt-manager'

__maybe_alias() {
  if ! hash "$1" >/dev/null 2>&1 && hash "$2" >/dev/null 2>&1; then
    alias "$1"="$2"
  fi
}
__maybe_alias blaze bazel
__maybe_alias python python3
__maybe_alias fd fdfind

mk() { mkdir -p "$@" && cd "$@"; }
mkd() { mkdir -p "$@" && cd "$@"; }

date() {
  local arg1=${1:--R}; shift;
  /usr/bin/date "$arg1" "$@"
}

ts() {
  if [[ "$1" == "" ]]; then
    /usr/bin/ts "%.T"
  else
    /usr/bin/ts "$@"
  fi
}
alias tsd='ts "%Y-%m-%d %.T"'

for _c in ifconfig iwconfig route; do
  if ! hash "$_c" >/dev/null 2>&1; then
    alias "$_c"=/sbin/"$_c"
  fi
done
unset _c

# }}}

# History {{{
# * keep deduped in ~/.history/bash.YYYYMM files
# * load last few months on startup
# * append to last history file but don't read back
# * force to re-read history: h

shopt -s cmdhist histverify histreedit

HISTFILE=
if ! [[ -d ~/.history ]] && ([[ -f ~/.history ]] || ! mkdir -m 0700 -p ~/.history); then
  # history disabled
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
else
  shopt -s histappend
  HISTCONTROL=ignoreboth
  HISTFILESIZE=-1
  HISTIGNORE='bg:fg:clear:ls:pwd:history:exit'
  HISTSIZE=100000
  HISTTIMEFORMAT='[%F %T] '

  # Flush history, dedup and reread recent history files
  __run_erasedup() {
    if [[ -n "$HISTFILE" ]]; then
      history -a
      history -c
    fi

    local interp=""
    if hash python2.7 >/dev/null 2>&1; then
      interp=python2.7
    elif hash python3 >/dev/null 2>&1; then
      interp=python3
    elif hash python >/dev/null 2>&1; then
      interp=python
    fi

    if [[ -n "$interp" && -f ~/.dotfiles/bin/erasedups.py ]]; then
      local histf
      for histf in $($interp ~/.dotfiles/bin/erasedups.py --expand=12 "$HOME/.history/bash.%Y%m"); do
        history -r "$histf"
        HISTFILE="$histf"    # last month last
      done
    elif [[ -n "$HISTFILE" ]]; then
      history -r
    fi
  }
  __run_erasedup

  # Re-read history to synchronize with other shell instances.
  # Also fix various terminal issues.
  h() { __run_erasedup; hash -r; __reset_colorfgbg; __fix_term_input; }

  __link_to_history() {
    local src="$1"
    local dst="$HOME/.history/$2"
    if [[ -L "$src" && ! -f "$src" ]]; then
      # broken symlink
      rm -f "$src"
    fi
    ln_sr='ln -s -r'
    if [[ "$OSTYPE" == darwin* ]]; then
      if hash gln >/dev/null 2>&1; then
        ln_sr='gln -s -r'
      else
        ln_sr='ln -s'
      fi
    fi
    if [[ -f "$src" && ! -L "$src" ]]; then
      if [[ -f "$dst" ]]; then
        cat "$dst" "$src" >>"$dst.$$" &&
          mv -f "$dst.$$" "$dst" &&
          rm -f "$src" &&
          $ln_sr "$dst" "$src"
      else
        mv "$src" "$dst" && $ln_sr "$dst" "$src"
      fi
    fi
  }
  __link_to_history ~/.julia/logs/repl_history.jl julia
  __link_to_history ~/.mysql_history mysql
  __link_to_history ~/.psql_history psql
  __link_to_history ~/.python_history python
  __link_to_history ~/.sqlite_history sqlite
  unset -f __link_to_history

  if [[ -f ~/.history/sqlite ]]; then
    export SQLITE_HISTORY=~/.history/sqlite
  fi
fi

# }}}

__BASHRC_EPILOGUE="unset __BASHRC_EPILOGUE;"

# Prompt {{{

# Fix messed up terminal input handling.
__fix_term_input() {
  stty sane cooked
  echo -en '\033]104\007\033[\041p\r'
  #echo -en '\033]104\007\033[\041p\033[?3;4l\033[4l\033>\033[?69l\r'  # full reset seq
  bind -f ~/.inputrc
}

# PROMPT_COMMAND
#
# Delayed till the end to ensure __prompt_print_status will be
# the first thing there in order to get the correct $?.
__bashrc_set_prompt_command() {
  if [[ "$PROMPT_COMMAND" != *__bashrc_prompt_command* ]]; then
    PROMPT_COMMAND="__bashrc_prompt_command;$PROMPT_COMMAND"
  fi
  unset __bashrc_set_prompt_command
}
__BASHRC_EPILOGUE+="__bashrc_set_prompt_command;"
unset PROMPT_COMMAND

__bashrc_prompt_command() {
  # Record last command's exit code, has to be first thing in PROMPT_COMMAND.
  local status=$?

  # Record elapsed time.
  local elapsedmsg=""
  if [[ -n "$__PS0_EPOCHSECONDS" ]]; then
    __PS0_ELAPSED=$(($EPOCHSECONDS - $__PS0_EPOCHSECONDS))

    if (( $__PS0_ELAPSED >= 23*3600 )); then
      elapsedmsg="Elapsed $(((__PS0_ELAPSED + 1800)/3600))h"
    fi
  fi

  # Print last command's exit code if non zero and elapsed time if large enough.
  if [[ $status -ne 0 ]]; then
    if [[ -n "$elapsedmsg" ]]; then
      echo -e "\033[31m\$? = $status  $elapsedmsg\033[m"
    else
      echo -e "\033[31m\$? = $status\033[m"
    fi
  elif [[ -n "$elapsedmsg" ]]; then
    echo -e "\033[38;5;8m$elapsedmsg\033[m"
  fi

  if [[ -n "$HISTFILE" ]]; then
    history -a
  fi

  if [[ $status -ne 0 ]]; then
    __fix_term_input
  fi
}

# PS0 (bash 4.4+)
# Expanded and displayed by interactive shells after reading a command and
# before the command is executed.
__bashrc_ps0() {
  # Update terminal title with currently running command.
  local cmd=$(HISTTIMEFORMAT= history 1 | cut -c8- | xargs -0 echo)
  if [[ -n "$USER" && -n "$HOSTNAME" && -n "$cmd" ]]; then
    echo -e "\e]0;$USER@$HOSTNAME - $cmd\a"
  fi

  # Write command to be executed to history
  if [[ -n "$HISTFILE" ]]; then
    history -a
  fi
}
PS0='$(__bashrc_ps0)'
# Record command's start time in __PS0_EPOCHSECONDS.
# Using substring expansion syntax ${parameter:offset:length} with a side effect
# to avoid getting executed in a subshell as $() and avoid printing anything.
PS0+='${$:$((__PS0_EPOCHSECONDS=$EPOCHSECONDS)):0}'

# PS1
#
# Delayed till the end to have the last say on PS1 and get definitions for
# __git_ps1 and parameters from local scripts:
#   * PS1_COLOR - user@host color:
#       30 .. 37      standard ansi colors
#       38;5;n        256 extended colors (0..255)
#       38;2;r;g;b    R/G/B (0..255)
#   * PS1_HOST - hostname to display
__bashrc_set_ps1() {
  # set variable identifying the chroot you work in (used in the prompt below)
  if [[ -z "$debian_chroot" && -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
  fi

  if [[ -z "$PS1_COLOR" ]]; then
    if [[ $UID == 0 ]]; then
      PS1_COLOR=31
    elif hash id >/dev/null 2>&1; then
      local groups=" $(id -nG) "
      if [[ "$groups" == *" sudo " && ! "$groups" == *" audio "* ]]; then
        PS1_COLOR=31
      else
        PS1_COLOR=32
      fi
    else
      PS1_COLOR=32
    fi
  fi

  if [[ "$TERM" == "dumb" ]]; then
    PS1='\u@\h:\w\$ '
  else
    PS1="\[\033[01;36m\]\A\[\033[m\] "                  # HH:MM
    PS1+="\[\033[01;${PS1_COLOR}m\]\u@${PS1_HOST:-\h}"  # user@host
    PS1+="\[\033[00m\]:"                                # :
    PS1+="\[\033[01;34m\]\w\[\033[00m\]"                # workdir
    if declare -f -F __git_ps1 >/dev/null; then
      PS1+='\[\033[35m\]$(__git_ps1)\[\033[00m\]'
    fi
    PS1+='\$ '
  fi

  # If this is an xterm set the title to user@host:dir
  if [[ "$TERM" == xterm* || "$TERM" == rxvt* ]]; then
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  fi

  if [[ -n "$VIRTUAL_ENV" ]]; then
    PS1="(${VIRTUAL_ENV##*/}) $PS1"
  fi
  if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    PS1="(${CONDA_DEFAULT_ENV}) $PS1"
  fi

  unset PS1_COLOR
  unset PS1_HOST
  unset __bashrc_set_ps1
}
__BASHRC_EPILOGUE+="__bashrc_set_ps1;"

# TODO: https://redandblack.io/blog/2020/bash-prompt-with-updating-time/
# }}}

# OS X {{{

if [[ "$OSTYPE" == darwin* ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1

  if hash gls >/dev/null 2>&1; then
    alias ls='gls --color=auto --group-directories-first'
  fi
fi

# }}}

if [[ $UID == 0 ]]; then
  umask 027
fi

if ! [[ -d ~/.ssh/socket ]]; then
  mkdir -p ~/.ssh/socket >/dev/null 2>&1
  chmod 0700 ~/.ssh ~/.ssh/socket >/dev/null 2>&1
fi

if hash bazel >/dev/null 2>&1 && [[ -d ~/.cache && ! -L ~/.cache/bazel && ! -d ~/.cache/bazel ]]; then
  ln -s /var/tmp ~/.cache/bazel
fi

if [[ -f ~/.lesshst || -f ~/.wget-hsts || -f ~/.xsel.log || -f ~/.xsession-errors || -f ~/.xsession-errors.old ]]; then
  rm -f ~/.lesshst ~/.wget-hsts ~/.xsel.log ~/.xsession-errors ~/.xsession-errors.old
fi

if [[ -z "$HIDPI" && -f "/run/user/$UID/dconf/user" ]]; then
  if [[ "$(dconf read /org/gnome/desktop/interface/scaling-factor 2>/dev/null)" == *2 ]]; then
    export HIDPI=1
  elif [[ "$(dconf read /org/gnome/desktop/interface/text-scaling-factor 2>/dev/null)" == 1.[2-9]* ]]; then
    export HIDPI=1
  else
    export HIDPI=0
  fi
fi

if [[ -f ~/.dotfiles/bin/colorfgbg ]]; then
  source ~/.dotfiles/bin/colorfgbg
fi

if [[ -z "$LS_COLORS" ]] && hash dircolors >/dev/null 2>&1; then
  eval $(dircolors ~/.dotfiles/dircolors)
fi

if [[ -n "$VTE_VERSION" ]]; then
  if [[ -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
  elif [[ -f /etc/profile.d/vte-2.91.sh ]]; then
    source /etc/profile.d/vte-2.91.sh
  fi
fi

if [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
  source /usr/share/doc/fzf/examples/completion.bash
fi

if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

if [[ -n "$CONDA_ROOT" && -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]]; then
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
fi

if [[ -f ~/.dotfiles/bashrc.local ]]; then
  source ~/.dotfiles/bashrc.local
fi

eval "$__BASHRC_EPILOGUE"
