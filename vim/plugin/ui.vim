" UI toggles shared by vim/nvim.
if exists("g:ui_vim_loaded")
  finish
endif
let g:ui_vim_loaded = 1

" Cursor motion by display lines when 'wrap' is on, in regular file buffers
" (not plugin buffers: telescope's prompt etc). Global <expr> maps that check
" 'wrap' each time, not buffer-local ones kept in sync with it: those
" overwrote (wrap on) or deleted (wrap off) completion plugins' buffer-local
" <Up>/<Down>, e.g. blink.cmp's, which sets them once per buffer. blink.cmp
" falls back to these when its menu is closed.
noremap  <silent> <expr> <Up>   &wrap && &buftype ==# '' ? 'gk' : '<Up>'
noremap  <silent> <expr> <Down> &wrap && &buftype ==# '' ? 'gj' : '<Down>'
noremap  <silent> <expr> <End>  &wrap && &buftype ==# '' ? 'g<End>' : '<End>'
" Keep arrows working in the completion popup
inoremap <silent> <expr> <Up>   !pumvisible() && &wrap && &buftype ==# '' ? "\<C-o>gk" : "\<Up>"
inoremap <silent> <expr> <Down> !pumvisible() && &wrap && &buftype ==# '' ? "\<C-o>gj" : "\<Down>"
" <C-o>g<End> leaves the cursor before the last char; <Right> moves past it
inoremap <silent> <expr> <End>  &wrap && &buftype ==# '' ? "\<C-o>g\<End>\<Right>" : "\<End>"
" <Home> is handled by vscode.vim wrap-aware

function! ToggleWrap()
  setlocal wrap!
  redraw
  echomsg &wrap ? "Wrapping long lines" : "No line wrapping"
endfunction

function! ToggleLineNumbers()
  if &number
    setlocal nonumber
    echomsg "Line number off"
  else
    setlocal number
    echomsg "Line number on"
  endif
endfunction

function! ToggleRelativeNumbers()
  if &relativenumber
    setlocal norelativenumber
    echomsg "relativenumber off"
  else
    setlocal number relativenumber
    echomsg "relativenumber on"
  endif
endfunction

function! ToggleSpell()
  if &spell
    setlocal nospell
    echomsg "spell off"
  else
    setlocal spell
    echomsg "spell on"
  endif
endfunction

function! ToggleBackground()
  if &background ==# "dark"
    set background=light
    echomsg "background=light"
  else
    set background=dark
    echomsg "background=dark"
  endif
endfunction

command! ToggleLineNumbers call ToggleLineNumbers()
command! ToggleRelativeNumbers call ToggleRelativeNumbers()
command! ToggleWrap call ToggleWrap()
command! ToggleSpell call ToggleSpell()
command! ToggleBackground call ToggleBackground()

if has('nvim')
lua << EOF
vim.keymap.set('n', '<leader>ub', '<Cmd>call ToggleBackground()<CR>', { desc = 'Toggle Background' })
vim.keymap.set('n', '<leader>ul', '<Cmd>call ToggleLineNumbers()<CR>', { desc = 'Toggle Line Numbers' })
vim.keymap.set('n', '<leader>uL', '<Cmd>call ToggleRelativeNumbers()<CR>', { desc = 'Toggle Relative Numbers' })
vim.keymap.set('n', '<leader>us', '<Cmd>call ToggleSpell()<CR>', { desc = 'Toggle Spell' })
vim.keymap.set('n', '<leader>uw', '<Cmd>call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
vim.keymap.set('n', '<A-z>', '<Cmd>call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
-- 0.8+: no is_disabled() before
if vim.diagnostic.is_enabled or vim.diagnostic.is_disabled then
vim.keymap.set('n', '<leader>ud', function()
  local d = vim.diagnostic
  local enabled
  if d.is_enabled then
    enabled = d.is_enabled()
    d.enable(not enabled)
  else  -- 0.9: is_disabled(), and enable()/disable() take a buffer, not a bool
    enabled = not d.is_disabled()
    if enabled then d.disable() else d.enable() end
  end
  vim.notify("Diagnostics " .. (enabled and "off" or "on"))
end, { desc = 'Toggle Diagnostics' })
end
EOF
else
  nnoremap <leader>ub :call ToggleBackground()<CR>
  nnoremap <leader>ul :call ToggleLineNumbers()<CR>
  nnoremap <leader>uL :call ToggleRelativeNumbers()<CR>
  nnoremap <leader>us :call ToggleSpell()<CR>
  nnoremap <leader>uw :call ToggleWrap()<CR>
  nnoremap <A-z> :call ToggleWrap()<CR>
  nnoremap <Esc>z :call ToggleWrap()<CR>
endif
