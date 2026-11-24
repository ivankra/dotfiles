" Dracula variant: background #21222c, foreground #ffffff, lighter comments.
" Overlay on top of dracula/vim (third_party/dracula.vim), in the style of its
" colors/alucard.vim: override the palette, build the theme with
" dracula_base.vim, then override a few highlight groups.

" nvim: get dracula/vim on 'runtimepath' first, for its autoload/ and
" colors/ below. A lazy.nvim plugin, which :colorscheme loads on demand only
" for its own schemes. (Vim: a package, on 'runtimepath' from startup.)
if has('nvim')
  lua pcall(function() require('lazy').load({ plugins = { 'dracula.vim' } }) end)
endif

runtime autoload/dracula.vim

let g:dracula#palette.fg       = ['#FFFFFF', 253]  " Original: #F8F8F2
let g:dracula#palette.bg       = ['#21222C', 236]  " Original: #282A36; this is upstream's bgdark
let g:dracula#palette.bgdark   = ['#21222C', 235]  " Same as upstream
let g:dracula#palette.bgdarker = ['#000000', 234]  " Original: #191A21

if !exists('g:dracula_italic')
  let g:dracula_italic = 0
endif

runtime colors/dracula_base.vim

let g:colors_name = 'dracula-dark'

" Same early exit as dracula_base.vim
if !(has('termguicolors') && &termguicolors) && !has('gui_running') && &t_Co != 256
  finish
endif

function! s:h(group, fg, ...) abort " bg, attrs
  let l:bg = get(a:, 1, ['NONE', 'NONE'])
  let l:attrs = get(a:, 2, 'NONE')
  execute 'highlight!' a:group
        \ 'guifg=' . a:fg[0] 'ctermfg=' . a:fg[1]
        \ 'guibg=' . l:bg[0] 'ctermbg=' . l:bg[1]
        \ 'gui=' . l:attrs 'cterm=' . l:attrs
endfunction

let s:comment = g:dracula#palette.comment
let s:bold = g:dracula_bold == 1 ? 'bold' : 'NONE'

" Lighter comments (#6272A4 stays for SignColumn, borders, etc.)
call s:h('DraculaComment', ['#8095D6', 61])
call s:h('DraculaCommentBold', ['#8095D6', 61], ['NONE', 'NONE'], s:bold)

call s:h('LineNr', ['#414D71', 61])
call s:h('NonText', ['#4C4F5D', 238])  " listchars
hi! link CursorLineNr DraculaFg
call s:h('TabLineSel', g:dracula#palette.bg, s:comment)
" ColorColumn links to DraculaBgDark, which equals bg here, so it's invisible.
" Also used for render-markdown.nvim code block backgrounds.
call s:h('ColorColumn', ['NONE', 'NONE'], ['#15151D', 234])

if has('nvim')
  highlight! NvimTreeSpecialFile gui=bold,underline
  call s:h('NvimTreeGitStaged', ['#43CC65', 84])
  call s:h('NvimTreeIndentMarker', s:comment)
endif
