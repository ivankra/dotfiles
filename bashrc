# If not running interactively, don't do anything
[[ -z "$PS1" || -z "$HOME" ]] && return

CONFIGS=$(dirname $(readlink ~/.bashrc))

export PATH=$HOME/bin:$CONFIGS/bin:$PATH
export EDITOR=vim
export PAGER=less
export LESSHISTFILE=-
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

# History control: do not write to disk, ignore all duplicates and commands starting with space
HISTFILE=
HISTCONTROL=ignoreboth
HISTSIZE=1000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable color support of ls
if [[ -x /usr/bin/dircolors ]]; then
  eval "$(dircolors -b | sed -e 's/;42:/;47:/g')"
  alias ls='ls --color=auto'
fi

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
alias bc='bc -q'
alias gdb='gdb --quiet'
alias ssh='ssh -AX'
alias R='R --no-save --no-restore --quiet'
alias octave='octave -q'
alias py='ipython'
alias cd3='cd ./$(scm-root.py)'
alias susl='sort | uniq -c | sort -nr | less'
alias dico='dico -a --host localhost'
alias g=git
alias got=git

function up() {
  local root="$(SCM_MAINDIR= scm-root.py)"
  if [[ -z "$root" ]]; then
    return 1
  fi
  if [[ -r $root/.git/config ]] && grep svn-remote $root/.git/config >/dev/null 2>&1; then
    local cmd='git svn rebase --fetch-all'
  elif [[ -d $root/.git5_specs ]] && [[ -d $root/.git ]]; then
    if [[ "$(git symbolic-ref HEAD)" != "refs/heads/work" ]]; then
      echo 'You are not on the "work" branch'
      return 1
    fi
    local cmd="git5 sync"
  elif [[ -d "$root/.git" ]]; then
    local cmd='git pull'
  elif [[ -d $root/.svn ]]; then
    local cmd="cd $root; svn update"
  else
    echo 'Not in a repository'
    return 1
  fi
  bash -c -x "$cmd"
  return $?
}

source $CONFIGS/bash-completion-git

# set variable identifying the chroot you work in (used in the prompt below)
if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

unset PROMPT_COMMAND
unset PS1

if [[ -f ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

if [[ -z "$PS1" ]]; then
  if [[ "$TERM" != "dumb" ]]; then
    function __ps1_print_status() {
      local __status=$?
      if [[ $__status -ne 0 ]]; then
        echo -e "\033[31m\$? = ${__status}\033[m"
      fi
    }
    PROMPT_COMMAND="__ps1_print_status;$PROMPT_COMMAND"

    PS1='${debian_chroot:+($debian_chroot)}'                                             # (`cat /etc/debian_chroot`)
    PS1+='\[\033[01;${PS1_COLOR:-32}m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]'  # user@host:workdir
    PS1+='\[\033[35m\]$(__git_ps1)\[\033[00m\]'                                          # git branch
    PS1+='\$ '

    # If this is an xterm set the title to user@host:dir
    if [[ "$TERM" == xterm* || "$TERM" == rxvt* ]]; then
      PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    fi
  else
    PS1='\u@\h:\w\$ '
  fi
fi
