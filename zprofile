# Linked by setup.sh. zsh login shells don't read ~/.profile, so
# non-interactive ones (`zsh -l -c ...`, e.g. a GUI session) get env and PATH
# here. Interactive ones get it from ~/.zshrc, others from ~/.zshenv.

if [[ ! -o interactive ]]; then
  source ~/.dotfiles/bashrc
fi
