" Auto chmod a+x new files with a shebang

augroup AutoChmodShebang
  autocmd!
  autocmd BufWritePost * call s:ChmodShebang()
augroup END

function! s:ChmodShebang()
  if !executable('/usr/bin/chmod')
    return
  endif
  let l:first_line = getline(1)
  if l:first_line !~# '^#!'
    return
  endif
  let l:file = expand('%:p')
  let l:perm = getfperm(l:file)
  if l:perm[2] ==# 'x'
    return
  endif
  silent! call system('/usr/bin/chmod a+x ' . shellescape(l:file))
endfunction
