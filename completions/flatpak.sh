# bash completion for ~/.dotfiles/flatpak/flatpak.sh

_flatpak_sh() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local apps words=
  apps=$(~/.dotfiles/flatpak/flatpak.sh list 2>/dev/null)
  case ${COMP_WORDS[1]:-} in
    update|sdk|list) ;;
    *) words=$apps;;
  esac
  if [[ $COMP_CWORD -eq 1 ]]; then
    words="$apps uninstall bundle clean update sdk list help"
  fi
  COMPREPLY=($(compgen -W "$words" -- "$cur"))
}

complete -F _flatpak_sh flatpak.sh
