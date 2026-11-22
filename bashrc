#!/bin/bash
# Targets Linux and macOS (latest 1-2 releases, Apple Silicon, /bin/bash 3.2).
# Also sourced from ~/.xsessionrc and ~/.profile by dash, top part must stay POSIX.

export IPYTHONDIR="$HOME/.config/ipython"
export JUPYTER_CONFIG_DIR="$HOME/.config/jupyter"
export LANG=en_US.UTF-8  # also /var/lib/AccountsService/users/*, ~/.config/plasma-localerc
export LANGUAGE=en_US:en
export LC_COLLATE=C
export LC_MEASUREMENT=C  # metric
export LESS='-FRSXi'
export LESSHISTFILE=-
export PAGER=less

# Not bash/zsh: set up basic PATH with POSIX syntax and quit
if [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ]; then
  for __dir in /bin /usr/bin /usr/local/bin /opt/homebrew/sbin /opt/homebrew/bin \
               "$HOME/.dotfiles/bin" "$HOME/.iac/bin" "$HOME/.local/bin"; do
    case :$PATH: in
      *:"$__dir":*) ;;
      *) if [ -d "$__dir" ]; then PATH="$__dir:$PATH"; fi ;;
    esac
  done
  unset __dir

  # For X session environment
  if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
  else
    export EDITOR=vim
  fi
  export VISUAL=$EDITOR

  return
fi

if [[ -z "$GOPATH" ]]; then
  export GOPATH=~/.go
fi

if [[ -z "$GOROOT" ]]; then
  if [[ -d ~/.local/go ]]; then
    export GOROOT=~/.local/go
  elif [[ -d /usr/local/go ]]; then
    export GOROOT=/usr/local/go
  fi
fi

if [[ -z "$CUDA_ROOT$CUDA_PATH" && -d /usr/local/cuda ]]; then
  export CUDA_ROOT=/usr/local/cuda
  export CUDA_PATH=/usr/local/cuda
fi

if [[ -z "$CONDA_ROOT" ]]; then
  if [[ -x ~/.conda/bin/conda ]] && ! [[ ~/.conda/bin/conda -ef /opt/conda/bin/conda ]]; then
    export CONDA_ROOT=~/.conda
  elif [[ -x /opt/conda/bin/conda ]]; then
    export CONDA_ROOT=/opt/conda
  fi
fi

# Move dirs in $1 (a:b:c) to the front of PATH, in order (e.g. after macOS's
# path_helper), unless already in order behind others (e.g. an active venv).
__prepend_path() {
  local dir have='' rest='' IFS=:
  # One pass over PATH: bash splits $PATH on IFS (no globbing of entries),
  # zsh has it split as $path.
  [[ -n "$BASH_VERSION" ]] && set -f
  for dir in ${BASH_VERSION:+$PATH} ${ZSH_VERSION:+"${path[@]}"}; do
    if [[ :$1: != *:"$dir":* ]]; then
      rest+=${rest:+:}$dir
    elif [[ :$have: != *:"$dir":* ]]; then
      have+=${have:+:}$dir
    fi
  done
  [[ -n "$BASH_VERSION" ]] && set +f
  [[ "$have" == "$1" ]] || PATH=$1${rest:+:$rest}
}

# Set up PATH
__path=
for __dir in /bin /usr/bin /usr/local/bin /opt/homebrew/sbin /opt/homebrew/bin \
             ${CUDA_ROOT:+"$CUDA_ROOT/bin"} ${CONDA_ROOT:+"$CONDA_ROOT/bin"} \
             ${GOROOT:+"$GOROOT/bin"} "$GOPATH/bin" \
             ~/.dotfiles/bin ~/.iac/bin ~/.local/bin; do
  if [[ -d "$__dir" && :$__path: != *:"$__dir":* ]]; then
    __path="$__dir${__path:+:$__path}"
  fi
done
# Skip in the common case, a nested shell: PATH already starts with these, in order.
if [[ :$PATH: != :"$__path":* ]]; then
  __prepend_path "$__path"
fi
unset __dir __path

# Search for editor after PATH setup
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi
export VISUAL=$EDITOR

__BASHRC_EPILOGUE="unset __BASHRC_EPILOGUE; unset -f __prepend_path;"

if [[ $- != *i* || -z "$HOME" ]]; then
  # non interactive shell
  eval "$__BASHRC_EPILOGUE"
  return
fi

if [[ -z "$SHELL" && -n "$BASH_VERSION" && -f /bin/bash ]]; then
  export SHELL=/bin/bash
fi

if [[ -n "$BASH_VERSION" ]]; then
  shopt -s checkhash checkwinsize no_empty_cmd_completion
  if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
    # globstar: ** matches files and dirs recursively
    # checkjobs: warn on exit with running/stopped jobs, exit if repeated
    shopt -s autocd checkjobs globstar
  fi
fi

# Aliases/functions
if [[ -f ~/.dotfiles/bashrc.aliases ]]; then
  source ~/.dotfiles/bashrc.aliases
fi

# History: bash's ~/.history/bash.YYYYMM, h, histoff; REPL histories (also zsh)
if [[ -f ~/.dotfiles/bashrc.history ]]; then
  source ~/.dotfiles/bashrc.history
fi

# Bash prompt
if [[ -n "$BASH_VERSION" && -f ~/.dotfiles/bashrc.prompt ]]; then
  source ~/.dotfiles/bashrc.prompt
fi

if [[ $UID == 0 ]]; then
  umask 027
fi

if ! [[ -d ~/.ssh/socket ]]; then
  mkdir -p ~/.ssh/socket >/dev/null 2>&1
  chmod 0700 ~/.ssh ~/.ssh/socket >/dev/null 2>&1
fi

if [[ -f ~/.lesshst || -f ~/.wget-hsts || -f ~/.xsel.log ]]; then
  rm -f ~/.lesshst ~/.wget-hsts ~/.xsel.log
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

# Disabled for now: asking the terminal for its background can eat keys typed
# during startup. Assume dark unless the terminal (rxvt) or ssh provides it.
# To re-enable: uncomment, drop the COLORFGBG guess and the stub below.
#if [[ -f ~/.dotfiles/bin/colorfgbg ]]; then
#  source ~/.dotfiles/bin/colorfgbg
#fi
if [[ -z "$COLORFGBG" ]]; then
  export COLORFGBG="15;0"
fi
__reset_colorfgbg() { :; }  # stub, called by h()

if [[ -z "$LS_COLORS" ]] && hash dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b ~/.dotfiles/dircolors)"
fi

if [[ -n "$VTE_VERSION" ]]; then
  if [[ -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
  elif [[ -f /etc/profile.d/vte-2.91.sh ]]; then
    source /etc/profile.d/vte-2.91.sh
  fi
fi

# WezTerm: OSC 7 cwd and OSC 133 semantic zones (ScrollToPrompt, select output)
# via bash-preexec's DEBUG trap, so also on bash 3.2.
if [[ "$TERM_PROGRAM" == WezTerm ]]; then
  # shellcheck disable=SC2034  # read by wezterm.sh; user vars cost several forks per prompt
  WEZTERM_SHELL_SKIP_USER_VARS=1
  source ~/.dotfiles/third_party/wezterm-shell-integration/wezterm.sh
  __bp_adjust_histcontrol() { :; }  # keep ignorespace in HISTCONTROL
fi
# Workaround to disable "Command complete" notifications in ptyxis
if [[ -n $PTYXIS_PROFILE ]]; then
  __vte_termprop_signal() { :; }
fi

if [[ -n "$BASH_VERSION" ]]; then
  if [[ "$OSTYPE" == darwin* ]]; then
    # Homebrew bash-completion@2 needs bash 4.2+, v1 (bash-completion) for 3.2
    __p=${HOMEBREW_PREFIX:-/opt/homebrew}  # Apple Silicon only
    if (( BASH_VERSINFO[0] * 100 + BASH_VERSINFO[1] >= 402 )) &&
       [[ -f "$__p/etc/profile.d/bash_completion.sh" ]]; then
      source "$__p/etc/profile.d/bash_completion.sh"
    elif [[ -f "$__p/etc/bash_completion" ]]; then
      source "$__p/etc/bash_completion"
    fi
    # __git_ps1 for PS1, unless bash-completion loaded it
    if ! declare -F __git_ps1 >/dev/null; then
      for __f in "$__p/etc/bash_completion.d/git-prompt.sh" \
                 /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh \
                 /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh; do
        if [[ -f "$__f" ]]; then
          source "$__f"
          break
        fi
      done
    fi
    unset __p __f
  elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
  fi
  # fzf key bindings and completion: `fzf --bash` needs fzf 0.48+
  if hash fzf >/dev/null 2>&1 && __fzf_init=$(fzf --bash 2>/dev/null); then
    eval "$__fzf_init"
  else
    if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
      source /usr/share/doc/fzf/examples/completion.bash
    fi
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
      source /usr/share/doc/fzf/examples/key-bindings.bash
    fi
  fi
  unset __fzf_init
  if [[ "$OSTYPE" == darwin* && "$TERM_PROGRAM" == iTerm.app ]]; then
    source ~/.dotfiles/iterm2/iterm2_shell_integration.bash
  fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  if [[ "$OSTYPE" == darwin* && "$TERM_PROGRAM" == iTerm.app ]]; then
    source ~/.dotfiles/iterm2/iterm2_shell_integration.zsh
  fi
fi

if [[ -n "$CONDA_ROOT" && -f "$CONDA_ROOT/etc/profile.d/conda.sh" ]]; then
  true  # in case conda installer comments out below line causing syntax error
  source "$CONDA_ROOT/etc/profile.d/conda.sh"
fi

if [[ -d ~/.iac || -d ~/.keys ]] && hash npm >/dev/null 2>&1; then
  echo -e '\e[97;41mAction required: uninstall npm from workstation!\e[0m'
fi

if [[ -f ~/.iac/bashrc.local ]]; then
  source ~/.iac/bashrc.local
fi

if [[ -f ~/.bashrc.local ]]; then
  source ~/.bashrc.local
fi

eval "$__BASHRC_EPILOGUE"
