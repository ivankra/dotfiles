set nocompatible
set noerrorbells                        " Be quiet
set wildmenu                            " Enhanced command line completion mode
set autoread                            " Automatically re-read files changed outside of vim
set autowrite                           " Automatically save file before calling external commands
set display+=uhex,lastline              " Display unprintable characters in hex as <xx>,
set showcmd                             " Show command on the last screen line
set showmode                            " Show current mode in the last screen line
set laststatus=2                        " All windows have a status line
set virtualedit=block                   " Allow cursor to move beyond end-of-line in block selection mode
set backspace=2                         " Allow backspacing over indent, EOL, start of insert
set formatoptions+=r                    " Automatically continue comments after pressing <Enter>
set nobackup noswapfile viminfo=""      " Don't create any kind of temporary files
set tags=tags,./tags;                   " Look for tags in current directory, then in current file's directory and upwards
set encoding=utf-8                      " Use utf-8 to represent text internally in vim
setglobal fileencoding=utf-8            " Default file encoding for new files
set fileencodings=ucs-bom,utf-8,cp1251  " List of encodings to check when opening an existing file
set formatprg=indent\ -kr\ --no-tabs    " Formatting command for "gq" operator
set noexpandtab tabstop=8 sts=0 sw=8    " Default tab settings
set nowrap                              " No wrapping by default
set incsearch ignorecase smartcase hlsearch  " Search options
if has("folding")
  set foldmethod=marker                 " Folds are defined by lines with {{{ and }}} markers
endif
set statusline=%<%f%h%m%r%=%{&fileencoding}\ \ 0x%B\ (%b)\ \ %l,%c%V\ %P
set lazyredraw
set pastetoggle=<F12>
set history=100                         " remember more then the default 20 commands

if has("syntax")
  syntax on
endif

set noautoindent

if has("autocmd")
  filetype plugin indent on

  " Load large files faster
  autocmd BufReadPre * if getfsize(expand("<afile>")) > 10485760 | setlocal syntax=OFF fdm=manual | endif

  autocmd BufReadPre SConstruct set filetype=python
  autocmd BufReadPre SConscript set filetype=python

  autocmd FileType c,cpp,java set sts=4 sw=4 et cindent
  autocmd FileType asm        set sts=4 sw=4 et autoindent
  autocmd FileType python     set sts=4 sw=4 et autoindent
  autocmd FileType lua        set sts=4 sw=4 et autoindent
  autocmd FileType make       set sts=0 sw=8 noet nowrap
  autocmd FileType cmake      set sts=4 sw=4 et nowrap
  autocmd FileType html,xhtml set sts=4 sw=4 ts=8 et nowrap noai indentexpr=""
  autocmd FileType sh,vim     set sts=2 sw=2 et autoindent

  autocmd BufNewFile *.py 0r ~/.vim/skeleton/skeleton.py | exec(":10")
endif

if has("user_commands")
" :ToggleWrap command - toggles wrap/nowrap, enables cursor motion by display lines when wrap is on.
com! ToggleWrap call ToggleWrap()
function ToggleWrap()  " {{{
  if &wrap
    setlocal nowrap
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
  else
    setlocal wrap
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g<Home>
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
  endif
endfunction  " }}}
endif

" Key map: F2 = save
noremap <F2> :w<CR>
inoremap <F2> <C-O>:w<CR>

" Make yank/paste work with system's clipboard.
if has("win32")
  set clipboard=unnamed
endif
if has("unnamedplus")  " for patched vim binary
  set clipboard=unnamedplus
endif
vmap <C-C> "+yi
nmap <C-V> "+gPi
imap <C-V> <C-O>"+gP

" Ctrl-V in command mode pastes from system clipboard
cmap <C-V> <C-R>+

" :CD switches to current file's directory
if has("user_commands")
  com! CD cd %:p:h
endif

" Typing %% in vim command line expands to current file's directory
cabbr <expr> %% expand('%:p:h')

" Enable fswitch plugin.  Ctrl-A switches between .h and .cc
if has("autocmd")
  runtime fswitch.vim
  nmap <C-A> :FSHere<CR>
  autocmd BufEnter *.cpp let b:fswitchdst='h,hpp' | let b:fswitchlocs='.'
  autocmd BufEnter *.cc  let b:fswitchdst='h,hpp' | let b:fswitchlocs='.'
  autocmd BufEnter *.h   let b:fswitchdst='cc,cpp,c' | let b:fswitchlocs='.'
endif

if has("autocmd") && has("user_commands")
" Interpret filenames of the form <filename>:<line>[:<col>] as the instruction
" to open <filename> (if it exists) and position the cursor at a given line number.
autocmd! BufNewFile *:* nested call s:gotoline()
function! s:gotoline()
  let file = bufname("%")
  let newfile = ""

  let matches = matchlist(file, '\(.*\):\(\d\+\):*')
  if len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = matches[2]
    let col = ""
  endif

  let matches = matchlist(file, '\(.*\):\(\d\+\):\(\d\+\):*$')
  if len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = matches[2]
    let col = matches[3]
  endif

  if len(newfile) > 0
    let l:bufn = bufnr("%")
    exec ":e " . newfile
    if len(col) > 0
      call cursor(row, col)
    else
      exec ":" . row
    endif
    exec ":bdelete " . l:bufn
    if foldlevel(row) > 0
      exec ":foldopen!"
    endif
    return
  endif
endfunction
endif

" Enable cscope keymaps
if has("cscope")
  runtime cscope_maps.vim
  set nocscopetag
endif

if has("gui_running")
  " gvim settings

  if has("win32")
    set guifont=DejaVu_Sans_Mono:h12:cRUSSIAN
    autocmd GUIEnter * simalt ~x    " Maximize GUI window on start
  else
    "set guifont=Monospace\ 11
    "set guifont=Inconsolata\ 13
  endif

  colorscheme summerfruit256

  " Highlight trailing whitespace and spaces before tabs
  if has("autocmd")
    hi ExtraWhitespace guibg=#ffcccc
    autocmd BufEnter *    match ExtraWhitespace /\s\+$\| \+\ze\t/
    autocmd InsertLeave * match ExtraWhiteSpace /\s\+$\| \+\ze\t/
    autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$\| \+\ze\t/
    match ExtraWhitespace /\s\+$/
  endif

  set guioptions-=T   " disable toolbar
  set guioptions-=t   " disable tear-off menu items
else
  " console vim settings
  if ($TERM == "xterm")
    set background=light
    set t_Co=256
  else
    set background=dark
  endif
endif

" йцукен->qwerty keymaps {{{
map й q
map ц w
map у e
map к r
map е t
map н y
map г u
map ш i
map щ o
map з p
map х [
map ъ ]
map ф a
map ы s
map в d
map а f
map п g
map р h
map о j
map л k
map д l
map ж ;
map э '
map я z
map ч x
map с c
map м v
map и b
map т n
map ь m
map б ,
map ю .
map Й Q
map Ц W
map У E
map К R
map Е T
map Н Y
map Г U
map Ш I
map Щ O
map З P
map Х {
map Ъ }
map Ф A
map Ы S
map В D
map А F
map П G
map Р H
map О J
map Л K
map Д L
map Ж :
map Э "
map Я Z
map Ч X
map С C
map М V
map И B
map Т N
map Ь M
map Б <
map Ю >
" }}}
