
let s:last_moved_text = ''
function! dragonfly#move(v, h, ...) range
	" Reselect the visual selection
	normal! gv

	" We can’t move before the start of the buffer
	" Dragging doesn’t make sense in character-wise mode
	if line("'<") + a:v == 0 || mode() ==# 'v'
		return
	endif

	" Save registers and options so we can restore them later
	set virtualedit+=block
	let save = [ @", &virtualedit ]

	" Merge consecutive movements
	normal ygv
	if s:last_moved_text == @" && !a:0
		silent! undojoin
	endif

	" All actual work is done here

	if mode() ==# 'V' " linewise
		let height = line("'>") - line("'<") + 1
		if a:0
			execute "normal! y'>p"
		else
			let eof = line("'>") == line('$')
			execute 'normal!' a:v == +1 ? eof ? 'yOgvdp' : 'dp'
						\     a:v == -1 : eof ? 'dP'       : 'dkP'
		endif
		execute 'normal! V'. height . '_=gv'

	else              " blockwise
		let [ mincol, maxcol ] = dragonfly#get_selection_corners()
		set virtualedit=all
		if a:0
			execute 'normal! y' . line("'<") . 'G' . (maxcol - 1) . '|pgv'
		elseif mincol + a:h > 0
			execute 'normal! ' . mincol . '|O' . maxcol . '|d'

			let start = (line("'<") + a:v) . 'G' . (mincol + a:h) . '|'
			let end   = (line("'>") + a:v) . 'G' . (maxcol + a:h) . '|'

			" Strip trailing whitespace
			*s/\s*$//
			*normal! ==

			execute 'normal! ' . start . 'P' . start . "\<C-V>" . end
		endif
	endif

	" Restore registers and options
	let s:last_moved_text = @"
	let [ @", &virtualedit ] = save
endfunction


function! dragonfly#get_selection_corners()
	let mincol = min([virtcol("'<"), virtcol("'>")])
	let maxcol = max([virtcol("'<"), virtcol("'>")])
	let line   = line('.')

	" Handle the special case of a blockwise selection with $
	set virtualedit=
	for i in range(line("'<"), line("'>"))
		execute 'normal! ' . i . 'G'
		if virtcol('.') > maxcol
			let maxcol = virtcol('.') - (&selection =~ 'inclusive')
		endif
	endfor
	execute 'normal! ' . line . 'G'

	" Fix the off-by-one error due to exclusive selections
	if &selection =~ 'exclusive' && line("'>") != line("'<")
		let maxcol += xor(virtcol('.') <= mincol, line == line("'<"))
	endif

	return [ mincol, maxcol ]
endfunction


" Optional parameter : append
function! dragonfly#insert(append) range

	" In character-wise mode, fallback to the normal behaviour
	if visualmode() ==# 'v'
		call setpos('.', getpos(a:append ? "'>" : "'<"))
		startinsert
		return
	endif

	" Save options so we can restore them later
	let save = [ &eventignore, &virtualedit, &cursorline, &cursorcolumn ]
	set eventignore=all virtualedit=all nocursorline nocursorcolumn
	match Cursor /┃/

	let chars = sort([virtcol("'>"), virtcol("'<")])[a:append] . '|i'
	let tick = b:changedtick

	while chars !~ "\<Esc>$"
		execute '*normal ' . chars . '┃l'
		redraw
		let char = getchar()
		let chars .= char > 0 ? nr2char(char) : char
		if b:changedtick > tick
			let tick = b:changedtick
			undo
		endif
	endwhile

	execute '*normal ' . chars

	match
	let [ &eventignore, &virtualedit, &cursorline, &cursorcolumn ] = save
	call repeat#set(chars, 1)
endfunction

