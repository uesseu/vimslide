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

function! slide#get_heredoc_text(line)
  let s:sep = split(getline(a:line), '"')
  return len(s:sep) == 0 ? '' : trim(s:sep[-1])
endfunction


function! slide#_goto_vim_heredoc(showline, eof, sep)
  let s:showline = a:showline
  while 1
    let s:mcurline = trim(getline(s:showline))
    if match(s:mcurline, a:sep) == 0
      return a:showline
    endif
    let s:split_line = split(s:mcurline, ' ')
    if trim(s:split_line[0]) == 'let' && trim(s:split_line[1]) == trim(a:eof)
      break
    endif
    let s:showline = s:showline + 1
  endwhile
  return s:showline + 1
endfunction

function! slide#_goto_heredoc(showline, eof, sep)
  let s:showline = a:showline
  let s:line = getline(s:showline)
  while 1
    let s:mcurline = getline(s:showline)
    if match(s:mcurline, a:sep) == 0
      return a:showline
    endif
    if a:eof != '' && trim(s:line) == trim(a:eof)
      break
    endif
    let s:line = getline(s:showline)
    let s:showline = s:showline + 1
  endwhile
  return s:showline
endfunction

function! slide#goto(sep='"""', up=0)
  " Return -1 if stop mode. Else, return line to run.
  if g:slide#is_waiting
    return -1
  endif
  if a:up
    let s:curline=search(a:sep, 'b')
    let s:curline=search(a:sep, 'b')
  else
    let s:curline = search(a:sep)
  endif
  let s:eof = slide#get_heredoc_text(s:curline)
  let s:showline = s:curline + 1
  if s:eof == ''
    let s:showline = slide#_goto_heredoc(s:showline, s:eof, a:sep)
  elseif s:eof[0] == '@'
    let s:showline = slide#_goto_vim_heredoc(s:showline, s:eof[1:], a:sep)
  else
    let s:showline = slide#_goto_heredoc(s:showline, s:eof, a:sep)
  endif
  call cursor(s:showline, 0)
  exec "norm z\n"
  return s:curline + 1
endfunction

function slide#_is_wait_line(line)
  let s:split_line = split(getline(a:line), ' ')
  if len(s:split_line) < 2
    return 0
  elseif trim(s:split_line[0]) == 'call' && trim(s:split_line[1])[:9] == 'slide#wait'
    return 1
  endif
  return 0
endfunction

function slide#_run_heredoc_based(curline, eof, sep)
  let s:curline = a:curline
  let s:command = ''
  while s:curline < line('$')
    " Stop if wait mode
    if slide#_is_wait_line(s:curline) == 1
      let g:slide#current_line = s:curline + 1
      exec $"{a:curline},{s:curline}source"
      return
    elseif trim(getline(s:curline)) == trim(a:eof)
      exec $"{a:curline},{s:curline-1}source"
      break
    elseif match(getline(s:curline), trim(a:sep)) > -1
      exec $"{a:curline},{s:curline}source"
      return
    endif
    let s:curline = s:curline + 1
  endwhile
endfunction

function slide#run(line=0, sep='^"""')
  if a:line == -1
    " When it is in waiting mode.
    let g:slide#is_waiting = 0
    let s:line = g:slide#current_line
    let g:slide#eof = slide#get_heredoc_text(search(a:sep, 'bn'))
  else
    let s:line = a:line == 0 ? search(a:sep, 'bn')+1 : a:line
    let g:slide#eof = slide#get_heredoc_text(s:line-1)
  endif
  if g:slide#eof == ''
    return
  elseif g:slide_script_enable == 0
    return
  endif
  call slide#_run_heredoc_based(s:line, g:slide#eof, a:sep)
endfunction


let g:slide#keys = []
let g:slide#command_num = 0

function slide#start(sep_num=3, forward='<down>', backward='<up>')
  set nocompatible
  set noruler
  set nonumber
  set laststatus=0
  set nolist
  set noshowcmd
  set nocursorline
  if has('nvim')
    highlight Normal guibg=none
    highlight NonText guibg=none
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none
    highlight NormalNC guibg=none
    highlight NormalSB guibg=none
  else
    highlight Normal ctermbg=none
    highlight NonText ctermbg=none
    highlight LineNr ctermbg=none
    highlight Folded ctermbg=none
    highlight EndOfBuffer ctermbg=none
  endif
  call slide#set_key(a:forward, 0, a:sep_num)
  call slide#set_key(a:backward, 1, a:sep_num)
endfunction


function slide#set_key(key, direction=0, sep_num=3)
  let g:slide#keys = g:slide#keys +
        \[{'direction': a:direction,
        \  'sep': '^'.repeat('"', a:sep_num),
        \}]
  exec $"nnoremap {a:key} :call slide#next({g:slide#command_num})<CR>:<ESC>"
  let g:slide#command_num = g:slide#command_num + 1
endfunction

function slide#next(num)
  let s:arg = g:slide#keys[a:num]
  call slide#run(slide#goto(s:arg['sep'], s:arg['direction']),s:arg['sep'])
endfunction

function slide#wait()
  let g:slide#is_waiting = 1
endfunction

function slide#put_text(line, text)
  call setline(line('.') + a:line, a:text)
endfunction

function slide#hide_cursor()
  let s:echoraw = has('nvim')
        \? {str -> chansend(v:stderr, str)}
        \: {str->echoraw(str)}
  call s:echoraw("\x1b[6 q")
endfunction

function slide#_get_pos_percent(direction, pos)
  let s:whole_comm = a:direction == 'x' ? &columns : &lines
  return a:pos * 100 / s:whole_comm
endfunction

function slide#image(fname, x=0, y=0, width=0, height=0) 
  let s:echoraw = has('nvim')
        \? {str -> chansend(v:stderr, str)}
        \: {str->echoraw(str)}
  call s:echoraw("\x1b[s")
  if g:slide#terminal == 'sixel'
    let s:y = slide#_get_pos_percent('y', a:y)
    let s:x = slide#_get_pos_percent('x', a:x)
    let s:width = a:width != 0 ? slide#_get_pos_percent('x', a:width): 0
    let s:height = a:height != 0 ? slide#_get_pos_percent('y', a:height): 0
    call s:echoraw($"\x1b[{s:y};{s:x}H")
    let s:width_comm = a:width != 0 ? $" -w {s:width}%" : ' -w auto'
    let s:height_comm = a:height != 0 ? $" -h {s:height}%" : ' -h auto'
    call s:echoraw(system($"img2sixel {a:fname}{s:width_comm}{s:height_comm}"))
    call s:echoraw("\x1b[u")
  elseif g:slide#terminal == 'wezterm-iterm'
    let s:width = a:width != 0 ? slide#_get_pos_percent('x', a:width): 0
    let s:height = a:height != 0 ? slide#_get_pos_percent('y', a:height): 0
    let s:y = slide#_get_pos_percent('y', a:y)
    let s:x = slide#_get_pos_percent('x', a:x)
    let s:width = a:width != 0 ? $" --width {a:width}" : ''
    let s:height = a:height != 0 ? $" --height {a:height}" : ''
    call s:echoraw(system($"wezterm imgcat {a:fname}{s:width}{s:height} --position={s:x},{s:y}"))
  elseif g:slide#terminal == 'kitty'
    if a:width != 0 && a:width != 0
      let s:attr = $"--place {a:width}x{a:height}@{a:x}x{a:y}"
    else
      let s:attr = ""
    endif
    call system($'kitten icat {s:attr} {a:fname} >/dev/tty </dev/tty')
  endif
endfunction

function slide#clear_image()
  redraw!
endfunction

function slide#do_nothing(arg)
  return 0
endfunction

func! slide#callback_echo(channel)
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    echomsg ch_read(a:channel)
  endwhile
endfunc


func! slide#wait_sh(time, command, callback='slide#do_nothing')
  let s:command=[$"sleep {a:time}", a:command]
  let s:command = join(s:command, ';')
  let job = job_start(['sh', '-c', s:command], {'close_cb': a:callback})
  return job
endfunction

func! slide#wait_vim(time, tmpcommand)
  let s:tmpcommand = a:tmpcommand
  func! TmpFunc(m)
    exec s:tmpcommand
  endfun
  let job = timer_start(float2nr(a:time*1000), 'TmpFunc')
  return job
endfunction


command! -nargs=? SlideStart call slide#start(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo
