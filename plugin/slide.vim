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
let g:slide#is_stopped = 0
let g:slide#current_line = 1

function! slide#goto(sep='---', up=0, command_flag='.')
  " Return -1 if stop mode. Else, return line to run.
  if g:slide#is_stopped
    redraw!
    return -1
  endif
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
  exec "norm z\n"
  exec "redraw!"
  return s:curline + 1
  "call slide#run(s:curline+1, a:command_flag)
endfunction


function slide#run(line=0, command_flag='.')
  if a:line == 0
    let s:line = search(a:sep, 'b')+1
  elseif a:line == -1
    let g:slide#is_stopped = 0
    let s:line = g:slide#current_line
  else
    let s:line = a:line
  endif
  if g:slide_script_enable == 0
    redraw!
    return
  endif
  let s:command = ''
  let s:curline = s:line
  while 1
    " Stop if stop mode
    if g:slide#is_stopped == 1
      let g:slide#current_line = s:curline
      return
    endif
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


function slide#start(forward='<down>', backward='<up>', sep='---', command_flag='.')
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
  exec "nnoremap ".a:forward." :silent! call slide#run(slide#goto('".a:sep."', 0, '".a:command_flag."'), '.')<CR>"
  exec "nnoremap ".a:backward." :silent! call slide#run(slide#goto('".a:sep."', 1, '".a:command_flag."'), '.')<CR>"
endfunction

function slide#stop()
  let g:slide#is_stopped = 1
  redraw!
endfunction

function slide#put_text(line, text)
  call setline(line('.') + a:line, a:text)
  redraw!
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
