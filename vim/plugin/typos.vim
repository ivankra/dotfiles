scriptencoding utf-8

" Shift held too long: :W, :Wq etc. as their lowercase commands, with ! and
" filename completion
if has("user_commands") || has("nvim")
  com! -bang -nargs=? -complete=file Tabe tabedit<bang> <args>
  com! -bang -nargs=? -complete=file E e<bang> <args>
  com! -bang -nargs=? -complete=file W w<bang> <args>
  com! -bang -nargs=? -complete=file Wq wq<bang> <args>
  com! -bang Q q<bang>
  com! -bang Qa qa<bang>
  com! -bang Wa wa<bang>
  com! -bang Wqa wqa<bang>
endif

" Russian ЙЦУКЕН layout: commands typed with it act as on QWERTY, also the
" second key of gg, zz, ZZ, marks (mф = ma) and registers ("фy). Not in
" Insert/Command-line mode, and not for the char after f/t/r, which is text.
" Unlike :map, also leaves Select mode typing alone.
" nolangremap: don't apply it to the result of mappings (defaults.vim and
" nvim's default; set here in case defaults.vim wasn't loaded).
if exists("+langmap")
  if exists("+langremap")
    set nolangremap
  endif
  " ; , " need a backslash in 'langmap'
  let &langmap = 'ЙЦУКЕНГШЩЗФЫВАПРОЛДЯЧСМИТЬ;QWERTYUIOPASDFGHJKLZXCVBNM,'
        \ . 'йцукенгшщзфывапролдячсмить;qwertyuiopasdfghjklzxcvbnm,'
        \ . 'х[,ъ],Х{,Ъ},ж\;,Ж:,э'',Э\",б\,,Б<,ю.,Ю>,ё`,Ё~'
endif
