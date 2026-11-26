" vscode-like bindings for vim/nvim for ease of switching between editors and muscle memory.
" https://code.visualstudio.com/shortcuts/keyboard-shortcuts-linux.pdf
" https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf

" Helpers: s:ClipReg() {{{

" System clipboard register for the Ctrl+X/C/Shift+V keys, as vimrc's
" 'clipboard': "* with "unnamed" (macOS: "+ doesn't yank into it), else "+.
" Vim without clipboard support has neither: its own unnamed register. nvim:
" always "+, which copies to the local clipboard via OSC 52 over ssh too.
function! s:ClipReg() abort
  if has('nvim')
    return '+'
  elseif !has('clipboard') && get(v:, 'clipmethod', 'none') =~# '^\%(none\)\=$'
    " Neither built-in clipboard support nor a clipboard provider (the osc52
    " package, see vimrc)
    return '"'
  endif
  return &clipboard =~# '\<unnamed\>' ? '*' : '+'
endfunction

" }}}

" Ctrl+PageUp/PageDown: previous/next tab, or buffer when there's only one tab {{{

function! s:TabOrBuffer(dir) abort
  if tabpagenr('$') > 1
    execute (a:dir > 0 ? 'tabnext' : 'tabprevious')
  elseif exists(':BufferLineCycleNext') == 2
    " Follows bufferline's visual order when it's loaded
    execute (a:dir > 0 ? 'BufferLineCycleNext' : 'BufferLineCyclePrev')
  else
    execute (a:dir > 0 ? 'bnext' : 'bprevious')
  endif
endfunction
nnoremap <silent> <C-PageUp> :<C-U>call <SID>TabOrBuffer(-1)<CR>
nnoremap <silent> <C-PageDown> :<C-U>call <SID>TabOrBuffer(1)<CR>
inoremap <silent> <C-PageUp> <C-O>:call <SID>TabOrBuffer(-1)<CR>
inoremap <silent> <C-PageDown> <C-O>:call <SID>TabOrBuffer(1)<CR>

" }}}
" Ctrl+Shift+PageUp/PageDown: move tab left/right, or buffer (bufferline) when there's only one tab {{{

function! s:MoveTabOrBuffer(dir) abort
  if tabpagenr('$') > 1
    " silent!: already the first/last tab
    execute 'silent! tabmove ' . (a:dir > 0 ? '+1' : '-1')
  elseif exists(':BufferLineMoveNext') == 2
    execute (a:dir > 0 ? 'BufferLineMoveNext' : 'BufferLineMovePrev')
  endif
endfunction
nnoremap <silent> <C-S-PageUp> :<C-U>call <SID>MoveTabOrBuffer(-1)<CR>
nnoremap <silent> <C-S-PageDown> :<C-U>call <SID>MoveTabOrBuffer(1)<CR>
inoremap <silent> <C-S-PageUp> <C-O>:call <SID>MoveTabOrBuffer(-1)<CR>
inoremap <silent> <C-S-PageDown> <C-O>:call <SID>MoveTabOrBuffer(1)<CR>

" }}}
" Ctrl+S: save file (if modified) {{{

if has('nvim') || has('patch-8.2.1978')
  nnoremap <C-S> <Cmd>update<CR>
  inoremap <C-S> <Cmd>update<CR>
else
  nnoremap <silent> <C-S> :update<CR>
  inoremap <silent> <C-S> <C-O>:update<CR>
endif

" }}}
" Ctrl+Z: undo (note: overrides suspend/:stop command) {{{

nnoremap <C-Z> u
inoremap <C-Z> <C-O>u
" Leave visual mode first: `u` in visual mode lowercases the selection
xnoremap <C-Z> <Esc>u

" }}}
" Ctrl+C: copy selection or current line {{{

nnoremap <expr> <C-C> '"' . <SID>ClipReg() . 'yy'
vnoremap <expr> <C-C> '"' . <SID>ClipReg() . 'y'

" }}}
" Ctrl+Shift+V: paste from clipboard (GUI) {{{

" Note - in CLI normally handled by terminal emulator. ^V in insert mode inserts
" special chars.
" Called by s:SetupGui()
function! s:SetupGuiCtrlShiftV()
  cnoremap <expr> <C-S-V> "\<C-R>" . <SID>ClipReg()
  nnoremap <expr> <C-S-V> '"' . <SID>ClipReg() . 'p'
  " Paste literally, without autoindent. A whole line (from Ctrl+C) goes above
  " the current line, like VS Code.
  inoremap <expr> <C-S-V> "\<C-R>\<C-O>" . <SID>ClipReg()
  " P: don't overwrite the clipboard with the replaced text (vim 9/nvim 0.8+)
  xnoremap <expr> <C-S-V> '"' . <SID>ClipReg() . 'P'
  if has('nvim')
    tnoremap <C-S-V> <C-\><C-N>"+pi
  endif
endfunction

" }}}
" Ctrl+V: paste in command line, from the unnamed register (like p) {{{
" <C-Q> still inserts special characters

cnoremap <expr> <C-V> getcmdtype() ==# '=' ? "\<C-R>\<C-R>\"" : "\<C-R>\<C-R>=substitute(getreg('\"'), '\\n$', '', '')\<CR>"

" }}}
" Ctrl+Up: scroll line up {{{

nnoremap <C-Up> <C-Y>
inoremap <C-Up> <C-O><C-Y>

" }}}
" Ctrl+Down: scroll line down {{{

nnoremap <C-Down> <C-E>
inoremap <C-Down> <C-O><C-E>

" }}}
" Alt+PageUp: scroll page up {{{

nnoremap <A-PageUp> <C-B>
inoremap <A-PageUp> <C-O><C-B>

" }}}
" Alt+PageDown: scroll page down {{{

nnoremap <A-PageDown> <C-F>
inoremap <A-PageDown> <C-O><C-F>

" }}}
" Alt+Down: move line/block down {{{
" silent!: on the last line the error would end the mapping before gi/gv.
" <C-U>: a count would become a range for :m

nnoremap <silent> <A-Down> :<C-U>silent! m .+1<CR>
inoremap <silent> <A-Down> <Esc>:silent! m .+1<CR>gi
vnoremap <silent> <A-Down> :<C-U>silent! '<,'>m '>+1<CR>gv

" }}}
" Alt+Up: move line/block up {{{
" Same as Alt+Down, for the first line

nnoremap <silent> <A-Up> :<C-U>silent! m .-2<CR>
inoremap <silent> <A-Up> <Esc>:silent! m .-2<CR>gi
vnoremap <silent> <A-Up> :<C-U>silent! '<,'>m '<-2<CR>gv

" }}}
" Alt+Left / Alt+Right, Ctrl+Alt+- / Ctrl+Shift+-: go back / forward (jumplist) {{{
" VS Code's Windows keys. Also in terminals where Ctrl+I is Tab, which indents
" (see below)

nnoremap <A-Left> <C-O>
nnoremap <A-Right> <C-I>
" Linux's. Neovim and GUIs only, as for Ctrl+Enter below. Without extended keys
" Ctrl+Alt+- comes as <M-C-_>, and Ctrl+Shift+- as ^_, which is Ctrl+/
" (comment.vim): not mapped.
if has('nvim') || has('gui_running')
  nnoremap <M-C--> <C-O>
  nnoremap <M-C-_> <C-O>
  nnoremap <C-S--> <C-I>
endif

" }}}
" Ctrl+Enter / Ctrl+Shift+Enter: insert line below / above {{{
" GUIs send distinct keys. nvim keeps <C-CR> distinct from <CR>, so in terminals
" without extended key reporting (kitty protocol etc) this just never fires.
" Skip terminal Vim, where key encoding varies by version/terminal.

if has('nvim') || has('gui_running')
  nnoremap <C-CR> o
  inoremap <C-CR> <C-O>o
  nnoremap <C-S-CR> O
  inoremap <C-S-CR> <C-O>O
endif

" }}}
" Home: go to column 1 like vim; if already there, go to first non-blank char. {{{
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

" }}}
" Tab: indent current line/block {{{

nnoremap <silent> <Tab> >>
xnoremap <silent> <Tab> >gv

" }}}
" Shift+Tab: unindent current line/block {{{

nnoremap <silent> <S-Tab> <<
inoremap <silent> <S-Tab> <C-D>
xnoremap <silent> <S-Tab> <gv

" Plain > < keep the selection too, to indent again. x, not v: typing in a
" select-mode snippet placeholder replaces it
xnoremap <silent> > >gv
xnoremap <silent> < <gv

" }}}
" Ctrl+Backspace: delete word backward (vscode/readline) {{{

cnoremap <C-BS> <C-W>
inoremap <C-BS> <C-W>
" CLI terminals usually send ^H: called by s:SetupGui()
function! s:SetupTermCtrlBS()
  cnoremap <C-H> <C-W>
  inoremap <C-H> <C-W>
endfunction

" }}}
" Ctrl+Delete: delete word forward (vscode/readline) {{{

nnoremap <C-Del> dw
" At end of line <C-O> moves onto the last char, so join the next line instead
inoremap <expr> <C-Del> col('.') >= col('$') ? "\<Del>" : "\<C-O>dw"
" ex mode: no direct equivalent

" }}}
" Ctrl+\: vertical split editor {{{

nnoremap <silent> <C-\> :vsplit<CR>

" }}}
" Ctrl++ / Ctrl+- / Ctrl+0: zoom in / out / reset (GUI) {{{

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
  " Handle 'name:hNN[:wNN]' format. 'g': every font of a fallback list
  " (ginit.vim sets one for nvim-qt), not only the first.
  elseif l:font =~ ':h\d\+'
    let l:height = str2nr(matchstr(l:font, ':h\zs\d\+'))
    let l:newheight = l:height + a:delta
    if l:newheight > 1
      let l:newfont = substitute(l:font, ':h\d\+', ':h'.l:newheight, 'g')
    endif
  " Handle 'name NN' format (GTK), also a 'name NN,name NN' list
  elseif l:font =~ '\s\d\+\%(,\|$\)'
    let l:height = str2nr(matchstr(l:font, '\s\zs\d\+\ze\%(,\|$\)'))
    let l:newheight = l:height + a:delta
    if l:newheight > 1
      let l:newfont = substitute(l:font, '\s\zs\d\+\ze\%(,\|$\)', l:newheight, 'g')
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

" Called by s:SetupGui()
function! s:SetupGuiZoom()
  " Ctrl++: zoom in
  nnoremap <silent> <C-=> :call <SID>AdjustGuiFont(1)<CR>
  nnoremap <silent> <C-kplus> :call <SID>AdjustGuiFont(1)<CR>

  " Ctrl+-: zoom out
  nnoremap <silent> <C--> :call <SID>AdjustGuiFont(-1)<CR>
  nnoremap <silent> <C-_> :call <SID>AdjustGuiFont(-1)<CR>
  nnoremap <silent> <C-kminus> :call <SID>AdjustGuiFont(-1)<CR>

  " Ctrl+0: reset zoom
  nnoremap <silent> <C-0> :call <SID>AdjustGuiFont(0)<CR>
endfunction

" }}}

if has('nvim')
  " Ctrl+Shift+[: fold region {{{

  nnoremap <C-S-[> zc
  inoremap <C-S-[> <C-O>zc

  " }}}
  " Ctrl+Shift+]: unfold region {{{

  nnoremap <C-S-]> zo
  inoremap <C-S-]> <C-O>zo

  " }}}
  " Ctrl+P: fuzzy file search {{{

  nnoremap <C-P> <Cmd>Telescope find_files<CR>

  " }}}
  " Ctrl+Shift+P / F1: command palette {{{
  " Terminals without extended keys send Ctrl+Shift+P as Ctrl+P (files)

  nnoremap <C-S-P> <Cmd>Telescope commands<CR>
  nnoremap <F1> <Cmd>Telescope commands<CR>

  " }}}
  " Ctrl+Shift+O: go to symbol in file {{{

  nnoremap <C-S-O> <Cmd>Telescope lsp_document_symbols<CR>

  " }}}
  " Ctrl+Shift+F: grep {{{

  nnoremap <C-S-F> <Cmd>Telescope live_grep<CR>
  " CLI terminals usually send ^F: called by s:SetupGui()
  function! s:SetupTermCtrlShiftF()
    nnoremap <C-F> <Cmd>Telescope live_grep<CR>
  endfunction

  " }}}
  " F8 / Shift+F8: next/previous problem {{{

  nmap <F8> ]d
  nmap <S-F8> [d

  " }}}
  " Shift+Alt+Right / Shift+Alt+Left: expand/shrink selection {{{

  if has('nvim-0.12')
    nmap <S-A-Right> van
    xmap <S-A-Right> an
    xmap <S-A-Left> in
  endif

  " }}}
  " Ctrl+Shift+E: focus/unfocus file explorer {{{

  nnoremap <expr> <C-S-E> &filetype ==# 'NvimTree' ? '<C-W>p' : '<Cmd>NvimTreeFocus<CR>'

  " }}}
  " Ctrl+Shift+G: source control (fugitive's status), or close it {{{
  " nmap: fugitive's own gq, not the format operator

  nmap <expr> <C-S-G> &filetype ==# 'fugitive' ? 'gq' : '<Cmd>Git<CR>'

  " }}}
  " Ctrl+Shift+M: problems (all diagnostics) {{{

  nnoremap <C-S-M> <Cmd>Telescope diagnostics<CR>

  " }}}
  " Ctrl+Shift+K: delete line/block, without copying it {{{
  " Terminals without extended keys send it as Ctrl+K (window up / digraph)

  nnoremap <C-S-K> "_dd
  inoremap <C-S-K> <C-O>"_dd
  xnoremap <C-S-K> "_D

  " }}}
  " Ctrl+Shift+\: jump to matching bracket {{{
  " Terminals without extended keys send it as Ctrl+\ (vertical split)

  nmap <C-S-\> %
  xmap <C-S-\> %

  " }}}
  " Ctrl+Shift+`: new terminal (toggleterm) {{{

  nnoremap <C-S-`> <Cmd>TermNew<CR>
  inoremap <C-S-`> <Cmd>TermNew<CR>
  tnoremap <C-S-`> <Cmd>TermNew<CR>

  " }}}
endif

" SetupGui() {{{

" In nvim, GUIs aren't known yet while plugins load (g:GuiLoaded is set after
" attaching), so this runs on UIEnter. Last in this file: Vim calls it right
" away, so the functions it calls must be defined by then.
function! s:SetupGui()
  if !has('gui_running') && !exists('g:GuiLoaded')
    " Terminals send Ctrl+Shift+F as ^F and Ctrl+Backspace as ^H, so map
    " those instead. GUIs keep the defaults (^F page down, ^H backspace).
    if has('nvim')
      call s:SetupTermCtrlShiftF()
    endif
    call s:SetupTermCtrlBS()
    return
  endif
  call s:SetupGuiCtrlShiftV()
  call s:SetupGuiZoom()
endfunction

if has('nvim')
  " For nvim, GUIs load asynchronously, so set up on UIEnter
  augroup VscodeSetupGui
    autocmd!
    autocmd UIEnter * call <SID>SetupGui()
  augroup END
else
  " For vim, set up immediately (has('gui_running') is already true in gvim)
  call s:SetupGui()
endif

" }}}

" Other bindings:
" Alt+Z         toggle word wrap           ui.vim
" Ctrl+B        toggle sidebar             nvim-tree.lua
" Ctrl+`        toggleable terminal        toggleterm.nvim
" Ctrl+/        toggle line comment        comment.vim
" Ctrl+Shift+I  format document/selection  conform.lua
" Ctrl+.        code action                lsp.lua
" F2            rename symbol              lsp.lua
" F12           go to definition           lsp.lua
" Ctrl+F12      go to implementation       lsp.lua
" Shift+F12     find references            lsp.lua
"
" Different from VS Code:
" Ctrl+Q        close buffer (~ Ctrl+W)    bufdelete.vim/mini.bufremove
"
" Unimplemented / disabled:
" Ctrl+W        unmapped, needed to manage vim's windows
if 0
" F3 / Shift+F3: find next/previous word under cursor {{{

nnoremap <F3> *
vnoremap <F3> *
inoremap <F3> <C-O>*
nnoremap <S-F3> #
vnoremap <S-F3> #
inoremap <S-F3> <C-O>#

" }}}
" Ctrl+A: select all (note: overrides increment number command) {{{
" Vim's Ctrl+A / Ctrl+X increment / decrement; Ctrl+X is already cut (below)

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

" }}}
" Ctrl+X: cut selection or current line (note: overrides decrement number command) - use x or d {{{

nnoremap <expr> <C-X> '"' . <SID>ClipReg() . 'dd'
vnoremap <expr> <C-X> '"' . <SID>ClipReg() . 'd'

" }}}
" Ctrl+Y: redo (note: overrides scroll up motion) - use Ctrl+R {{{

nnoremap <C-Y> <C-R>
" Keep <C-Y> as "accept" in the completion popup
inoremap <expr> <C-Y> pumvisible() ? "\<C-Y>" : "\<C-O>\<C-R>"
xnoremap <C-Y> <Esc><C-R>

" }}}
" Ctrl+N: new tab (note: overrides downward motion) {{{

nnoremap <silent> <C-N> :tabnew<CR>

" }}}
endif
