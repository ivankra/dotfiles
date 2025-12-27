set nocompatible
set autoread                            " Automatically re-read files changed outside of vim
set clipboard=unnamedplus               " Yank/paste using X11 clipboard
set confirm                             " Confirm to save when closing a modified buffer instead of error
set encoding=utf-8                      " Use utf-8 to represent text internally in vim
set fileencodings=ucs-bom,utf-8,cp1251  " List of encodings to check when opening an existing file
set foldmethod=marker                   " Folds are defined by lines with {{{ and }}} markers
set formatoptions+=r                    " Automatically continue comments after pressing <Enter>
set gdefault                            " Replace does /g by default
set hlsearch                            " Highlight all matches
set ignorecase                          " Case-insensitive search by default (add \C to pattern to override)
set incsearch                           " Incremental search as you type
set laststatus=2                        " Always show statusline
set noswapfile viminfo=""               " Don't create any kind of temporary files
set pastetoggle=<F12>                   " Key to toggle paste mode
set pumheight=10                        " Limit popup menu's height
set showcmd                             " Show command on the last screen line
set smartcase                           " Case-sensitive search if pattern contains uppercase characters
set splitbelow                          " Put new split window below
set splitright                          " Put new vertically split window to the right
set virtualedit=block                   " Allow cursor to move beyond end-of-line in block selection mode
set wildmode=longest:full,full          " Completion mode like readline
set wildoptions=pum                     " Show a popup menu for autocompletions

" Wrapping
set nowrap                              " No line wrapping by default
set linebreak                           " Wrap line at whitespace
set breakindent                         " Continue original indentation on wrapped lines
set breakindentopt="shift:2,sbr"        " At least 2 column indent and enable showbreak
set showbreak="↪"                       " Wrapping indicator e.g. ↪ ⤷ ↳ └─▶

" Default indent options. Will get adjusted by vim-sleuth.
set autoindent                          " Basic autoindent
set smartindent                         " C-like indent (between autoindent and cindent)
set expandtab                           " Expand tabs
set softtabstop=-1                      " Use shiftwidth value
set shiftwidth=2                        " 2 space indent

set statusline=
set statusline+=%<%f                    " File path
set statusline+=%h                      " Help flag [help]
set statusline+=%m                      " Modified flag [+]
set statusline+=%r                      " Readonly flag [RO]
set statusline+=%=                      " === Right side ===
set statusline+=\ 0x%02B                " Hex value of char under cursor
set statusline+=\ \ %{&fenc?&fenc:&enc} " File encoding: utf-8
set statusline+=\ \ %y                  " FileType: [python]
set statusline+=\ %3l:%-2c              " line:col
set statusline+=\ %P                    " Percentage through file

if has("termguicolors") || $TERM == "xterm-256color" || $TERM == "screen-256color" || $TERM == "tmux-256color"
  set termguicolors                     " Enable 24-bit color in terminal
endif

if has("eval")
  let mapleader = " "                   " <leader> key

  let g:is_bash = 1
  let g:markdown_minlines = 1000
  let g:netrw_dirhistmax = 0
  let g:tex_flavor = "latex"
  let g:pyindent_open_paren = "&sw"

  let g:dracula_italic = 0
  let g:gruvbox_contrast_dark = "hard"
  let g:gruvbox_italic = 0
  let g:sonokai_enable_italic = 0
end

" [ cd]: cd to current file's directory (alternative: set autochdir)
noremap <leader>cd :cd %:p:h<CR>

" Typing %%/ in command mode expands to current file's directory
cabbr <expr> %% expand("%:p:h")

" Ctrl-L clears search highlight in addition to redraw
noremap <silent> <C-L> :nohls<CR><C-L>

if has("syntax")
  syntax on
endif

if has("autocmd")
  filetype plugin indent on

  autocmd FileType c,cpp,java,javascript  setlocal cin cino=j1,+2s,g1,h1,(0,l1
  autocmd FileType make                   setlocal noet
  autocmd FileType markdown               syn sync minlines=1000

  " Load large files faster: disable syntax/folding
  autocmd BufReadPre * if getfsize(expand("<afile>")) > 10485760 | setlocal syntax=OFF fdm=manual | endif
endif

if $COLORFGBG == "" || $COLORFGBG == "15;default;0" || $COLORFGBG == "15;0" || has("gui_running")
  set background=dark
  colorscheme dracula
else
  set background=light
  colorscheme fruidle
endif

if has("gui_running")
  set guioptions-=T   " disable toolbar
  set guioptions-=t   " disable tear-off menu items
  set guioptions+=d   " use dark theme variant
  set mouse=a

  if exists("+lines") && exists("+columns")
    set lines=45
    set columns=120
  endif

  " Use system monospace font
  if filereadable("/usr/bin/dconf")
    let dconffont = system("dconf read /org/gnome/desktop/interface/monospace-font-name | tr -d \"'\" | tr -d \\\\n")
    if len(dconffont) > 1
      let &guifont = dconffont
    endif
  endif
endif
