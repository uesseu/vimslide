scriptencoding utf-8
" vimslide
" Last Change:	2024 Nov 03
" Maintainer:	Shoichiro Nakanishi <sheepwing@kyudai.jp>
" License:	Mit licence

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_vimslide')
  finish
endif
let g:loaded_vimslide = 1
let g:slide_script_enable = 1
let g:slide#is_waiting = 0
let g:slide#current_line = 1
" iterm, sixel, kitty, wezterm-iterm
if !exists('g:slide#terminal')
  let g:slide#terminal = 'sixel'
endif


let g:slide#keys = []
let g:slide#command_num = 0


command -nargs=? SlideStart call slide#start(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo
