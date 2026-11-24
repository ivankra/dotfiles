" Interprets filenames of the form <filename>:<line>[:<col>] as the instruction
" to open <filename> (if it exists) and position the cursor at a given line number.
"
" Also strips prefix in git diff paths (a/file, b/file).

if has("autocmd")

augroup FileLineJump
  autocmd!
  autocmd BufNewFile *:*,a/*,b/* nested call s:gotoline()
augroup END

" Wipe the <filename>:<line> buffer after the BufNewFile event is over. Wiping
" it right away breaks the BufNewFile handlers that run after this one for the
" same buffer (guess-indent.nvim: "Invalid buffer id").
function! s:WipeLater(bufn)
  call timer_start(0, function('s:Wipe', [a:bufn]))
endfunction

function! s:Wipe(bufn, timer)
  if bufexists(a:bufn) && empty(win_findbuf(a:bufn)) && !getbufvar(a:bufn, '&modified')
    exec "silent! bwipeout " . a:bufn
  endif
endfunction

function! s:gotoline()
  let file = bufname("%")

  " Handle git diff paths: a/file or b/file
  " If 'a' or 'b' directory doesn't exist, strip the prefix
  let git_matches = matchlist(file, '^\([ab]\)/\(.*\)')
  if len(git_matches) != 0
    let prefix_dir = git_matches[1]
    let path_without_prefix = git_matches[2]
    " If the 'a' or 'b' directory doesn't exist, use the path without prefix
    if !isdirectory(prefix_dir)
      let file = path_without_prefix
      " If the stripped path is directly readable (no :line), open it now
      if filereadable(file) && !filereadable(bufname("%"))
        let l:bufn = bufnr("%")
        exec "edit " . fnameescape(file)
        call s:WipeLater(l:bufn)
        return
      endif
    endif
  endif

  let newfile = ""

  " filename:row[:]
  let matches = matchlist(file, '\(.*\):\(\d\+\):\?$')
  if len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = matches[2]
    let col = ""
  endif

  " filename:row:col[:]
  let matches = matchlist(file, '\(.*\):\(\d\+\):\(\d\+\):\?$')
  if len(newfile) == 0 && len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = matches[2]
    let col = matches[3]
  endif

  " filename:
  let matches = matchlist(file, '\(.*\):$')
  if len(newfile) == 0 && len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = ""
    let col = ""
  endif

  if len(newfile) > 0
    let l:bufn = bufnr("%")
    exec "edit " . fnameescape(newfile)
    if len(col) > 0
      call cursor(row, col)
    elseif !empty(row)
      exec ":" . row
    endif
    call s:WipeLater(l:bufn)
    if !empty(row) && foldlevel(row) > 0
      exec ":foldopen!"
    endif
    return
  endif
endfunction

endif  " has("autocmd")
