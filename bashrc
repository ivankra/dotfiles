[[ -z "$PS1" || -z "$HOME" ]] && return

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_COLLATE=C
export EDITOR=vim
export PAGER=less
export LESS=-FRSXi
export LESSHISTFILE=-

alias ls='ls --color=auto --group-directories-first'
alias l='ls -l'
alias ll='ls -l -h'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias df='df -h'
alias du='du -h'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias cd3='cd "$(scm-root)"'
alias cd..='cd ..'
alias ..='cd ..'
alias susl='sort | uniq -c | sort -nr | less'
alias nb='jupyter-notebook'
alias py='ipython'
alias py3='ipython3'
alias bc='bc -q'
alias gdb='gdb --quiet'
alias R='R --no-save --no-restore --quiet'
alias octave='octave -q'
alias parallel='parallel --will-cite'
alias b=byobu-tmux
alias g=git
alias got=git
alias nvidia-mon='nvidia-smi dmon -s pucvmet -o T'

if [[ -d ~/.ws/docker ]] && ls ~/.ws/docker/*/run.sh >/dev/null 2>&1; then
  for __d in $(ls ~/.ws/docker); do
    if [[ -x "$HOME/.ws/docker/$__d/run.sh" ]]; then
      alias "docker-$__d"="$HOME/.ws/docker/$__d/run.sh"
    fi
  done
else
  for __d in $(ls ~/.dotfiles/docker); do
    if [[ -x "$HOME/.dotfiles/docker/$__d/run.sh" ]]; then
      alias "docker-$__d"="$HOME/.dotfiles/docker/$__d/run.sh"
    fi
  done
fi

# Paths
[[ -z "$CUDA_ROOT" && -d /usr/local/cuda ]] && export CUDA_ROOT=/usr/local/cuda
[[ -z "$CUDA_PATH" && ! -z "$CUDA_ROOT" ]] && export CUDA_PATH=$CUDA_ROOT
[[ -z "$CONDA_ROOT" && -x ~/.conda/bin/conda ]] && CONDA_ROOT=~/.conda
[[ -z "$CONDA_ROOT" && -x /opt/conda/bin/conda ]] && CONDA_ROOT=/opt/conda

for __d in "$CUDA_ROOT/bin" "$CONDA_ROOT/bin" ~/.dotfiles*/bin ~/.local/bin ~/.bin ~/bin; do
  [[ -d "$__d" && ":$PATH:" != *":$__d:"* ]] && PATH="$__d:$PATH"
done

unset __d

# History
if [[ -f "$HOME/.history" ]]; then
  HISTFILE=
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
else
  [[ -d "$HOME/.history" ]] || mkdir -m 0700 -p "$HOME/.history"
  shopt -s histappend
  HISTFILE="$HOME/.history/bash.$(date +%Y%m)"
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
  HISTFILESIZE=-1
  HISTTIMEFORMAT='[%F %T] '

  if [[ -x "$HOME/.dotfiles/bin/erasedups.py" ]]; then
    "$HOME/.dotfiles/bin/erasedups.py" -q "$HISTFILE"
    h() { history -a; "$HOME/.dotfiles/bin/erasedups.py" -q "$HISTFILE"; history -c; history -r; }
    __prompt_history() { history -a; }
  else
    h() { history -a; history -c; history -r; }
    __prompt_history() { history -a; }
  fi
fi

shopt -s autocd cmdhist checkhash checkwinsize histverify histreedit

# Fix for 'Could not add identity "~/.ssh/id_ed25519": communication with agent failed'
if [[ -x /usr/bin/keychain && -f ~/.ssh/id_ed25519 ]]; then
  eval $(/usr/bin/keychain --eval -Q --quiet --agents ssh)
fi

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

if [[ -n "$VTE_VERSION" ]]; then
  if [[ -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
  elif [[ -f /etc/profile.d/vte-2.91.sh ]]; then
    source /etc/profile.d/vte-2.91.sh
  fi
fi

[[ -f /usr/share/bash-completion/bash_completion ]] &&
  source /usr/share/bash-completion/bash_completion

if ! [[ -d ~/.ssh/control ]]; then
  mkdir -p ~/.ssh/control >/dev/null 2>&1
  chmod 0700 ~/.ssh ~/.ssh/control >/dev/null 2>&1
fi

[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

declare -f -F __setup_prompt_command >/dev/null 2>&1 && __setup_prompt_command
declare -f -F __setup_ps1 >/dev/null 2>&1 && __setup_ps1
unset __setup_prompt_command
unset __setup_ps1

if [[ ! -z "$CONDA_ROOT" && -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]]; then
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
fi
