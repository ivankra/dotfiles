" Interprets filenames of the form <filename>:<line>[:<col>] as the instruction
" to open <filename> (if it exists) and position the cursor at a given line number.
"
" Also strips prefix in git diff paths (a/file, b/file).

if has("autocmd")

autocmd! BufNewFile *:* nested call s:gotoline()
autocmd! BufNewFile a/*,b/* nested call s:gotoline()

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
        exec ":e " . file
        exec ":bdelete " . l:bufn
        return
      endif
    endif
  endif

  let newfile = ""

  " filename:row[:]
  let matches = matchlist(file, '\(.*\):\(\d\+\):\?')
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
  let matches = matchlist(file, '\(.*\):')
  if len(newfile) == 0 && len(matches) != 0 && filereadable(matches[1]) && !filereadable(file)
    let newfile = matches[1]
    let row = matches[2]
    let col = ""
  endif

  if len(newfile) > 0
    let l:bufn = bufnr("%")
    exec ":e " . newfile
    if len(col) > 0
      call cursor(row, col)
    else
      exec ":" . row
    endif
    exec ":bdelete " . l:bufn
    if foldlevel(row) > 0
      exec ":foldopen!"
    endif
    return
  endif
endfunction

endif  " has("autocmd")
