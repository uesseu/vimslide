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
let g:slide#expand = 0
let g:loaded_vimslide = 1
let g:slide_script_enable = 1
let g:slide#is_waiting = 0
let g:slide#current_line = 1
let g:slide#_expanded = ''
let s:_appended_firstline = 0
if !exists('g:slide#minimum_lines')
  let g:slide#minimum_lines = 20
endif
" iterm, sixel, kitty, wezterm-iterm
if !exists('g:slide#terminal')
  let g:slide#terminal = 'sixel'
endif

command -nargs=? SlideStart call slide#start(<args>)
command -nargs=? SlideEnd call slide#end(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo
