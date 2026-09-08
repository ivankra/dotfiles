" GUI-only settings. Has to be in vimscript - no ginit.lua.

set mouse=a                       " Enable mouse in all modes

if exists('+guioptions')
  set guioptions+=d               " Use dark theme variant
endif

" set guifont=Iosevka\ NFM:h12:w57
" nvim-qt doesn't support fallbacks so check with system('fc-match ...')
if exists(':GuiFont')
  function! s:HasFont(name) abort
    if !executable('fc-match')
      return 1
    endif
    let l:got = system('fc-match -f "%{family}" ' . shellescape(a:name))
    return l:got =~? '\V' . escape(a:name, '\')
  endfunction

  for s:font in ['Iosevka NFM', 'Iosevka Nerd Font Mono', 'Iosevka']
    if s:HasFont(s:font)
      execute 'GuiFont! ' . s:font . ':h12'
      break
    endif
  endfor
endif
