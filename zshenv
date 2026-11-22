# Linked by setup.sh. Read by every zsh, before anything else.

# Non-interactive, non-login zsh (`ssh host cmd`, zsh scripts) reads only this
# file: env and PATH from bashrc, which returns right after them. Login shells
# get them from zprofile, interactive ones from zshrc.
if [[ ! -o login && ! -o interactive ]]; then
  source ~/.dotfiles/bashrc
fi

# macOS Terminal.app (/etc/zshrc_Apple_Terminal): no per-window history or
# state in ~/.zsh_sessions. Has to be set here, before /etc/zshrc runs.
SHELL_SESSIONS_DISABLE=1
