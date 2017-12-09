[[ -z "$PS1" || -z "$HOME" ]] && return  # quit if not running interactively

export PATH="$HOME/bin:$HOME/.bin:$HOME/.dotfiles/bin:$PATH"
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_COLLATE=C
export EDITOR=vim
export PAGER=less
export LESS=-r
export LESSHISTFILE=-

# History control: do not write to disk, ignore all duplicates and commands starting with space
HISTFILE=
HISTCONTROL=ignoreboth
HISTSIZE=1000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

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
alias cd3='cd ./$(scm-root)'
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
alias g=git
alias got=git

# For use in PROMPT_COMMAND: print last command's exit code if non zero.
__ps1_print_status() {
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

  [[ "$PROMPT_COMMAND" =~ .*__ps1_print_status.* ]] && return

  # Has to be the first thing in PROMPT_COMMAND to get correct $?
  PROMPT_COMMAND="__ps1_print_status;$PROMPT_COMMAND"
}

if [[ -n "$VTE_VERSION" ]]; then
  if [[ -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
  elif [[ -f /etc/profile.d/vte-2.91.sh ]]; then
    source /etc/profile.d/vte-2.91.sh
  fi
fi

[[ -f /usr/share/bash-completion/bash_completion ]] &&
  source /usr/share/bash-completion/bash_completion

# Local per-machine configuration
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
[[ -f ~/.dotfiles/bashrc.local ]] && source ~/.dotfiles/bashrc.local

__setup_prompt
