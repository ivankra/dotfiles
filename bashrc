[[ -z "$PS1" || -z "$HOME" ]] && return

[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$PATH"
[[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="$HOME/bin:$PATH"
[[ ":$PATH:" != *":$HOME/.dotfiles/bin:"* ]] && PATH="$HOME/.dotfiles/bin:$PATH"

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_COLLATE=C
export EDITOR=vim
export PAGER=less
export LESS=-r
export LESSHISTFILE=-

if [[ -f "$HOME/.history" ]]; then
  HISTFILE=
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
else
  [[ -d "$HOME/.history" ]] || mkdir -m 0700 -p "$HOME/.history"
  shopt -s histappend
  HISTFILE="$HOME/.history/bash.$(date +%Y%m)"
  [[ "$HISTFILE" -ef "$HOME/.bash_history" ]] || \
    ln -s -f ".history/$(basename "$HISTFILE")" "$HOME/.bash_history"
  HISTCONTROL=ignoreboth
  HISTSIZE=100000
  HISTFILESIZE=-1
  HISTTIMEFORMAT='[%F %T] '
  __prompt_history() { history -a; history -c; history -r; }
fi

shopt -s autocd cmdhist checkhash checkwinsize histverify histreedit

alias ls='ls --color=auto'
alias l='ls -l'
alias ll='ls -l'
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
alias py='ipython --no-banner --no-confirm-exit'
alias py3='ipython3 --no-banner --no-confirm-exit'
alias ipython='ipython --no-banner --no-confirm-exit'
alias ipython3='ipython --no-banner --no-confirm-exit'
alias bc='bc -q'
alias gdb='gdb --quiet'
alias R='R --no-save --no-restore --quiet'
alias octave='octave -q'
alias parallel='parallel --will-cite'
alias b=byobu-tmux
alias g=git
alias got=git

# For use in PROMPT_COMMAND: print last command's exit code if non zero.
__prompt_print_status() {
  local __status=$?
  if [[ $__status -ne 0 ]]; then
    echo -e "\033[31m\$? = ${__status}\033[m"
  fi
}

# Set up PS1, PROMPT_COMMAND. Parameters: PS1_COLOR.
__setup_prompt() {
  # set variable identifying the chroot you work in (used in the prompt below)
  if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
  fi

  if [[ "$TERM" == "dumb" ]]; then
    PS1='\u@\h:\w\$ '
  else
    PS1='\[\033[01;${PS1_COLOR:-32}m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'  # user@host:workdir
    if declare -f -F __git_ps1 >/dev/null; then
      PS1+='\[\033[35m\]$(__git_ps1)\[\033[00m\]'                                       # git branch
    fi
    PS1+='\$ '
  fi

  # If this is an xterm set the title to user@host:dir
  if [[ "$TERM" == xterm* || "$TERM" == rxvt* ]]; then
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  fi

  [[ ";$PROMPT_COMMAND;" == *__prompt_print_status* ]] && return

  declare -f __prompt_history >/dev/null 2>&1 &&
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

[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

if declare -f __setup_prompt >/dev/null 2>&1; then
  __setup_prompt
  unset __setup_prompt
fi
