" Ctrl+/ toggles line comments, like VS Code: gcc / visual gc, built into
" nvim 0.10+; in Vim, the comment package (packadd! in vimrc), when this Vim
" has it. Not to be confused with that package's own plugin/comment.vim.

" Cursor shift for text after the indentation when gcc turned line a:before
" into a:after: the width of the opening marker that was added (+) or removed
" (-). Not the whole length change: a closing marker (HTML's ` -->`) goes after
" the cursor.
function! s:CommentShift(before, after, indent) abort
  if strlen(a:after) == strlen(a:before)
    return 0
  endif
  let [l:long, l:short, l:sign] = strlen(a:after) > strlen(a:before)
        \ ? [a:after, a:before, 1] : [a:before, a:after, -1]
  let l:text = strpart(l:short, a:indent)
  " gcc inserts the parts of 'commentstring': indent . left . text . right.
  " nvim uses them as they are; Vim's comment.vim pads the marker with spaces
  " (/*%s*/ becomes /* %s */).
  let l:cms = has('nvim') ? &commentstring
        \ : substitute(substitute(&commentstring, '\S\zs%s\s*', ' %s', ''), '%s\ze\S', '%s ', '')
  let l:parts = matchlist(l:cms, '^\(.\{-}\)%s\(.*\)$')
  if !empty(l:parts)
    let [l:left, l:right] = l:parts[1:2]
    if l:text ==# ''
      " Blank line: nvim comments it with the unpadded marker (Vim skips it)
      return l:sign * strlen(trim(l:left))
    elseif l:long ==# strpart(l:short, 0, a:indent) . l:left . l:text . l:right
      return l:sign * strlen(l:left)
    endif
  endif
  " Otherwise (nvim: treesitter-injected language with its own commentstring,
  " like JS inside HTML; a marker removed without its padding): where the text
  " starts, after a non-empty marker
  let l:start = stridx(l:long, l:text, a:indent + 1)
  return l:start < 0 ? 0 : l:sign * (l:start - a:indent)
endfunction

" In Insert mode keep typing where you were: gcc moves the cursor to the indent
function! s:CommentInsert() abort
  let [l:lnum, l:col] = [line('.'), col('.') - 1]  " 0-based byte column
  let l:before = getline('.')
  let l:indent = max([0, match(l:before, '\S')])  " where the comment marker goes
  normal gcc
  if l:col >= l:indent
    " Not back into the indentation (cursor was inside a removed marker)
    let l:col = max([l:indent, l:col + s:CommentShift(l:before, getline('.'), l:indent)])
  endif
  call cursor(l:lnum, l:col + 1)
endfunction

" Once gcc exists (Vim: the package's maps are defined when plugins load) and
" GUI vs terminal is known: on VimEnter in Vim, on UIEnter in nvim, where GUIs
" set g:GuiLoaded after attaching.
function! s:MapComment() abort
  if empty(maparg('gcc', 'n', 0, 1))
    return
  endif
  " CLI terminals usually send <C-_> on Ctrl+/. In GUIs it's Ctrl+- (zoom out,
  " vscode.vim's SetupGui()).
  let l:gui = has('gui_running') || get(g:, 'GuiLoaded', 0)
  for l:key in ['<C-/>'] + (l:gui ? [] : ['<C-_>'])
    execute 'nmap' l:key 'gcc'
    execute 'xmap' l:key 'gc'
    execute 'inoremap <silent>' l:key '<Cmd>call <SID>CommentInsert()<CR>'
  endfor
endfunction

augroup CommentKey
  autocmd!
  execute 'autocmd' (has('nvim') ? 'UIEnter' : 'VimEnter') '* ++once call s:MapComment()'
augroup END
