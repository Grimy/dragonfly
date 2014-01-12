
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
						\   : a:v == -1 ? eof ? 'dP'       : 'dkP'
						\   : ''
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

	let chars = sort([virtcol("'>"), virtcol("'<")])[a:append] . '|'
	execute '*normal ' . chars . "\<C-N>"
	call g:dragonfly_sublime()
endfunction


let g:nbcursors = 0

function! NormalPos(pos)
	return line(a:pos) . 'G' . virtcol(a:pos) . '|'
endfunction

nnoremap <C-N> :let g:nbcursors += 1<CR>i<Char-0x2503><Esc>l
nnoremap <C-Z> :call g:dragonfly_sublime()<CR>
vnoremap <Space> :s/\s*$//<CR>gv

function! g:dragonfly_sublime()
	if g:nbcursors == 0
		return
	endif

	" Save options so we can restore them later
	let save = [ &eventignore, &cursorline, &cursorcolumn ]
	set eventignore=all nocursorline nocursorcolumn
	match cursor /\%u2503/

	let char = ''
	while char != "\<Esc>"
		redraw
		let charcode = getchar()
		let char = charcode > 0 ? nr2char(charcode) : charcode
		for i in range(g:nbcursors)
			silent! undojoin
			execute "normal! l/\\%u2503\<CR>x"
			execute 'normal i' . char
			execute "normal! a\<Char-0x2503>"
		endfor
	endwhile

	%s/\%u2503//g
	match
	let g:nbcursors = 0
	let [ &eventignore, &cursorline, &cursorcolumn ] = save
	"call repeat#set(chars, 1)
endfunction



