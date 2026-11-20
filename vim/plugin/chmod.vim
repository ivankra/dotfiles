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
  " Empty if the file doesn't exist locally (e.g. scp:// writes)
  if l:perm ==# '' || l:perm[2] ==# 'x'
    return
  endif
  " Not setfperm(): it only knows the 9 rwx bits and would clear
  " setuid/setgid/sticky. Symbolic chmod only adds the x bits.
  silent! call system('/usr/bin/chmod a+x ' . shellescape(l:file))
endfunction
