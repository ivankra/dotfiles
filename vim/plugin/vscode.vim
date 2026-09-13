" vscode-like bindings for vim/nvim for ease of switching between editors and muscle memory.
" https://code.visualstudio.com/shortcuts/keyboard-shortcuts-linux.pdf

" [Ctrl+N]: new tab (note: overrides downward motion)
nnoremap <silent> <C-N> :tabnew<CR>

" [Ctrl+S]: save file (if modified)
if has('nvim') || has('patch-8.2.1978')
  nnoremap <C-S> <Cmd>update<CR>
  inoremap <C-S> <Cmd>update<CR>
else
  nnoremap <silent> <C-S> :update<CR>
  inoremap <silent> <C-S> <C-O>:update<CR>
endif

" [Ctrl+Q]: close tab / quit
" Note - in insert/command mode, <C-Q>/<C-V> inserts special characters,
" <C-W> is needed for vim window management - do not redefine.
" nnoremap <C-Q> :q<CR>

" [Ctrl+Z]: undo (note: overrides suspend/:stop command)
nnoremap <C-Z> u
inoremap <C-Z> <C-O>u
vnoremap <C-Z> u

" [Ctrl+Y]: redo (note: overrides scroll up motion)
nnoremap <C-Y> <C-R>
" Keep <C-Y> as "accept" in the completion popup
inoremap <expr> <C-Y> pumvisible() ? "\<C-Y>" : "\<C-O>\<C-R>"
vnoremap <C-Y> <C-R>

" [Ctrl+X]: cut selection or current line (note: overrides subtract command)
nnoremap <C-X> "+dd
vnoremap <C-X> "+d

" [Ctrl+C]: copy selection or current line
nnoremap <C-C> "+yy
vnoremap <C-C> "+y

" [Ctrl+A]: select all, restore cursor on exit (note: overrides increment number command)
if exists('##ModeChanged')
  let s:select_all_pos = []
  " from_insert: <Esc> already moved the cursor left, use the '^ mark instead
  function! s:SelectAllKeepCursor(from_insert)
    let s:select_all_pos = a:from_insert ? getpos("'^") : getpos('.')
    autocmd! SelectAllRestore ModeChanged
    autocmd SelectAllRestore ModeChanged *:* call s:SelectAllOnModeChanged()
    normal! ggVG
  endfunction
  " Restore the cursor only when the selection is left straight to Normal mode
  " (Esc, y, >, :cmd), not e.g. after `c` + typing.
  function! s:SelectAllOnModeChanged()
    if v:event.new_mode =~# '^[vV\x16c]'
      return
    endif
    autocmd! SelectAllRestore ModeChanged
    if v:event.new_mode ==# 'n'
      call setpos('.', s:select_all_pos)
    endif
  endfunction
  augroup SelectAllRestore | augroup END
  nnoremap <silent> <C-A> :call <SID>SelectAllKeepCursor(0)<CR>
  inoremap <silent> <C-A> <Esc>:call <SID>SelectAllKeepCursor(1)<CR>
  vnoremap <silent> <C-A> <Esc>:call <SID>SelectAllKeepCursor(0)<CR>
else
  nnoremap <C-A> ggVG
  inoremap <C-A> <Esc>ggVG
  vnoremap <C-A> <Esc>ggVG
endif

" [Ctrl+Shift+V]: paste from clipboard - defined in SetupGui()

" [Ctrl+Up]: scroll line up
nnoremap <C-Up> <C-Y>
inoremap <C-Up> <C-O><C-Y>

" [Ctrl+Down]: scroll line down
nnoremap <C-Down> <C-E>
inoremap <C-Down> <C-O><C-E>

" [Alt+PageUp]: scroll page up
nnoremap <A-PageUp> <C-B>
inoremap <A-PageUp> <C-O><C-B>

" [Alt+PageDown]: scroll page down
nnoremap <A-PageDown> <C-F>
inoremap <A-PageDown> <C-O><C-F>

" [Alt+Down]: move line/block down
nnoremap <silent> <A-Down> :m .+1<CR>
inoremap <silent> <A-Down> <Esc>:m .+1<CR>gi
vnoremap <silent> <A-Down> :m '>+1<CR>gv

" [Alt+Up]: move line/block up
nnoremap <silent> <A-Up> :m .-2<CR>
inoremap <silent> <A-Up> <Esc>:m .-2<CR>gi
vnoremap <silent> <A-Up> :m '<-2<CR>gv

" [Ctrl+Enter] / [Ctrl+Shift+Enter]: insert line below / above
" GUIs send distinct keys. nvim keeps <C-CR> distinct from <CR>, so in terminals
" without extended key reporting (kitty protocol etc) this just never fires.
" Skip terminal Vim, where key encoding varies by version/terminal.
if has('nvim') || has('gui_running')
  nnoremap <C-CR> o
  inoremap <C-CR> <C-O>o
  nnoremap <C-S-CR> O
  inoremap <C-S-CR> <C-O>O
endif

" [Home]: go to column 1 like vim; if already there, go to first non-blank char.
" With 'wrap' on a continuation screen row, go to the start of that row first.
if has('nvim') || has('patch-8.2.1978')
  function! s:SmartHome()
    let l:col = col('.')
    if &wrap
      normal! g0
      " Landed past column 1: was on a continuation row
      if col('.') != l:col && col('.') > 1
        return
      endif
    endif
    let l:first = match(getline('.'), '\S') + 1
    call cursor(0, l:col == 1 && l:first > 1 ? l:first : 1)
  endfunction
  " <Cmd> keeps the mode, so the same function works in normal/visual/insert.
  " Operator-pending not mapped: d<Home> stays d0.
  nnoremap <Home> <Cmd>call <SID>SmartHome()<CR>
  xnoremap <Home> <Cmd>call <SID>SmartHome()<CR>
  inoremap <Home> <Cmd>call <SID>SmartHome()<CR>
endif

" [Tab]: indent current line/block
nnoremap <silent> <Tab> >>
xnoremap <silent> <Tab> >gv

" [Shift+Tab]: unindent current line/block
nnoremap <silent> <S-Tab> <<
inoremap <silent> <S-Tab> <C-D>
xnoremap <silent> <S-Tab> <gv

" [Ctrl+Backspace]: delete word backward (vscode/readline)
cnoremap <C-BS> <C-W>
inoremap <C-BS> <C-W>
if !has('gui_running') && !exists('g:GuiLoaded')
  " CLI terminals usually send ^H
  cnoremap <C-H> <C-W>
  inoremap <C-H> <C-W>
endif

" [Ctrl+Delete]: delete word forward (vscode/readline)
nnoremap <C-Del> dw
" At end of line <C-O> moves onto the last char, so join the next line instead
inoremap <expr> <C-Del> col('.') >= col('$') ? "\<Del>" : "\<C-O>dw"
" ex mode: no direct equivalent

" [Ctrl+\]: vertical split editor
nnoremap <silent> <C-\> :vsplit<CR>

" [F3]: find next word under cursor
"nnoremap <F3> *
"vnoremap <F3> *
"inoremap <F3> <C-O>*

" [Shift+F3]: find previous word under cursor
"nnoremap <S-F3> #
"vnoremap <S-F3> #
"inoremap <S-F3> <C-O>#

if has('nvim')
  " [Ctrl+Shift+[]: fold region
  nnoremap <C-S-[> zc
  inoremap <C-S-[> <C-O>zc

  " [Ctrl+Shift+]]: unfold region
  nnoremap <C-S-]> zo
  inoremap <C-S-]> <C-O>zo
endif

" Zoom in/out
function! s:AdjustGuiFont(delta)
  if !exists('g:GuiFontOriginal')
    let g:GuiFontOriginal = &guifont
  endif

  let l:font = &guifont
  let l:newfont = l:font

  " Reset to original
  if a:delta == 0
    let l:newfont = g:GuiFontOriginal
  " Handle 'name:hNN[:wNN]' format
  elseif l:font =~ ':h\d\+'
    let l:height = str2nr(matchstr(l:font, ':h\zs\d\+'))
    let l:newheight = l:height + a:delta
    if l:newheight > 1
      let l:newfont = substitute(l:font, ':h\d\+', ':h'.l:newheight, '')
    endif
  " Handle 'name NN' format
  elseif l:font =~ '\s\+\d\+$'
    let l:height = str2nr(matchstr(l:font, '\s\+\zs\d\+$'))
    let l:newheight = l:height + a:delta
    if l:newheight > 1
      let l:newfont = substitute(l:font, '\s\+\d\+$', ' '.l:newheight, '')
    endif
  endif

  " Apply the new font if it changed
  if l:newfont != l:font
    let &guifont = l:newfont
    redraw
    echo 'Font: ' . &guifont
    if has('nvim')
      call timer_start(200, {-> execute("echo 'Font: " . escape(&guifont, "'\\") . "'")})
    endif
  endif
endfunction

function! s:SetupGui()
  if !has('gui_running') && !exists('g:GuiLoaded')
    return
  endif

  " [Ctrl+Shift+V]: paste from clipboard
  " Note - in CLI normally handled by terminal emulator. ^V inserts special chars.
  cnoremap <C-S-V> <C-R>+
  nnoremap <C-S-V> "+p
  " Paste at the cursor literally, without autoindent
  inoremap <C-S-V> <C-R><C-O>+
  " P: don't overwrite the clipboard with the replaced text (vim 9/nvim 0.8+)
  xnoremap <C-S-V> "+P
  if has('nvim')
    tnoremap <C-S-V> <C-\><C-N>"+pi
  endif

  " [Ctrl++]: zoom in
  nnoremap <silent> <C-=> :call <SID>AdjustGuiFont(1)<CR>
  nnoremap <silent> <C-kplus> :call <SID>AdjustGuiFont(1)<CR>

  " [Ctrl+-]: zoom out
  nnoremap <silent> <C--> :call <SID>AdjustGuiFont(-1)<CR>
  nnoremap <silent> <C-_> :call <SID>AdjustGuiFont(-1)<CR>
  nnoremap <silent> <C-kminus> :call <SID>AdjustGuiFont(-1)<CR>

  " [Ctrl+0]: reset zoom
  nnoremap <silent> <C-0> :call <SID>AdjustGuiFont(0)<CR>
endfunction

if has('nvim')
  " For nvim, GUIs load asynchronously, so set up on UIEnter
  augroup VscodeGuiSetup
    autocmd!
    autocmd UIEnter * call <SID>SetupGui()
  augroup END
elseif has('gui_running')
  " For vim, set up immediately if GUI is running
  call s:SetupGui()
endif

if has('nvim')
  " Alt+Z: toggle word wrap
  " nmap <A-z> :call ToggleWrap()<CR>

  " ===== nvim-tree.lua =====
  " [Ctrl+B]: toggle sidebar
  " nnoremap <C-B> :NvimTreeToggle<CR>

  " ===== telescope.nvim =====
  " [Ctrl+P]: fuzzy file search
  nnoremap <C-P> <Cmd>Telescope find_files<CR>
  " [Ctrl+Shift+F]: grep
  nnoremap <C-S-F> <Cmd>Telescope live_grep<CR>
  if !exists('g:GuiLoaded')
    " CLI terminals usually send ^F
    nnoremap <C-F> <Cmd>Telescope live_grep<CR>
  endif

  " ===== Comment.nvim =====
  " [Ctrl+/]: toggle line comment
  " nmap <C-/> <Plug>(comment_toggle_linewise_current)
  " imap <C-/> <Esc><Plug>(comment_toggle_linewise_current)a
  " vmap <C-/> <Plug>(comment_toggle_linewise_visual)
  " if !exists('g:GuiLoaded')
  "   " CLI terminals usually send ^_
  "   nmap <C-_> <Plug>(comment_toggle_linewise_current)
  "   imap <C-_> <Esc><Plug>(comment_toggle_linewise_current)a
  "   vmap <C-_> <Plug>(comment_toggle_linewise_visual)
  " endif

  " ===== toggleterm.nvim =====
  " [Ctrl+`]: toggleable terminal
  " -- <C-`> is sent as <C-Space> (NUL) by gnome-terminal
  " require('toggleterm').setup{open_mapping = { [[<C-`>]], [[<C-Space>]] } }
endif
