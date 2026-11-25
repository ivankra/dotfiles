" Colorschemes, vim's version of nvim/lua/plugins/colorscheme.lua.
" Vim only: it isn't linked into nvim/plugin/.
"
" At startup, the first of these that works:
"   - a scheme given with -c
"   - the last one picked with :colorscheme
"   - on a light terminal, a light default (all dotfiles themes are dark)
"   - the dotfiles theme (~/.dotfiles/themes/)
"   - a default
"
" Applied on VimEnter, not right away: packages (pack/*/start) join
" 'runtimepath' only after plugin/ files load, and some schemes need files
" from them (dracula's autoload/ and dracula_base.vim).
if exists("g:colorscheme_vim_loaded") || !has("autocmd")
  finish
endif
let g:colorscheme_vim_loaded = 1

" Per-scheme options, for whichever way a scheme gets applied
let g:dracula_italic = 0
let g:gruvbox_contrast_dark = "hard"
let g:gruvbox_italic = 0
let g:gruvbox_italicize_comments = 0
let g:sonokai_enable_italic = 0
let g:sonokai_disable_italic_comment = 1

augroup StickyColorscheme
  autocmd!
augroup END

" Last picked scheme and 'background'. `setup.sh --theme` deletes it. In XDG
" state, where vim's own $VIMRUNTIME/xdg.vim puts viminfo. Separate from
" nvim's (~/.local/state/nvim/colorscheme).
let s:save_file = (empty($XDG_STATE_HOME) ? expand("~/.local/state") : $XDG_STATE_HOME)
      \ . "/vim/colorscheme"

" Default theme to use if setup.sh hasn't been run
let s:default_theme = "dracula-dark"
" On a light terminal, instead of the dotfiles theme (all are dark)
let s:default_light_theme = "fruidle"

" Light terminal: vim reads $COLORFGBG ("fg;bg") into 'background' itself.
" Unset: assume dark.
let s:light_terminal = $COLORFGBG != "" && &background ==# "light" && !has("gui_running")
let &background = s:light_terminal ? "light" : "dark"  " for -c schemes too

" Returns 0 if the scheme is missing or broken.
function! s:ApplyColorscheme(name, background) abort
  if a:name == ""
    return 0
  endif
  try
    unlet! g:colors_name  " else setting 'background' reloads it
    let &background = a:background
    execute "colorscheme" fnameescape(a:name)
    return 1
  catch
    return 0
  endtry
endfunction

" Saves picks, 'background' changes too (they reload the scheme).
function! s:SaveColorscheme() abort
  " colors_name is the variant shown (tokyonight-moon + bg=light:
  " tokyonight-day), but may be just the family or not a scheme.
  let name = get(g:, "colors_name", "")
  let loaded = expand("<amatch>")
  if index(getcompletion(name, "color"), name) < 0 || stridx(loaded, name . "-") == 0
    let name = loaded
  endif
  if name != ""  " empty after a bare :doautocmd ColorScheme
    call mkdir(fnamemodify(s:save_file, ":h"), "p")
    call writefile([name, &background], s:save_file)
  endif
endfunction

function! s:InitColorscheme() abort
  " 1. One given with -c (runs before VimEnter), else the last pick
  let saved = filereadable(s:save_file) ? readfile(s:save_file) : []
  if exists("g:colors_name") || s:ApplyColorscheme(get(saved, 0, ""), get(saved, 1, ""))
    return
  endif

  " 2. On a light terminal, the light default instead of the dark ones below
  if s:light_terminal
    call s:ApplyColorscheme(s:default_light_theme, "light")
    return
  endif

  " 3. The dotfiles theme: setup.sh links ~/.config/theme to
  " ~/.dotfiles/themes/<name>, whose vim.vim applies its scheme
  let theme = expand("~/.config/theme/vim.vim")
  if filereadable(theme)
    unlet! g:colors_name
    set background=dark  " all are dark themes, not all vim.vim set it
    try
      execute "source" fnameescape(theme)
      return
    catch
      echohl WarningMsg
      echomsg "No colorscheme for theme " . fnamemodify(resolve(expand("~/.config/theme")), ":t")
      echohl None
    endtry
  endif

  " 4. The default theme, else vim's own
  if !s:ApplyColorscheme(s:default_theme, "dark")
    call s:ApplyColorscheme("default", "dark")
  endif
endfunction

" ++nested: ColorScheme autocmds (of plugins too) see the startup scheme.
" Saving starts after it, so applying it doesn't count.
autocmd StickyColorscheme VimEnter * ++once ++nested call s:InitColorscheme()
      \ | autocmd StickyColorscheme ColorScheme * call s:SaveColorscheme()
