" Adwaita Dark with the desktop's orange accent.
" The palette matches Ghostty, Fuzzel and Waybar.
" Colors: surface #1d1d20 (Adwaita text view), raised #36363a, selected row #4b4b50,
" focus accent #ff7800 (selection/search), standalone orange #ff9c5b (text).

hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'adwaita-orange'
set background=dark

" Without 24-bit color the terminal's own (Adwaita) ANSI palette still applies.
if !has('gui_running') && !has('termguicolors')
  finish
endif

function! s:hi(group, fg, bg, attr) abort
  let l:cmd = 'hi ' . a:group
        \ . ' guifg=' . (a:fg  ==# '' ? 'NONE' : a:fg)
        \ . ' guibg=' . (a:bg  ==# '' ? 'NONE' : a:bg)
        \ . ' gui='   . (a:attr ==# '' ? 'NONE' : a:attr)
        \ . ' cterm=' . (a:attr ==# '' ? 'NONE' : a:attr)
  execute l:cmd
endfunction

" Palette
let s:bg      = '#1d1d20'
let s:window  = '#222226'
let s:header  = '#2e2e32'
let s:raised  = '#36363a'
let s:select  = '#4b4b50'
let s:line    = '#45454a'
let s:fg      = '#ffffff'
let s:text    = '#deddda'
let s:muted   = '#c0bfbc'
let s:dim     = '#9a9996'
let s:faint   = '#77767b'
let s:accent  = '#ff7800'
let s:orange  = '#ff9c5b'
let s:peach   = '#ffbe6f'
let s:yellow  = '#f9f06b'
let s:amber   = '#ffc252'
let s:green   = '#8ff0a4'
let s:cyan    = '#7bdff4'
let s:blue    = '#99c1f1'
let s:purple  = '#dc8add'
let s:red     = '#ff938c'

" Editor chrome
call s:hi('Normal',       s:fg,     s:bg,     '')
call s:hi('NonText',      s:faint,  '',       '')
call s:hi('EndOfBuffer',  s:bg,     s:bg,     '')
call s:hi('SpecialKey',   s:faint,  '',       '')
call s:hi('Whitespace',   s:line,   '',       '')
call s:hi('Cursor',       s:bg,     s:accent, '')
call s:hi('CursorLine',   '',       s:window, '')
call s:hi('CursorColumn', '',       s:window, '')
call s:hi('ColorColumn',  '',       s:window, '')
call s:hi('LineNr',       s:faint,  '',       '')
call s:hi('CursorLineNr', s:orange, s:window, 'bold')
call s:hi('SignColumn',   s:dim,    s:bg,     '')
call s:hi('FoldColumn',   s:faint,  s:bg,     '')
call s:hi('Folded',       s:dim,    s:window, 'italic')
call s:hi('Visual',       s:bg,     s:accent, '')
call s:hi('VisualNOS',    s:bg,     s:orange, '')
call s:hi('Search',       s:bg,     s:amber,  '')
call s:hi('IncSearch',    s:bg,     s:accent, 'bold')
call s:hi('CurSearch',    s:bg,     s:accent, 'bold')
call s:hi('MatchParen',   s:orange, s:line,   'bold')
call s:hi('Directory',    s:blue,   '',       '')
call s:hi('Title',        s:orange, '',       'bold')
call s:hi('Question',     s:green,  '',       'bold')
call s:hi('MoreMsg',      s:green,  '',       '')
call s:hi('ModeMsg',      s:fg,     '',       'bold')
call s:hi('WarningMsg',   s:amber,  '',       '')
call s:hi('ErrorMsg',     s:red,    '',       'bold')
call s:hi('WildMenu',     s:bg,     s:accent, '')
call s:hi('Conceal',      s:faint,  '',       '')

" Splits, bars, tabs and popups
call s:hi('StatusLine',   s:fg,     s:header, '')
call s:hi('StatusLineNC', s:dim,    s:window, '')
call s:hi('StatusLineTerm',   s:fg,  s:header, '')
call s:hi('StatusLineTermNC', s:dim, s:window, '')
call s:hi('VertSplit',    s:line,   s:bg,     '')
call s:hi('WinSeparator', s:line,   s:bg,     '')
call s:hi('TabLine',      s:dim,    s:window, '')
call s:hi('TabLineFill',  s:dim,    s:window, '')
call s:hi('TabLineSel',   s:bg,     s:accent, 'bold')
call s:hi('Pmenu',        s:fg,     s:raised, '')
call s:hi('PmenuSel',     s:fg,     s:select, 'bold')
call s:hi('PmenuSbar',    '',       s:raised, '')
call s:hi('PmenuThumb',   '',       s:faint,  '')
call s:hi('NormalFloat',  s:fg,     s:raised, '')
call s:hi('FloatBorder',  s:line,   s:raised, '')
call s:hi('FloatTitle',   s:orange, s:raised, 'bold')

" Syntax: purple keywords, blue functions, green strings, soft-orange literals, cyan types
call s:hi('Comment',      s:dim,    '',       'italic')
call s:hi('Constant',     s:peach,  '',       '')
call s:hi('String',       s:green,  '',       '')
call s:hi('Character',    s:green,  '',       '')
call s:hi('Number',       s:peach,  '',       '')
call s:hi('Boolean',      s:peach,  '',       '')
call s:hi('Float',        s:peach,  '',       '')
call s:hi('Identifier',   s:text,   '',       '')
call s:hi('Function',     s:blue,   '',       '')
call s:hi('Statement',    s:purple, '',       '')
call s:hi('Conditional',  s:purple, '',       '')
call s:hi('Repeat',       s:purple, '',       '')
call s:hi('Label',        s:purple, '',       '')
call s:hi('Operator',     s:muted,  '',       '')
call s:hi('Keyword',      s:purple, '',       '')
call s:hi('Exception',    s:purple, '',       '')
call s:hi('PreProc',      s:orange, '',       '')
call s:hi('Include',      s:orange, '',       '')
call s:hi('Define',       s:orange, '',       '')
call s:hi('Macro',        s:orange, '',       '')
call s:hi('PreCondit',    s:orange, '',       '')
call s:hi('Type',         s:cyan,   '',       '')
call s:hi('StorageClass', s:purple, '',       '')
call s:hi('Structure',    s:cyan,   '',       '')
call s:hi('Typedef',      s:cyan,   '',       '')
call s:hi('Special',      s:orange, '',       '')
call s:hi('SpecialChar',  s:orange, '',       '')
call s:hi('Tag',          s:blue,   '',       '')
call s:hi('Delimiter',    s:muted,  '',       '')
call s:hi('SpecialComment', s:dim,  '',       'bold,italic')
call s:hi('Debug',        s:red,    '',       '')
call s:hi('Underlined',   s:blue,   '',       'underline')
call s:hi('Ignore',       s:faint,  '',       '')
call s:hi('Error',        s:red,    '',       'bold')
call s:hi('Todo',         s:bg,     s:amber,  'bold')

" Diff and spelling
call s:hi('DiffAdd',      '',       '#1f3a2a', '')
call s:hi('DiffDelete',   s:red,    '#3d2326', '')
call s:hi('DiffChange',   '',       '#2a3040', '')
call s:hi('DiffText',     s:fg,     '#3b4a6b', 'bold')
call s:hi('Added',        s:green,  '',       '')
call s:hi('Removed',      s:red,    '',       '')
call s:hi('Changed',      s:blue,   '',       '')
for s:g in ['SpellBad', 'SpellCap', 'SpellRare', 'SpellLocal']
  let s:c = s:g ==# 'SpellBad' ? s:red : s:g ==# 'SpellCap' ? s:amber : s:blue
  execute 'hi ' . s:g . ' guifg=NONE guibg=NONE guisp=' . s:c . ' gui=undercurl cterm=underline'
endfor

" Terminal buffers use Ghostty's palette.
let g:terminal_ansi_colors = [
      \ '#5e5c64', '#f66151', '#33d17a', '#f6d32d', '#62a0ea', '#c061cb', '#2aa9bd', '#deddda',
      \ '#9a9996', '#ff7b63', '#8ff0a4', '#f9f06b', '#99c1f1', '#dc8add', '#7bdff4', '#ffffff']

unlet s:g s:c
