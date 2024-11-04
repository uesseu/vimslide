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


function! GoToSlide(sep, up, command_flag='.')
  if a:up
    let s:curline=search(a:sep, 'b')
    let s:curline=search(a:sep, 'b')
  else
    let s:curline = search(a:sep)
  endif
  let s:showline = s:curline + 1
  while 1
    let s:line = getline(s:showline)
    if s:line[0] == a:command_flag
      while getline(s:showline)[strlen(getline(s:showline))-1] == "\\"
        let s:showline = s:showline + 1
      endwhile
      let s:showline = s:showline + 1
    else
      break
    endif
  endwhile
  call cursor(s:showline, 0)
  return s:curline
  "call RunCommand(s:curline+1, a:command_flag)
endfunction

function RunCommand(line, command_flag)
  let s:command = ''
  let s:curline = a:line
  while 1
    let s:str = getline(s:curline)
    " Run shell if head is '!'
    if s:str[0] == a:command_flag
      while s:str[strlen(s:str)-1] == "\\"
        let s:command = s:command . s:str[:-1]
        let s:curline = s:curline + 1
        let s:str = getline(s:curline)
      endwhile
      let s:command = s:command . s:str
      if s:command[0] == a:command_flag
        silent! exec s:command[1:]
      endif
      let s:command = ''
    " Run vim script if head is '.'
    else
      break
    endif
    let s:curline = s:curline + 1
  endwhile
  redraw!
endfunction


function SlideStart(forward, backward, sep, command_flag='.')
  set nocompatible
  set noruler
  set nonumber
  set laststatus=0
  set nolist
  set noshowcmd
  if has('nvim')
    highlight Normal guibg=none
    highlight NonText guibg=none
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none
    highlight NormalNC guibg=none
    highlight NormalSB guibg=none
  endif
  exec "nnoremap ".a:forward." :let Line=GoToSlide('".a:sep."', 0, '".a:command_flag."')+1<CR>z<CR>0:redraw!<CR>:call RunCommand(Line, '.')<CR>"
  exec "nnoremap ".a:backward." :let Line=GoToSlide('".a:sep."', 1, '".a:command_flag."')+1<CR>z<CR>0:redraw!<CR>:call RunCommand(Line, '.')<CR>"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
