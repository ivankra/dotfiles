set nocompatible
set noerrorbells                        " Be quiet
set wildmenu                            " Enhanced command line completion mode
set autoread                            " Automatically re-read files changed outside of vim
set autowrite                           " Automatically save file before calling external commands
set display+=uhex,lastline              " Display unprintable characters in hex as <xx>,
set showcmd                             " Show command on the last screen line
set showmode                            " Show current mode in the last screen line
set laststatus=2                        " All windows have a status line
set statusline=%<%f%h%m%r%=%b=0x%B\ \ %l,%c%V\ %P
set virtualedit=block                   " Allow cursor to move beyond end-of-line in block selection mode
set backspace=2                         " Allow backspacing over indent, EOL, start of insert
set formatoptions+=r                    " Automatically continue comments after pressing <Enter>
set nobackup noswapfile viminfo=""      " Don't create any kind of temporary files
set tags=tags,./tags;                   " Look for tags in current directory, then in current file's directory and upwards
set encoding=utf-8                      " Use utf-8 to represent text internally in vim
setglobal fileencoding=utf-8            " Default file encoding for new files
set fileencodings=ucs-bom,utf-8,cp1251  " List of encodings to check when opening an existing file
set formatprg=indent\ -kr\ --no-tabs    " Formatting command for "gq" operator
set foldmethod=marker                   " Folds are defined by lines with {{{ and }}} markers
set noexpandtab tabstop=8 sts=0 sw=8    " Default tab settings
set nowrap                              " No wrapping by default
set incsearch ignorecase smartcase hlsearch  " Search options
syntax on

set noautoindent
filetype plugin indent on

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

" Key map: F2 = save
noremap <F2> :w<CR>
inoremap <F2> <C-O>:w<CR>

" Make yank/paste work with system's clipboard.
if has("win32")
  set clipboard=unnamed
else
  " Workaround for X11 vim via remaps.
  " Unfortunately, this prevents working with other vim registers.
  vnoremap y "+y
  vnoremap p "+p
endif

" Ctrl-V in command mode pastes from system clipboard
cmap <C-V> <C-R>+

" :CD switches to current file's directory
com! CD cd %:p:h

" Typing %% in vim command line expands to current file's directory
cabbr <expr> %% expand('%:p:h')

" Enable fswitch plugin.  Ctrl-A switches between .h and .cc
runtime fswitch.vim
nmap <C-A> :FSHere<CR>
autocmd BufEnter *.cpp let b:fswitchdst='h,hpp' | let b:fswitchlocs='.'
autocmd BufEnter *.cc  let b:fswitchdst='h,hpp' | let b:fswitchlocs='.'
autocmd BufEnter *.h   let b:fswitchdst='cc,cpp,c' | let b:fswitchlocs='.'

" Interpret filenames of the form <filename>:<number> as the instruction
" to open <filename> (if it exists) and position the cursor at a given line.
autocmd! BufNewFile *:* nested call s:gotoline()
function! s:gotoline()
  let file = bufname("%")
  let names = matchlist(file, '\(.*\):\(\d\+\):*')

  if len(names) != 0 && filereadable(names[1])
    let l:bufn = bufnr("%")
    exec ":e " . names[1]
    exec ":" . names[2]
    exec ":bdelete " . l:bufn
    if foldlevel(names[2]) > 0
      exec ":foldopen!"
    endif
  endif
endfunction

" Enable cscope keymaps
runtime cscope_maps.vim
set nocscopetag

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

  set guioptions-=T   " disable toolbar
  set guioptions-=t   " disable tear-off menu items
else
  " console vim settings
  if ($TERM == "xterm")
    set background=light
  else
    set background=dark
  endif
endif
