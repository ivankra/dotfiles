" UI toggles shared by vim/nvim.
if exists("g:ui_vim_loaded")
  finish
endif
let g:ui_vim_loaded = 1

" Toggles wrap/nowrap, enables cursor motion by display lines when wrap is on.
function! ToggleWrap()
  if &wrap
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <Home>
    silent! nunmap <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <Home>
    silent! iunmap <buffer> <End>
    setlocal nowrap
    redraw
    echomsg "No line wrapping"
  else
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <Home> g<Home>
    noremap  <buffer> <silent> <End>  g<End>
    inoremap <buffer> <silent> <Up>   <C-o>gk
    inoremap <buffer> <silent> <Down> <C-o>gj
    inoremap <buffer> <silent> <Home> <C-o>g<Home>
    inoremap <buffer> <silent> <End>  <C-o>g<End>
    setlocal wrap
    redraw
    echomsg "Wrapping long lines"
  endif
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
vim.keymap.set('n', '<leader>ub', ':call ToggleBackground()<CR>', { desc = 'Toggle Background' })
vim.keymap.set('n', '<leader>ul', ':call ToggleLineNumbers()<CR>', { desc = 'Toggle Line Numbers' })
vim.keymap.set('n', '<leader>uL', ':call ToggleRelativeNumbers()<CR>', { desc = 'Toggle Relative Numbers' })
vim.keymap.set('n', '<leader>us', ':call ToggleSpell()<CR>', { desc = 'Toggle Spell' })
vim.keymap.set('n', '<leader>uw', ':call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
vim.keymap.set('n', '<A-z>', ':call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
vim.keymap.set('n', '<leader>ud', function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (enabled and "off" or "on"))
end, { desc = 'Toggle Diagnostics' })
EOF
else
  nmap <leader>ub :call ToggleBackground()<CR>
  nmap <leader>ul :call ToggleLineNumbers()<CR>
  nmap <leader>uL :call ToggleRelativeNumbers()<CR>
  nmap <leader>us :call ToggleSpell()<CR>
  nmap <leader>uw :call ToggleWrap()<CR>
  nmap <A-z> :call ToggleWrap()<CR>
endif
