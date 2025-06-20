function! slide#get_heredoc_text(line)
  let sep = getline(a:line)->split('"')
  return len(sep) == 0 ? '' : trim(sep[-1])
endfunction

function! slide#_expand_heredoc(current_line, append_num, toggle=1, atmark=1)
  if a:atmark
    let eof = a:current_line->getline()->trim()->split('=<<')[1]->trim()
  else
    let eof = a:current_line->getline()->trim()->split('"')[1]->trim()
  endif
  let n = 0
  while 1
    if getline(a:current_line + n)->trim() == eof
      break
    endif
    let n = n + 1
  endwhile
  if g:slide#minimum_lines == 0
    return
  endif
  if a:toggle == 1
    for j in range(a:append_num)
      call append(n+a:current_line-1, '')
    endfor
  else
    call deletebufline(bufname(),
          \n+a:current_line-a:append_num,
          \n+a:current_line-1)
  endif
endfunction


function! slide#_expand_sep(current_line, append_num, toggle=1)
  let n = a:toggle ? 0 : 1
  while 1
    let br = 0
    for a in g:slide#keys
      if getline(a:current_line + n)->match(a['sep']) == 0
        let br = 1
        break
      endif
    endfor
    if br == 1
      break
    endif
    let n = n + 1
    if n+a:current_line-1 > line('$')
      break
    endif
  endwhile
  if g:slide#minimum_lines == 0
    return
  endif
  if a:toggle == 1
    for j in range(a:append_num)
      call append(n+a:current_line-1, '')
    endfor
  else
    call deletebufline(bufname(),
          \n+a:current_line-a:append_num,
          \n+a:current_line-1)
  endif
endfunction

function! slide#_expand(current_line, append_num, toggle=1)
endfunction

function! slide#_goto_atmark_heredoc(showline, label, sep)
  let showline = a:showline
  while 1
    let mcurline = showline->getline()->trim()
    if match(mcurline, a:sep) == 0
      return a:showline
    endif
    let split_line = mcurline->split(' ')
    if len(split_line) > 1
          \&& trim(split_line[0]) == 'let'
          \&& split(split_line[1], '=')[0] == trim(a:label)
      break
    endif
    let showline = showline + 1
  endwhile
  return showline + 1
endfunction

function! slide#_goto_heredoc(showline, label, sep)
  let showline = a:showline
  let line = getline(showline)
  while 1
    let mcurline = getline(showline)
    if match(mcurline, a:sep) == 0
      return a:showline
    endif
    if a:label != '' && trim(line) == trim(a:label)
      break
    endif
    if showline >= line('$')
      break
    endif
    let line = getline(showline)
    let showline = showline + 1
  endwhile
  return showline
endfunction

function! slide#expand(toggle=1)
  if a:toggle
    let label = slide#get_heredoc_text(curline)
    let showline = curline + 1
    if label == ''
      let showline = slide#_goto_heredoc(showline, label, a:sep)
      call slide#_expand_sep(showline, g:slide#minimum_lines)
      let g:slide#_expanded = 'sep'
      let s:_expanded_line = showline-1
    elseif label[0] == '@'
      let showline = slide#_goto_atmark_heredoc(showline, label[1:], a:sep)
      call slide#_expand_heredoc(showline-1, g:slide#minimum_lines)
      let g:slide#_expanded = 'heredoc'
      let s:_expanded_line = showline-1
    else
      let showline = slide#_goto_heredoc(showline, label, a:sep)
    endif
  else
    if g:slide#_expanded == 'heredoc'
      call slide#_expand_heredoc(s:_expanded_line,
            \g:slide#minimum_lines, a:toggle)
      let g:slide#_expanded = ''
    elseif g:slide#_expanded == 'sep'
      call slide#_expand_sep(s:_expanded_line,
            \g:slide#minimum_lines, a:toggle)
      let g:slide#_expanded = ''
    endif
  endif
endfunction

function! slide#goto(sep='"""', up=0)
  " Return -1 if stop mode. Else, return line to run.
  if g:slide#is_waiting
    return -1
  endif
  if g:slide#_expanded == 'heredoc'
    call slide#_expand_heredoc(s:_expanded_line, g:slide#minimum_lines, 0)
    let g:slide#_expanded = ''
  elseif g:slide#_expanded == 'sep'
    call slide#_expand_sep(s:_expanded_line, g:slide#minimum_lines, 0)
    let g:slide#_expanded = ''
  endif
  if a:up
    let curline=search(a:sep, 'b')
    let curline=search(a:sep, 'b')
  else
    let curline = search(a:sep)
  endif
  let label = slide#get_heredoc_text(curline)
  let showline = curline + 1
  if label == ''
    let showline = slide#_goto_heredoc(showline, label, a:sep)
    call slide#_expand_sep(showline, g:slide#minimum_lines)
    let g:slide#_expanded = 'sep'
    let s:_expanded_line = showline-1
  elseif label[0] == '@'
    let showline = slide#_goto_atmark_heredoc(showline, label[1:], a:sep)
    call slide#_expand_heredoc(showline-1, g:slide#minimum_lines)
    let g:slide#_expanded = 'heredoc'
    let s:_expanded_line = showline-1
  else
    let showline = slide#_goto_heredoc(showline, label, a:sep)
  endif
  call cursor(showline, 0)
  exec "norm z\n"
  return curline + 1
endfunction

function slide#_is_wait_line(line)
  let split_line = getline(a:line)->split(' ')
  if len(split_line) < 2
    return 0
  elseif split_line[0]->trim() == 'call' && split_line[1]->trim()[:9] == 'slide#wait'
    return 1
  endif
  return 0
endfunction

function slide#_run_heredoc_based(curline, label, sep)
  let curline = a:curline
  let command = ''
  while curline < line('$') + 1
    " Stop if wait mode
    if slide#_is_wait_line(curline) == 1
      let g:slide#current_line = curline + 1
      exec $"{a:curline},{curline}source"
      return
    elseif curline->getline()->trim() == a:label->trim()
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
    let label = a:sep->search('bn')->slide#get_heredoc_text()
  else
    let line = a:line == 0 ? a:sep->search('bn')+1 : a:line
    let label = slide#get_heredoc_text(line-1)
  endif
  if label == ''
    return
  elseif g:slide_script_enable == 0
    return
  endif
  call slide#_run_heredoc_based(line, label, a:sep)
endfunction


let g:slide#keys = []
let g:slide#command_num = 0

function slide#start(sep_num=3, forward='<down>', backward='<up>')
  call cursor(1, 0)
  set nocompatible
  set noruler
  set nonumber
  set laststatus=0
  set nolist
  set noshowcmd
  set nocursorline
  set showtabline=0
  set signcolumn=no
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
  if getline('.') != ''
    call append(0, '')
    let g:_appended_firstline = 1
    call cursor(1, 0)
    call slide#next(0)
  endif
  call slide#hide_cursor()
  if $TMUX != ''
    call system('tmux set status off')
  endif
  au VimLeave * call slide#end()
endfunction


function slide#end()
  if g:slide#_expanded == 'heredoc'
    call slide#_expand_heredoc(s:_expanded_line, g:slide#minimum_lines, 0)
    let g:slide#_expanded = ''
  elseif g:slide#_expanded == 'sep'
    call slide#_expand_sep(s:_expanded_line, g:slide#minimum_lines, 0)
    let g:slide#_expanded = ''
  endif
  if g:_appended_firstline == 1
    call deletebufline(bufname(), 1)
    let g:_appended_firstline = 0
  endif
  if $TMUX != ''
    call system('tmux set status on')
  endif
  call slide#show_cursor()
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
  if g:slide#auto_redraw
    redraw!
    mode
  endif
  let arg = g:slide#keys[a:num]
  call slide#goto(arg['sep'], arg['direction'])->slide#run(arg['sep'])
endfunction

function slide#wait()
  let g:slide#is_waiting = 1
endfunction

function slide#put_text(line, text)
  call setline(line('.') + a:line, a:text)
endfunction

function s:hide_cursor_nvim(str)
  execute $"lua vim.api.nvim_out_write('{a:str}'..'\\n')"
endfunction

function slide#hide_cursor()
  let s:echoraw = has('nvim')
        \? {str->s:hide_cursor_nvim(str)}
        \: {str->echoraw(str)}
  call s:echoraw("\e[?25l")
endfunction

function slide#show_cursor()
  let s:echoraw = has('nvim')
        \? {str -> chansend(v:stderr, str)}
        \: {str->echoraw(str)}
  call s:echoraw("\x1b[?25h")
endfunction

function slide#_get_pos_percent(direction, pos)
  let whole_comm = a:direction == 'x' ? &columns : &lines
  return a:pos * 100 / whole_comm
endfunction

function! slide#chip(fname, compose='over', geometry='+0+0')
  return #{fname: a:fname, compose: a:compose, geometry: a:geometry}
endfunction

function! slide#canvas(images, output='tmp.png', type='file')
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
  echo code." -format png - " . $" > {a:output} {suffix}"
  let result["job"] = system(code." -format png - " . $" > {a:output} {suffix}")
  return result
endfunction

function slide#image(fname, pos=[0, 0, 0, 0])
  if g:slide#tty == ""
    let pid = system('ps -o ppid= -p '.getpid())
    let tty = '/dev/'.system('ps -o tty= -p '.pid)
    let tty = tty->trim() == '/dev/?' ? "/dev/tty" : tty
  else
    tty = g:slide#tty
  endif

  if type(a:fname) == v:t_dict
    let fname = $"< {a:fname["fname"]}"
    let is_canvas = 1
  else
    let arg = trim(a:fname)
    let kitten_suffix = arg[len(arg)-1] != '|' ? a:fname : " <".tty
    let fname = arg[len(arg)-1] == '|' ? a:fname : $"< {a:fname}"
    let is_canvas = 0
  endif
  let s:echoraw = has('nvim')
        \? {str -> chansend(v:stderr, str)}
        \: {str -> echoraw(str)}
  call s:echoraw("\x1b[s")
  if g:slide#terminal == 'sixel'
    let y = a:pos[1]
    let x = a:pos[0]
    let width = a:pos[2] != 0 ? a:pos[2]: 0
    let height = a:pos[3] != 0 ? a:pos[3]: 0
    call s:echoraw($"\x1b[{y};{x}H")
    let width_comm = a:pos[2] != 0 ? $" -w {width}%" : ' -w auto'
    let height_comm = a:pos[3] != 0 ? $" -h {height}%" : ' -h auto'
    call s:echoraw(system($"{fname} img2sixel {width_comm}{height_comm}"))
    call s:echoraw("\x1b[u")
  elseif g:slide#terminal == 'wezterm-iterm'
    let width = a:pos[2] != 0 ? a:pos[2]: 0
    let height = a:pos[3] != 0 ? a:pos[3]: 0
    let y = a:pos[1]
    let x = a:pos[0]
    let width = a:pos[2] != 0 ? $" --width {a:pos[2]}" : ''
    let height = a:pos[3] != 0 ? $" --height {a:pos[3]}" : ''
    call system($"{fname} wezterm imgcat {width}{height} --position={x},{y} > {tty}\n")
  elseif g:slide#terminal == 'kitty'
    if a:pos[2] != 0 && a:pos[2] != 0
      let attr = $"--place {a:pos[2]}x{a:pos[3]}@{a:pos[0]}x{a:pos[1]}"
    else
      let attr = ""
    endif
    call system($"{fname} kitten icat {attr} > {tty}\n < {tty}\n")
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
