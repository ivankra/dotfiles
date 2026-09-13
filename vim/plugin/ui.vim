" UI toggles shared by vim/nvim.
if exists("g:ui_vim_loaded")
  finish
endif
let g:ui_vim_loaded = 1

" Enables cursor motion by display lines when 'wrap' is on.
" 'wrap' is window-local but maps are buffer-local, so resync whenever the
" buffer/window changes or 'wrap' is set. b:ui_wrap_maps marks our maps.
function! s:SyncWrapMaps()
  " Only in regular file buffers; don't clobber plugin buffer maps (telescope etc)
  if &buftype !=# ''
    return
  endif
  if &wrap && !get(b:, 'ui_wrap_maps', 0)
    noremap  <buffer> <silent> <Up>   gk
    noremap  <buffer> <silent> <Down> gj
    noremap  <buffer> <silent> <End>  g<End>
    " Keep arrows working in the completion popup
    inoremap <buffer> <silent> <expr> <Up>   pumvisible() ? "\<Up>"   : "\<C-o>gk"
    inoremap <buffer> <silent> <expr> <Down> pumvisible() ? "\<Down>" : "\<C-o>gj"
    " <C-o>g<End> leaves the cursor before the last char; <Right> moves past it
    inoremap <buffer> <silent> <End>  <C-o>g<End><Right>
    " <Home> is handled by vscode.vim wrap-aware
    " noremap  <buffer> <silent> <Home> g<Home>
    " inoremap <buffer> <silent> <Home> <C-o>g<Home>
    let b:ui_wrap_maps = 1
  elseif !&wrap && get(b:, 'ui_wrap_maps', 0)
    " unmap (not nunmap) to also clear the visual/operator-pending maps
    silent! unmap  <buffer> <Up>
    silent! unmap  <buffer> <Down>
    silent! unmap  <buffer> <End>
    silent! iunmap <buffer> <Up>
    silent! iunmap <buffer> <Down>
    silent! iunmap <buffer> <End>
    " <Home> is handled by vscode.vim wrap-aware
    " silent! unmap  <buffer> <Home>
    " silent! iunmap <buffer> <Home>
    unlet b:ui_wrap_maps
  endif
endfunction

augroup UiWrapMaps
  autocmd!
  autocmd BufEnter,BufWinEnter,WinEnter * call s:SyncWrapMaps()
  if exists('##OptionSet')
    autocmd OptionSet wrap call s:SyncWrapMaps()
  endif
augroup END

function! ToggleWrap()
  setlocal wrap!
  call s:SyncWrapMaps()
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
vim.keymap.set('n', '<leader>ud', function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (enabled and "off" or "on"))
end, { desc = 'Toggle Diagnostics' })
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
