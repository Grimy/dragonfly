" Vim global plugin for dragging virtual blocks
" Last change: 2014-01-12
" Maintainer: Victor Adam (victor.adam@derpymail.org)
" This software is released in the public domain

vnoremap <silent> <Plug>(dragonfly_left)   :call dragonfly#move( 0, -1)<CR>
vnoremap <silent> <Plug>(dragonfly_right)  :call dragonfly#move( 0, +1)<CR>
vnoremap <silent> <Plug>(dragonfly_up)     :call dragonfly#move(+1,  0)<CR>
vnoremap <silent> <Plug>(dragonfly_down)   :call dragonfly#move(-1,  0)<CR>
vnoremap <silent> <Plug>(dragonfly_copy)   :call dragonfly#move(0, 0, 1)<CR>

command! -range=% DragonflyInsert call dragonfly#insert(0)
command! -range=% DragonflyAppend call dragonfly#insert(1)

