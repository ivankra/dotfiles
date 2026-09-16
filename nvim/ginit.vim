" GUI-only settings. Has to be in vimscript - no ginit.lua.

set mouse=a                       " Enable mouse in all modes

if exists('+guioptions')
  set guioptions+=d               " Use dark theme variant
endif

let s:fonts = ['Iosevka NFM', 'Iosevka']

" nvim-qt version as a number (0.2.20 -> 20020), 0 if unknown (reported since 0.2.11).
" Available once nvim-qt has attached, which is the case in ginit.vim.
function! s:NvimQtVersion() abort
  for l:ui in nvim_list_uis()
    let l:client = get(nvim_get_chan_info(get(l:ui, 'chan', 0)), 'client', {})
    if get(l:client, 'name', '') ==# 'nvim-qt'
      let l:v = l:client.version
      return str2nr(l:v.major) * 1000000 + str2nr(l:v.minor) * 10000 + str2nr(l:v.patch)
    endif
  endfor
  return 0
endfunction

if s:NvimQtVersion() >= 20020
  " 0.2.20+ uses Qt6 (weight scale 1-1000, Medium = 500) and supports
  " guifont with fallback lists
  let &guifont = join(map(copy(s:fonts), 'v:val . ":h12:w500"'), ',')
else
  " Older: Qt5 (weight scale 0-99, Medium = 57) and no fallback lists
  function! s:HasFont(name) abort
    if !executable('fc-match')
      return 1
    endif
    let l:got = system('fc-match -f "%{family}" ' . shellescape(a:name))
    return l:got =~? '\V' . escape(a:name, '\')
  endfunction

  for s:font in s:fonts
    if s:HasFont(s:font)
      let &guifont = s:font . ':h12:w57'
      break
    endif
  endfor
endif

" Workaround for https://github.com/equalsraf/neovim-qt/issues/251
" Resize a tiny window with xdotool
function! s:FixTinyWindow(timer) abort
  if (&columns >= 80 && &lines >= 24) || !executable('xdotool')
    return
  endif
  call timer_stop(a:timer)
  for l:ui in nvim_list_uis()
    let l:client = get(nvim_get_chan_info(get(l:ui, 'chan', 0)), 'client', {})
    let l:id = get(get(l:client, 'attributes', {}), 'windowid', 0)
    if get(l:client, 'name', '') ==# 'nvim-qt' && l:id
      call jobstart(['xdotool', 'windowsize', string(l:id), '50%', '80%'])
    endif
  endfor
endfunction

call timer_start(100, function('s:FixTinyWindow'), {'repeat': 3})
