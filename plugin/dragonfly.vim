" Copyright © 2014 Grimy <Victor.Adam@derpymail.org>
" This work is free software. You can redistribute it and/or modify it under
" the terms of the Do What The Fuck You Want To Public License, Version 2, as
" published by Sam Hocevar. See the LICENCE file for more details.

vnoremap <silent> <Plug>(dragonfly_left)  :call dragonfly#move(0, -v:count1)<CR>
vnoremap <silent> <Plug>(dragonfly_right) :call dragonfly#move(0, +v:count1)<CR>
vnoremap <silent> <Plug>(dragonfly_up)    :call dragonfly#move(-v:count1, 0)<CR>
vnoremap <silent> <Plug>(dragonfly_down)  :call dragonfly#move(+v:count1, 0)<CR>
vnoremap <silent> <Plug>(dragonfly_copy)  :call dragonfly#copy(v:count1)<CR>

