set nocompatible
set nobackup noswapfile
set ruler showcmd showmode noerrorbells nowrap wildmenu
set autoread autowrite clipboard=unnamed history=50
set foldmethod=marker backspace=2 formatoptions+=r encoding=utf8
set incsearch ignorecase smartcase hlsearch display+=lastline,uhex
set laststatus=2 statusline=%<%f%h%m%r%=%b=0x%B\ \ %l,%c%V\ %P
set tags=./tags,./TAGS,tags,TAGS,../tags,../../tags,../../../tags,../../../../tags,../../../../../tags,../../../../../../tags
set virtualedit=block   " allow cursor to move unrestricted in block mode

set tabstop=8 noexpandtab autoindent
syntax on

set fileencodings=ucs-bom,utf-8,cp1251,default,latin1

if has("gui_running")
  if has("win32")
    set guifont=DejaVu_Sans_Mono:h12:cRUSSIAN
    autocmd GUIEnter * simalt ~x    " Maximize GUI window on start
  else
    "set guifont=Monospace\ 11
    "set guifont=Inconsolata\ 13
  endif

  colorscheme summerfruit256

  set guioptions-=T
  set guioptions-=t
else
  " settings for console
  set highlight+=s:MyStatusLineHighlight
  highlight MyStatusLineHighlight ctermbg=white ctermfg=black
  if ($TERM == "xterm")
    set background=light
  else
    set background=dark
  endif
endif

" Toggles wrapping, and enables cursor motion by display lines when
" wrapping is on.
function ToggleWrap()
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
endfunction
com! ToggleWrap call ToggleWrap()

filetype plugin indent on

autocmd BufReadPre SConstruct set filetype=python
autocmd BufReadPre SConscript set filetype=python

autocmd FileType c,cpp,java set sts=4 sw=4 et cindent
autocmd FileType asm    set sts=4 sw=4 et autoindent
autocmd FileType python set sts=4 sw=4 et autoindent
autocmd FileType lua    set sts=4 sw=4 et autoindent
autocmd FileType make   set sts=0 sw=8 noet nowrap
autocmd FileType cmake  set sts=4 sw=4 et nowrap
autocmd FileType html,xhtml set sts=4 sw=4 ts=8 et nowrap noai indentexpr=""

autocmd BufEnter *.cpp let b:fswitchdst='hpp,h' | let b:fswitchlocs='.'
autocmd BufEnter *.cc let b:fswitchdst='hpp,h' | let b:fswitchlocs='.'
autocmd BufEnter *.h let b:fswitchdst='cc,cpp,c' | let b:fswitchlocs='.'

autocmd BufNewFile *.cpp 0 read ~/.vimrc

set formatprg=indent\ -kr\ --no-tabs

" Keys remaps:
"   F2 - save
"   F5 - make
"   Ctrl-[Shift]-V - paste from X clipboard  (you can still use Ctrl-Q for block selection)
noremap <F2> :w<CR>
inoremap <F2> <C-O>:w<CR>
noremap <F5> :make<CR>
inoremap <F5> <C-O>:make<CR>
map  <C-S-V> "+gp
imap <C-S-V> <C-O>"+gp
map! <C-S-V> <C-R>+

" :CD switches to the directory where the current buffer currently is
com! CD cd %:p:h

" file:line.vim
function! s:gotoline()
	let file = bufname("%")
	let names =  matchlist( file, '\(.*\):\(\d\+\):*')

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

autocmd! BufNewFile *:* nested call s:gotoline()
autocmd! BufNewFile *:*: nested call s:gotoline()

runtime cscope_maps.vim
set nocscopetag

" Ctrl-A switches between .h and .cc
runtime fswitch.vim
nmap <C-A> :FSHere<CR>

" Typing %%/ in vim command line produces file's current directory
cabbr <expr> %% expand('%:p:h')
