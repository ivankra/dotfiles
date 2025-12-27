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

command! ToggleWrap call ToggleWrap()

" Alt+Z: toggle word wrap (vscode-like key binding)
if has('nvim')
  lua vim.keymap.set('n', '<A-z>', ':call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
  lua vim.keymap.set('n', '<leader>uw', ':call ToggleWrap()<CR>', { desc = 'Toggle Wrap' })
else
  nmap <A-z> :call ToggleWrap()<CR>
  nmap <leader>uw :call ToggleWrap()<CR>
end
