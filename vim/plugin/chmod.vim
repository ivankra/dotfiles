" Auto chmod a+rx a file when a write makes it a script: the written text
" starts with a shebang and the file is new or had no shebang when opened
" (or last written). An existing script stays as is, e.g. after chmod -x.

augroup AutoChmodShebang
  autocmd!
  autocmd BufReadPost * let b:chmod_shebang = getline(1) =~# '^#!'
  autocmd BufWritePre,FileWritePre * let s:existed = !empty(getftype(expand('<afile>:p')))
  autocmd BufWritePost,FileWritePost * call s:ChmodShebang(expand('<afile>:p'))
augroup END

let s:existed = 1

function! s:ChmodShebang(file) abort
  " '[ is the first line written, including for :range write otherfile.
  let l:shebang = getline("'[") =~# '^#!'
  " Shebang state at open is only known for the buffer's own file.
  let l:own = a:file ==# expand('%:p')
  let l:had = s:existed && (l:own ? get(b:, 'chmod_shebang', 0) : 1)
  if l:own
    let b:chmod_shebang = l:shebang
  endif
  if !l:shebang || l:had || !executable('chmod')
    return
  endif
  let l:perm = getfperm(a:file)
  " Empty if the file doesn't exist locally (e.g. scp:// writes)
  if l:perm ==# '' || l:perm =~# '^r.xr.xr.x'
    return
  endif
  " Not setfperm(): it only knows the 9 rwx bits and would clear
  " setuid/setgid/sticky. Symbolic chmod only adds the r and x bits.
  silent! call system('chmod a+rx ' . shellescape(a:file))
endfunction
