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
  let sep = getline(a:line)->split('"')
  return len(sep) == 0 ? '' : trim(sep[-1])
endfunction


function! slide#_goto_vim_heredoc(showline, eof, sep)
  let showline = a:showline
  while 1
    let mcurline = trim(getline(showline))
    if match(mcurline, a:sep) == 0
      return a:showline
    endif
    let split_line = split(mcurline, ' ')
    if len(split_line) > 1 && trim(split_line[0]) == 'let' && split(split_line[1], '=')[0] == trim(a:eof)
      break
    endif
    let showline = showline + 1
  endwhile
  return showline + 1
endfunction

function! slide#_goto_heredoc(showline, eof, sep)
  let showline = a:showline
  let line = getline(showline)
  while 1
    let mcurline = getline(showline)
    if match(mcurline, a:sep) == 0
      return a:showline
    endif
    if a:eof != '' && trim(line) == trim(a:eof)
      break
    endif
    let line = getline(showline)
    let showline = showline + 1
  endwhile
  return showline
endfunction

function! slide#goto(sep='"""', up=0)
  " Return -1 if stop mode. Else, return line to run.
  if g:slide#is_waiting
    return -1
  endif
  if a:up
    let curline=search(a:sep, 'b')
    let curline=search(a:sep, 'b')
  else
    let curline = search(a:sep)
  endif
  let eof = slide#get_heredoc_text(curline)
  let showline = curline + 1
  if eof == ''
    let showline = slide#_goto_heredoc(showline, eof, a:sep)
  elseif eof[0] == '@'
    let showline = slide#_goto_vim_heredoc(showline, eof[1:], a:sep)
  else
    let showline = slide#_goto_heredoc(showline, eof, a:sep)
  endif
  call cursor(showline, 0)
  exec "norm z\n"
  return curline + 1
endfunction

function slide#_is_wait_line(line)
  let split_line = split(getline(a:line), ' ')
  if len(split_line) < 2
    return 0
  elseif trim(split_line[0]) == 'call' && trim(split_line[1])[:9] == 'slide#wait'
    return 1
  endif
  return 0
endfunction

function slide#_run_heredoc_based(curline, eof, sep)
  let curline = a:curline
  let command = ''
  while curline < line('$') + 1
    " Stop if wait mode
    if slide#_is_wait_line(curline) == 1
      let g:slide#current_line = curline + 1
      exec $"{a:curline},{curline}source"
      return
    elseif curline->getline()->trim() == a:eof->trim()
      exec $"{a:curline},{curline-1}source"
      break
    elseif curline->getline()->match(a:sep->trim()) > -1
      exec $"{a:curline},{curline}source"
      return
    endif
    let curline = curline + 1
  endwhile
  exec $"{a:curline},{curline-1}source"
endfunction

function slide#run(line=0, sep='^"""')
  if a:line == -1
    " When it is in waiting mode.
    let g:slide#is_waiting = 0
    let line = g:slide#current_line
    let g:slide#eof = slide#get_heredoc_text(search(a:sep, 'bn'))
  else
    let line = a:line == 0 ? search(a:sep, 'bn')+1 : a:line
    let g:slide#eof = slide#get_heredoc_text(line-1)
  endif
  if g:slide#eof == ''
    return
  elseif g:slide_script_enable == 0
    return
  endif
  call slide#_run_heredoc_based(line, g:slide#eof, a:sep)
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
  let arg = g:slide#keys[a:num]
  call slide#run(slide#goto(arg['sep'], arg['direction']),arg['sep'])
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
  let whole_comm = a:direction == 'x' ? &columns : &lines
  return a:pos * 100 / whole_comm
endfunction

function! slide#chip(fname, compose='over', geometry='+0+0')
  return #{fname: a:fname, compose: a:compose, geometry: a:geometry}
endfunction

function! slide#canvas(images, output='tmp', type='file')
  let code = $"magick {a:images[0]["fname"]} "
  let suffix = ''
  if a:type == 'fifo'
    call system($'rm {a:output}')
    call system($'mkfifo {a:output}')
    let suffix = '&'
  endif
  for image in a:images[1:]
    let code = code.$"  {image['fname']} -geometry {image['geometry']}
          \ -compose {image['compose']} -composite  "
  endfor
  let result = #{fname: a:output, type: a:type}
  let result["job"] = system(code." -format png - " . $" > {a:output} {suffix}")
  return result
endfunction

function slide#image(fname, pos=[0, 0, 0, 0])
  if type(a:fname) == v:t_dict
    let fname = $"< {a:fname["fname"]}"
    let is_canvas = 1
  else
    let arg = trim(a:fname)
    let kitten_suffix = arg[len(arg)-1] != '|' ? a:fname : " </dev/tty"
    let fname = arg[len(arg)-1] == '|' ? a:fname : $"< {a:fname}"
    let is_canvas = 0
  endif
  let s:echoraw = has('nvim')
        \? {str -> chansend(v:stderr, str)}
        \: {str->echoraw(str)}
  call s:echoraw("\x1b[s")
  if g:slide#terminal == 'sixel'
    let y = slide#_get_pos_percent('y', a:pos[1])
    let x = slide#_get_pos_percent('x', a:pos[0])
    let width = a:pos[2] != 0 ? slide#_get_pos_percent('x', a:pos[2]): 0
    let height = a:pos[3] != 0 ? slide#_get_pos_percent('y', a:pos[3]): 0
    call s:echoraw($"\x1b[{y};{x}H")
    let width_comm = a:pos[2] != 0 ? $" -w {width}%" : ' -w auto'
    let height_comm = a:pos[3] != 0 ? $" -h {height}%" : ' -h auto'
    call s:echoraw(system($"{fname} img2sixel {width_comm}{height_comm}"))
    call s:echoraw("\x1b[u")
  elseif g:slide#terminal == 'wezterm-iterm'
    let width = a:pos[2] != 0 ? slide#_get_pos_percent('x', a:pos[2]): 0
    let height = a:pos[3] != 0 ? slide#_get_pos_percent('y', a:pos[3]): 0
    let y = slide#_get_pos_percent('y', a:pos[1])
    let x = slide#_get_pos_percent('x', a:pos[0])
    let width = a:pos[2] != 0 ? $" --width {a:pos[2]}" : ''
    let height = a:pos[3] != 0 ? $" --height {a:pos[3]}" : ''
    call s:echoraw(system($"{fname} wezterm imgcat {width}{height} --position={x},{y}"))
  elseif g:slide#terminal == 'kitty'
    if a:pos[2] != 0 && a:pos[2] != 0
      let attr = $"--place {a:pos[2]}x{a:pos[3]}@{a:pos[0]}x{a:pos[1]}"
    else
      let attr = ""
    endif
    call system($'{fname} kitten icat {attr} >/dev/tty ')
  endif
  if a:fname["type"] == 'fifo'
    call system($'rm {a:fname["fname"]}')
  endif
endfunction

function slide#clear_image()
  redraw!
endfunction

func! slide#callback_echo(channel)
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    echomsg ch_read(a:channel)
  endwhile
endfunc


function! slide#_wrapper(x, y)
  exec a:x
endfunction

command -nargs=? SlideStart call slide#start(<args>)

let &cpo = s:save_cpo
unlet s:save_cpo
