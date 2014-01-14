" dragonfly.vim
" Last change: Tue 14 Jan 2014 05:27:34 AM CET
" Author: Grimy <Victor.Adam@derpymail.org>
" License: This file is released in the public domain

let s:mincol  = 0
let s:maxcol  = 0
let s:minline = 0
let s:maxline = 0

function! dragonfly#init(v, h)
	" Save registers and options so we can restore them later
	set virtualedit+=block
	let s:save = [ @", &clipboard, &virtualedit, &report ]
	set report=2000000000
	set clipboard=

	" Reselect the visual selection
	normal! gvygv

	" Merge consecutive movements in the undo history
	if [ line("'<"), line("'>") ] == [  s:minline, s:maxline ]
				\ && ([ virtcol("'<"), virtcol("'>") ] == [ s:mincol, s:maxcol ]
				\ || mode() ==# 'V')
		silent! undojoin
	endif

	" Paste the selection on top of itself
	" Quick but perfect trick to deal with selections using $
	normal! pgv

	" Fixes off-by-one errors due to inclusive selections
	if &selection =~ 'exclusive'
		normal! lygv
	endif

	let s:indent = mode() ==# 'V' && a:v
	let s:minline =   line("'<") + a:v
	let s:maxline =   line("'>") + a:v
	let s:mincol = virtcol("'<") + a:h
	let s:maxcol = virtcol("'>") + a:h

	if s:mincol <= 0
		let s:maxcol += 1 - s:mincol
		let s:mincol = 1
	endif
	if s:minline <= 0
		let s:maxline += 1 - s:minline
		let s:minline = 1
	endif
	while s:maxline >= line('$')
		call append('$', '')
	endwhile

endfunction

" Restore registers and options
function! dragonfly#after()
	let reselect =  s:minline . 'G' . s:mincol . '|' . getregtype()[0]
				\ . s:maxline . 'G' . s:maxcol . '|'

	if s:indent
		let reselect .= '=gv'
	endif

	execute 'normal!' reselect
	*call dragonfly#fix_spaces()
	execute 'normal! y' . reselect
	let [ @", &clipboard, &virtualedit, &report ] = s:save
endfunction


function! dragonfly#move(v, h) range
	call dragonfly#init(a:v, mode() ==# 'V' ? 0 : a:h)

	if mode() ==# 'v'
		" Dragging doesn’t make sense in character-wise mode
	elseif mode() ==# 'V' && a:h
		execute 'normal! ' a:h > 0 ? a:h . '>' : -a:h . '<'
	else
		set virtualedit=all

		normal! d
		call setreg('"', substitute(@", "\t", repeat(' ', &tabstop), 'g'),
					\ getregtype())

		*call dragonfly#fix_spaces()
		execute 'normal! ' . s:minline . 'G' . s:mincol . '|P'
	endif

	call dragonfly#after()
endfunction

function! dragonfly#fix_spaces()
	let indent  = repeat("\t", indent('.') / &tabstop)
	let indent .= repeat(' ',  indent('.') % &tabstop)
	let line = getline('.')
	let line = substitute(line, '^\s*', indent, '')
	let line = substitute(line, '\s*$', '', '')
	if (line !=# getline('.'))
		call setline('.', line)
	endif
endfunction

function! dragonfly#copy(times) range
	normal! gvyv
	call dragonfly#init(getregtype() ==# 'V' ? line("'>") - line("'<") + 1 : 0,
				\ str2nr(getregtype()[1:]))
	execute 'normal! y' . s:minline . 'G' . s:mincol . '|' . a:times . 'P'
	call dragonfly#after()
endfunction

