" Dracula with local tweaks, sourced by vimrc
" Colors from vim/colors/dracula-dark.vim, an overlay on third_party/dracula.vim
" Local preference: disable italics.
let g:dracula_italic = 0
" Put the package on runtimepath now: its colors/ use :runtime, which only
" sees pack/*/start after vimrc is done
packadd! dracula.vim
set background=dark
colorscheme dracula-dark
