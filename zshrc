source ~/.dotfiles/bashrc    # env, PATH, aliases, misc stuff shared with bash

setopt AUTO_CD               # `dir` alone cds into it, as bash's autocd
setopt AUTO_PUSHD            # cd remembers dirs: `cd -<Tab>`, `dirs -v`, `cd +N`
setopt GLOB_STAR_SHORT       # **.py recurses, as bash's globstar
setopt INTERACTIVE_COMMENTS  # allow `cmd  # comment` at the prompt
setopt NO_BEEP
setopt NO_FLOW_CONTROL       # Ctrl-S/Ctrl-Q don't freeze the prompt; Ctrl-S searches forward
setopt PUSHD_IGNORE_DUPS     # revisiting a dir moves it to the top, no duplicates

autoload -Uz add-zsh-hook

# History {{{

# ~/.history/zsh, appended after each command. As bash: a regular file at
# ~/.history disables saving, also any HISTFILE set by /etc/zsh or zshenv.
if [[ -d ~/.history ]] || mkdir -m 0700 -p ~/.history 2>/dev/null; then
  HISTFILE=~/.history/zsh
else
  unset HISTFILE
fi
HISTSIZE=100000
SAVEHIST=100000
HISTORY_IGNORE='(bg|fg|clear|ls|pwd|history|exit)'  # as bash's HISTIGNORE
setopt EXTENDED_HISTORY      # save timestamps
setopt INC_APPEND_HISTORY    # write each command right away, not on exit
setopt HIST_IGNORE_SPACE     # skip commands starting with a space
setopt HIST_IGNORE_DUPS      # only consecutive repeats, so the file is a full log
setopt HIST_FIND_NO_DUPS     # Up/Ctrl-R skip duplicates
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY           # !-expansions are shown for editing, not run

# }}}

# Key bindings {{{

# Bindings as in inputrc
bindkey -e
WORDCHARS=${WORDCHARS//\/}  # Ctrl/Alt+Backspace stop at /
__bind() { local widget=$1 seq; shift; for seq; do bindkey "$seq" $widget; done; }
# Up/Down: search history by the text before the cursor, as inputrc. These put
# the cursor at the end of the line (history-beginning-search-* leave it after
# the searched text, column 0 on an empty line) and move within multi-line ones.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
__bind up-line-or-beginning-search   '\e[A' '\eOA'
__bind down-line-or-beginning-search '\e[B' '\eOB'
__bind beginning-of-line   '\e[1~' '\e[7~' '\e[H' '\eOH'                # Home
__bind end-of-line         '\e[4~' '\e[8~' '\e[F' '\eOF'                # End
__bind delete-char         '\e[3~'                                      # Delete
__bind quoted-insert       '\e[2~'                                      # Insert
__bind emacs-forward-word  '\e[1;5C' '\e[5C' '\e\e[C' '\eOc' '\e[1;3C'  # Ctrl/Alt+Right
__bind emacs-backward-word '\e[1;5D' '\e[5D' '\e\e[D' '\eOd' '\e[1;3D'  # Ctrl/Alt+Left
__bind backward-kill-word  '^H' '^[^?'                                  # Ctrl/Alt+Backspace
__bind kill-word           '\e[3;5~'                                    # Ctrl+Delete

# Ctrl+W: delete back to whitespace, as bash (Ctrl+Backspace stops at /)
autoload -Uz backward-kill-word-match
zle -N backward-kill-space-word backward-kill-word-match
zstyle ':zle:backward-kill-space-word' word-style space
__bind backward-kill-space-word '^W'

# Ctrl+X Ctrl+E: edit in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
__bind edit-command-line   '^X^E'
unset -f __bind

# }}}

# Completion {{{

# Homebrew's completions: `brew shellenv` would add them, bashrc sets PATH itself
if [[ -d ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions ]]; then
  fpath=( ${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions $fpath )
fi

zmodload zsh/complist
autoload -Uz compinit bashcompinit
() {
  local dump=~/.cache/zsh/zcompdump-$ZSH_VERSION
  local -a fresh=( $dump(N.mh-24) )
  mkdir -p ${dump:h}
  if (( $#fresh )); then
    compinit -C -d $dump
  else
    compinit -d $dump && touch $dump
  fi
}
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/compcache
bindkey '\e[Z' reverse-menu-complete                   # Shift+Tab
bindkey -M menuselect '\e[Z' reverse-menu-complete

# ~/.dotfiles/completions/ via zsh's bash emulation
bashcompinit
for __f in ~/.dotfiles/completions/*(N.); do
  [[ $__f == *.md ]] || source $__f
done
unset __f

# }}}

# Prompt {{{

# __git_ps1, which bash gets via bash-completion: first of these that exists
__git_prompt=( /usr/lib/git-core/git-sh-prompt(N)
               ${HOMEBREW_PREFIX:-/opt/homebrew}/etc/bash_completion.d/git-prompt.sh(N)
               /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh(N) )
if (( $#__git_prompt )); then
  source $__git_prompt[1]
fi
unset __git_prompt

# Prompt color: red for root and sudoers on servers (no audio)
if [[ -z $PS1_COLOR ]]; then
  if (( UID == 0 || $+usergroups[sudo] && ! $+usergroups[audio] )); then
    PS1_COLOR=31
  else
    PS1_COLOR=32
  fi
fi

# Did a command run? psvar[3] is "1" if so, not for an empty line or Ctrl-C
# at the prompt. Read by the $? line below, the terminal reset and OSC 133;D.
__zshrc_ran_preexec() { __zshrc_ran=1 }
__zshrc_ran_precmd() { psvar[3]=$__zshrc_ran; __zshrc_ran= }
add-zsh-hook preexec __zshrc_ran_preexec
add-zsh-hook precmd __zshrc_ran_precmd  # first precmd hook, before readers

# Labels go in psvar and show via %1v/%2v as is, never run as prompt code
if [[ $TERM == dumb ]]; then
  PROMPT='%n@%m:%~%# '
else
  # (conda) (venv) label, at each prompt: VS Code and nested shells activate
  # them after zshrc
  __zshrc_env_precmd() {
    psvar[1]="${CONDA_DEFAULT_ENV:+($CONDA_DEFAULT_ENV) }${VIRTUAL_ENV:+(${VIRTUAL_ENV:t}) }"
  }
  add-zsh-hook precmd __zshrc_env_precmd
  PROMPT=
  if [[ -z $VSCODE_SHELL_INTEGRATION ]]; then  # VS Code shows it itself
    PROMPT+=$'%(3V.%(?..%F{red}$? = %?%f\n).)'  # last exit code if non-zero
  fi
  PROMPT+='%1v'                        # venv/conda
  PROMPT+="%B%F{cyan}%T%f%b %B%{"$'\e'"[${PS1_COLOR}m%}%n@${PS1_HOST:-%m}%f%b:%B%F{blue}%~%f%b"
  if (( $+functions[__git_ps1] )); then
    __zshrc_git_precmd() {
      local git=$(__git_ps1)
      psvar[2]=${git//'%%'/%}  # undo git-sh-prompt's own % escaping for zsh
    }
    add-zsh-hook precmd __zshrc_git_precmd
    PROMPT+='%F{magenta}%2v%f'
  fi
  PROMPT+='%# '
fi
unset PS1_COLOR PS1_HOST

# Killed by a signal (e.g. Ctrl-C, crash): reset colors and terminal state
__zshrc_fix_tty() {
  local st=$?
  if [[ -n $psvar[3] ]] && (( st > 128 && st < 160 )); then
    print -n $'\e]104\a\e[!p\r'
  fi
}
add-zsh-hook precmd __zshrc_fix_tty

ttyctl -f  # restore tty modes after a program leaves them broken

# }}}

# Terminal integrations {{{

# Only emit OSC sequences for terminals known to support them
case $TERM in
  xterm*|rxvt*|tmux*|screen*|alacritty*|wezterm*|foot*|gnome*|vte*) __zshrc_osc=1;;
esac

# iTerm2's integration: sends its own marks and cwd (OSC 133, 1337).
# Also sets ITERM_SHELL_INTEGRATION_INSTALLED checked below.
if [[ "$OSTYPE" == darwin* && "$TERM_PROGRAM" == iTerm.app ]]; then
  source ~/.dotfiles/iterm2/iterm2_shell_integration.zsh
fi

# Ghostty's script reads this at the first prompt
if [[ -n $GHOSTTY_SHELL_FEATURES ]]; then
  GHOSTTY_SHELL_FEATURES=${${GHOSTTY_SHELL_FEATURES//title/}//cursor/}
fi

# Send OSC 133 and OSC 7, unless sent by a shell integration:
# VS Code, iTerm2, kitty, Ghostty (loaded by their .zshenv before zshrc;
# kitty can turn off either).
if (( ! ${+__zshrc_osc7} )); then
  __zshrc_osc133=$__zshrc_osc
  __zshrc_osc7=$__zshrc_osc
  if [[ -n $VSCODE_SHELL_INTEGRATION$ITERM_SHELL_INTEGRATION_INSTALLED ]] ||
     (( $+functions[_ghostty_deferred_init] )); then
    __zshrc_osc133=0
    __zshrc_osc7=0
  elif (( $+functions[_ksi_deferred_init] )); then
    if [[ " $KITTY_SHELL_INTEGRATION " != *" no-prompt-mark "* ]]; then
      __zshrc_osc133=0
    fi
    if [[ " $KITTY_SHELL_INTEGRATION " != *" no-cwd "* ]]; then
      __zshrc_osc7=0
    fi
  fi
fi

# }}}

# Set terminal title (OSC 2) {{{
# Use OSC 2 instead of OSC 0 to only set the title, not the icon.

if (( __zshrc_osc )); then
  # `user@host: dir`
  __zshrc_title_precmd() {
    print -Pn '\e]2;%n@%m: %~\a'
  }
  add-zsh-hook precmd __zshrc_title_precmd

  # `user@host - cmd`
  __zshrc_title_preexec() {
    # Not for space-prefixed commands, as history
    if [[ $1 != ' '* ]]; then
      print -rn -- $'\e]2;'"$USERNAME@${HOST%%.*} - ${1//[[:cntrl:]]/ }"$'\a'
    fi
  }
  add-zsh-hook preexec __zshrc_title_preexec
fi
unset __zshrc_osc

# }}}

# Prompt marks (OSC 133) {{{

if (( __zshrc_osc133 )); then
  # D;status of the previous command and A prompt start from precmd, so they
  # aren't replayed when the prompt is redrawn (Ctrl-L); B command line start
  __zshrc_osc133_precmd() {
    local st=$?
    if [[ -n $psvar[3] ]]; then
      print -n "\e]133;D;$st\a"
    fi
    print -n "\e]133;A\a"
  }
  add-zsh-hook precmd __zshrc_osc133_precmd
  PROMPT+=$'%{\e]133;B\a%}'
  if (( ! ${preexec_functions[(I)__vte_preexec]} )); then
    __zshrc_osc133_preexec() { print -n $'\e]133;C\a' }  # output starts
    add-zsh-hook preexec __zshrc_osc133_preexec
  fi
fi

# }}}

# Current directory (OSC 7) {{{

if (( __zshrc_osc7 && ! ${precmd_functions[(I)__vte_osc7]} )); then
  # At every prompt: an ssh, nested shell or sudo -s may have reported another
  # one meanwhile. The file:// URL is percent-encoded byte by byte, as
  # Terminal.app's own does, so any name arrives as is; cached per directory.
  __zshrc_osc7_precmd() {
    if [[ $PWD != $__zshrc_osc7_pwd ]]; then
      __zshrc_osc7_pwd=$PWD
      setopt local_options no_multibyte  # bytes, not characters
      local LC_ALL=C url=$PWD i ch
      if [[ $PWD == *[^A-Za-z0-9/._~-]* ]]; then
        url=
        for (( i = 1; i <= $#PWD; i++ )); do
          ch=$PWD[i]
          if [[ $ch == [A-Za-z0-9/._~-] ]]; then
            url+=$ch
          else
            printf -v ch '%%%02X' "'$ch"
            url+=$ch
          fi
        done
      fi
      __zshrc_osc7_url=$url
    fi
    print -rn -- $'\e]7;file://'"$HOST$__zshrc_osc7_url"$'\a'
  }
  add-zsh-hook precmd __zshrc_osc7_precmd
  # macOS Terminal.app's own (/etc/zshrc_Apple_Terminal), sent twice otherwise
  add-zsh-hook -d precmd update_terminal_cwd
fi

# }}}

# Plugins: zsh-autosuggestions, zsh-syntax-highlighting, fzf {{{

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50  # no suggestions past 50 chars
ZSH_HIGHLIGHT_MAXLENGTH=1000        # no highlighting past 1000 chars for fast pastes

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd, **<Tab>.
if [[ -t 0 ]] && (( $+commands[fzf] )); then  # no terminal: zle errors
  if __fzf_init=$(fzf --zsh 2>/dev/null); then
    eval "$__fzf_init"
  else  # fzf < 0.48 (Debian 12) has no `fzf --zsh`
    for __f in /usr/share/doc/fzf/examples/{completion,key-bindings}.zsh(N); do
      source $__f
    done
  fi
fi
unset __f __fzf_init

# Plugins from Debian (/usr/share) or Homebrew, if installed.
# zsh-autosuggestions: grey suggestion from history as you type, Right/End accepts it
# zsh-syntax-highlighting: colors the command line as you type (keep last)
for __p in zsh-autosuggestions zsh-syntax-highlighting; do
  for __f in /usr/share/$__p/$__p.zsh(N) ${HOMEBREW_PREFIX:-/opt/homebrew}/share/$__p/$__p.zsh(N); do
    source $__f
    break
  done
done
unset __p __f

# }}}
