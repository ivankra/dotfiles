export EDITOR=vim
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_COLLATE=C
export LESS=-FRSXi
export LESSHISTFILE=-
export PAGER=less
export QT_STYLE_OVERRIDE=adwaita

[[ -z "$PS1" || -z "$HOME" ]] && return

# Aliases {{{
alias ..='cd ..'
alias R='R --no-save --no-restore --quiet'
alias b=byobu-tmux
alias bc='bc -q'
alias cd..='cd ..'
alias cd3='cd "$(scm-root)"'
alias cp='cp -i'
alias df='df -h'
alias dokcer=docker
alias du='du -h'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias g=git
alias gdb='gdb --quiet'
alias got=git
alias grep='grep --color=auto'
alias gt=git
alias ju=jupyter-notebook
alias l='ls -l'
alias ll='ls -l -h'
alias ls='ls --color=auto --group-directories-first'
alias mv='mv -i'
alias nb=jupyter-notebook
alias nvidia-mon='nvidia-smi dmon -s pucvmet -o T'
alias octave='octave -q'
alias parallel='parallel --will-cite'
alias py3='ipython3'
alias py='ipython'
alias rm='rm -i'
alias ssh-insecure='ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ControlMaster=no'
alias susl='sort | uniq -c | sort -nr | less'
# }}}

# Paths {{{

[[ -z "$CUDA_ROOT" && -d /usr/local/cuda ]] && export CUDA_ROOT=/usr/local/cuda
[[ -z "$CUDA_PATH" && ! -z "$CUDA_ROOT" ]] && export CUDA_PATH=$CUDA_ROOT
[[ -z "$CONDA_ROOT" && -x ~/.conda/bin/conda ]] && CONDA_ROOT=~/.conda
[[ -z "$CONDA_ROOT" && -x /opt/conda/bin/conda ]] && CONDA_ROOT=/opt/conda

for _d in "$CUDA_ROOT/bin" "$CONDA_ROOT/bin" ~/.dotfiles/bin ~/.local/bin ~/.bin ~/bin; do
  if [[ -d "$_d" && ":$PATH:" != *":$_d:"* ]]; then
    PATH="$_d:$PATH"
  fi
done

# }}}

# History {{{
# * keep deduped in ~/history/bash.YYYYMM files
# * load last few months on startup
# * append to last history file but don't read back
# * force to re-read history: h

shopt -s cmdhist histverify histreedit

if [[ -f ~/.history ]]; then
  HISTFILE=
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
else
  if ! [[ -d ~/.history ]]; then
    mkdir -m 0700 -p ~/.history
  fi

  shopt -s histappend

  HISTFILE=~/.history/bash."$(date +%Y%m)"
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
  HISTFILESIZE=-1
  HISTTIMEFORMAT='[%F %T] '

  if ! [[ -f "$HISTFILE" ]]; then
    touch "$HISTFILE"
    chmod 0600 "$HISTFILE"
  fi

  if [[ -x ~/.dotfiles/bin/erasedups.py && -x /usr/bin/python ]]; then
    history -c

    for _i in 6 5 4 3 2 1; do
      _d="$(date -d "-$_i month" +%Y%m)"
      if [[ -f ~/.history/"bash.$_d" ]]; then
        if [[ -w ~/.history/"bash.$_d" ]]; then
          ~/.dotfiles/bin/erasedups.py -q ~/.history/"bash.$_d"
          chmod 0400 ~/.history/"bash.$_d"
        fi
        history -r ~/.history/"bash.$_d"
      fi
    done

    ~/.dotfiles/bin/erasedups.py -q "$HISTFILE"

    # Re-read history to synchronize with other shell instances
    # Also fix background color guess
    h() {
      history -a
      ~/.dotfiles/bin/erasedups.py -q "$HISTFILE"
      history -c
      local _d
      local _i
      for _i in 6 5 4 3 2 1; do
        _d="$(date -d "-$_i month" +%Y%m)"
        if [[ -f ~/.history/"bash.$_d" ]]; then
          history -r ~/.history/"bash.$_d"
        fi
      done
      history -r
      hash -r
      __guess_colorfgbg
    }

    __prompt_history() { history -a; }
  else
    # Fallback
    h() { history -a; history -c; history -r; hash -r; }
    __prompt_history() { history -a; }
  fi
fi

unset _i _d
# }}}

# Prompt setup functions {{{

# For use in PROMPT_COMMAND: print last command's exit code if non zero.
__prompt_print_status() {
  local __status=$?
  if [[ $__status -ne 0 ]]; then
    echo -e "\033[31m\$? = ${__status}\033[m"
  fi
}

# Parameter: PS1_COLOR.
__setup_ps1() {
  # set variable identifying the chroot you work in (used in the prompt below)
  if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
  fi

  if [[ -z "$PS1_COLOR" ]]; then
    if [[ $UID == 0 ]]; then
      PS1_COLOR=31
    elif cat /proc/cpuinfo /proc/1/cgroup 2>/dev/null | grep -v /init.scope | egrep -q "(pids:/.|hypervisor)"; then
      PS1_COLOR=36
    else
      PS1_COLOR=32
    fi
  fi

  if [[ "$TERM" == "dumb" ]]; then
    PS1='\u@\h:\w\$ '
  else
    if ((PS1_COLOR < 0)); then  # 256 colors
      PS1_COLOR=$((-PS1_COLOR))
      PS1_COLOR="38;5;${PS1_COLOR}"
    fi
    PS1="\[\033[01;${PS1_COLOR}m\]\u@${PS1_HOST:-\h}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]"  # user@host:workdir
    if declare -f -F __git_ps1 >/dev/null; then
      PS1+='\[\033[35m\]$(__git_ps1)\[\033[00m\]'
    fi
    PS1+='\$ '
  fi

  # If this is an xterm set the title to user@host:dir
  if [[ "$TERM" == xterm* || "$TERM" == rxvt* ]]; then
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  fi

  unset PS1_COLOR
  unset PS1_HOST
}

__setup_prompt_command() {
  [[ ";$PROMPT_COMMAND;" == *__prompt_print_status* ]] && return

  declare -f -F __prompt_history >/dev/null 2>&1 &&
    PROMPT_COMMAND="__prompt_history;$PROMPT_COMMAND"

  # Has to be the first thing in PROMPT_COMMAND to get correct $?
  PROMPT_COMMAND="__prompt_print_status;$PROMPT_COMMAND"
}

unset PROMPT_COMMAND

# }}}

# __guess_colorfgbg {{{
# Automatically determine terminal's background color and set rxvt's var for vim
function __guess_colorfgbg() {
  if [[ -n "$COLORFGBG" && -z "$COLORBG_GUESS" ]]; then
    # rxvt like
    return
  fi

  unset COLORBG_GUESS
  if [[ "$TERM" == "linux" ||
        "$TERM" == "screen.linux" ||
        "$TERM" == "cygwin" ||
        "$TERM" == "putty" ||
        -n "$GUAKE_TAB_UUID" ||      # guake
        -n "$PYXTERM_DIMENSIONS" ||  # jupyterlab
        -n "$CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES"  # ssh applet
       ]]; then
    export COLORBG_GUESS="dark"
  else
    local prev_stty="$(stty -g)"
    stty raw -echo min 0 time 0
    printf "\033]11;?\033\\"

    # sometimes terminal can be slow to respond
    local response=""
    local i=0
    while ((i < 15)); do
      if [[ "$i" -le 10 ]]; then
        sleep 0.01
      else
        sleep 0.1
      fi
      read -r response
      if [[ "$response" != "" ]]; then
        break
      fi
      i=$((i + 1))
    done
    stty "$prev_stty"

    if [[ "$response" == *rgb:[0-8]* ]]; then
      export COLORBG_GUESS="dark"
    else
      export COLORBG_GUESS="light"
    fi
  fi

  if [[ "$COLORBG_GUESS" == "dark" ]]; then
    export COLORFGBG="15;default;0"
  elif [[ "$COLORBG_GUESS" == "light" ]]; then
    export COLORFGBG="0;default;15"
  else
    unset COLORFGBG
  fi
}

__guess_colorfgbg
# }}}

if [[ $UID == 0 ]]; then
  umask 027
fi

shopt -s autocd checkhash checkwinsize

# Fix for 'Could not add identity "~/.ssh/id_ed25519": communication with agent failed'
if [[ -x /usr/bin/keychain && -f ~/.ssh/id_ed25519 ]]; then
  eval $(/usr/bin/keychain --eval -Q --quiet --agents ssh)
fi

if [[ -n "$VTE_VERSION" ]]; then
  if [[ -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
  elif [[ -f /etc/profile.d/vte-2.91.sh ]]; then
    source /etc/profile.d/vte-2.91.sh
  fi
fi

[[ -f /usr/share/bash-completion/bash_completion ]] &&
  source /usr/share/bash-completion/bash_completion

if ! [[ -d ~/.ssh/socket ]]; then
  mkdir -p ~/.ssh/socket >/dev/null 2>&1
  chmod 0700 ~/.ssh ~/.ssh/socket >/dev/null 2>&1
fi

if [[ -f ~/.ws/bashrc ]]; then
  source ~/.ws/bashrc
fi
if [[ -f ~/.bashrc.local && ! ~/.ws/bashrc -ef ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

declare -f -F __setup_prompt_command >/dev/null 2>&1 && __setup_prompt_command
declare -f -F __setup_ps1 >/dev/null 2>&1 && __setup_ps1
unset __setup_prompt_command
unset __setup_ps1

if [[ ! -z "$CONDA_ROOT" && -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]]; then
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
fi

for _f in \
  ~/.python_history \
  ~/.sqlite_history \
  ~/.wget-hsts \
  ~/.xsel.log \
  ~/.xsession-errors \
  ~/.xsession-errors.old; do
  if [[ -f "$_f" ]]; then
    rm -f "$_f"
  fi
done
unset _f
