" Delete buffers while preserving window layout (Vim version of mini.bufremove).
" Custom tweak: if deleting the last listed buffer, also close the current window.

if exists('g:bufdelete_vim_loaded')
  finish
endif
let g:bufdelete_vim_loaded = 1

" Neovim uses mini.bufremove configured in nvim/lua/plugins/init.lua.
if has('nvim')
  finish
endif

function! s:is_listed_buffer(bufnr) abort
  return a:bufnr > 0 && buflisted(a:bufnr)
endfunction

function! s:listed_buffer_count() abort
  if exists('*getbufinfo')
    return len(getbufinfo({'buflisted': 1}))
  endif

  let l:count = 0
  for l:bnr in range(1, bufnr('$'))
    if buflisted(l:bnr)
      let l:count += 1
    endif
  endfor
  return l:count
endfunction

function! s:switch_window_off_target(target) abort
  let l:cur = bufnr('%')
  if l:cur != a:target
    return 1
  endif

  let l:alt = bufnr('#')
  if s:is_listed_buffer(l:alt) && l:alt != l:cur
    execute 'hide buffer' l:alt
    return 1
  endif

  let l:before = bufnr('%')
  silent! execute 'hide bprevious'
  if bufnr('%') != l:before
    return 1
  endif

  if exists('*getbufinfo')
    for l:info in getbufinfo({'buflisted': 1})
      if l:info.bufnr != l:cur
        execute 'hide buffer' l:info.bufnr
        return 1
      endif
    endfor
  else
    for l:bnr in range(1, bufnr('$'))
      if buflisted(l:bnr) && l:bnr != l:cur
        execute 'hide buffer' l:bnr
        return 1
      endif
    endfor
  endif

  " Leave unnamed to allow buffer reuse.
  hide enew
  return 1
endfunction

function! s:unshow_buffer_everywhere(target) abort
  let l:orig_win = win_getid()
  let l:wins = exists('*win_findbuf') ? win_findbuf(a:target) : [l:orig_win]

  for l:winid in l:wins
    if !win_gotoid(l:winid)
      continue
    endif
    if exists('*getcmdwintype') && getcmdwintype() !=# ''
      close!
      continue
    endif
    call s:switch_window_off_target(a:target)
  endfor

  call win_gotoid(l:orig_win)
endfunction

function! s:bufdelete(force) abort
  let l:target = bufnr('%')
  if l:target <= 0 || !bufexists(l:target)
    return 0
  endif

  let l:is_last_listed = s:is_listed_buffer(l:target) && s:listed_buffer_count() <= 1

  " Settle unsaved changes before any window switches away from the buffer,
  " so that Cancel (or an error) leaves everything as it was. :bdelete would
  " ask only after the windows were already switched. Like mini.bufremove.
  let l:discard = a:force
  if !a:force && getbufvar(l:target, '&modified') && getbufvar(l:target, '&buftype') ==# ''
    if !&confirm
      echohl ErrorMsg
      echom 'E89: No write since last change for buffer ' . l:target . ' (add ! to override)'
      echohl None
      return 0
    endif
    let l:name = bufname(l:target) ==# '' ? 'Untitled' : bufname(l:target)
    let l:choice = confirm('Save changes to "' . l:name . '"?', "&Yes\n&No\n&Cancel", 1, 'Question')
    if l:choice == 1
      try
        write
      catch
        echohl ErrorMsg
        echom v:exception
        echohl None
        return 0
      endtry
    elseif l:choice == 2
      let l:discard = 1
    else
      return 0
    endif
  endif

  call s:unshow_buffer_everywhere(l:target)

  try
    if l:discard
      execute 'bdelete!' l:target
    else
      execute 'bdelete' l:target
    endif
  catch /^Vim\%((\a\+)\)\=:E516:/
  catch /^Vim\%((\a\+)\)\=:E517:/
  catch /^Vim\%((\a\+)\)\=:E11:/
  catch
    echohl ErrorMsg
    echom v:exception
    echohl None
    return 0
  endtry

  " Only once it's really gone: :bdelete can still fail or be cancelled
  " (e.g. a terminal job's prompt), and then the buffer stays listed
  if l:is_last_listed && !buflisted(l:target)
    if a:force
      quit!
    else
      quit
    endif
  endif

  return 1
endfunction

command! -bar -bang Bd call <SID>bufdelete(<bang>0)

" Also covers `bd!`: typing `!` already expands `bd` to `Bd`
cabbr <expr> bd (getcmdtype() ==# ':' && getcmdline() ==# 'bd') ? 'Bd' : 'bd'

nnoremap <silent> <leader>bd :Bd<CR>
nnoremap <silent> <C-Q> :Bd<CR>
