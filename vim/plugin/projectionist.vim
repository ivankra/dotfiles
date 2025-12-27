" Switch to alternate file with <C-A>/<leader>a
" Configures vim-projectionist

if has('eval')
  let g:projectionist_heuristics = {
  \  '*': {
  \    '*.cpp': { 'alternate': '{}.h', 'type': 'source' },
  \    '*.cc':  { 'alternate': '{}.h', 'type': 'source' },
  \    '*.c':   { 'alternate': '{}.h', 'type': 'source' },
  \    '*.h':   { 'alternate': ['{}.cpp', '{}.cc', '{}.c'], 'type': 'header' },
  \    '*.hpp': { 'alternate': ['{}.cpp', '{}.cc'], 'type': 'header' },
  \  }
  \}

  " Note - overrides <C-A> = increment command
  " if has('nvim')
  "   lua vim.keymap.set('n', '<C-A>', ':A<CR>', { desc = 'Switch to alternate file (.c/.h)' })
  " else
  "   nmap <C-A> :A<CR>
  " end

  if has('nvim')
    lua vim.keymap.set('n', '<leader>a', ':A<CR>', { desc = 'Switch to alternate file (.c/.h)' })
  else
    nmap <leader>a :A<CR>
  end
end
