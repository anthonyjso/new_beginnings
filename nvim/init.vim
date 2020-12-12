" Set the shell to ensure the terminal launches a login shell to read
" bash_profile
set shell=bash\ -l

" Expand tab
set expandtab
set tabstop=4
set shiftwidth=4

" add yaml stuffs
au! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Disable Conquer of Completion at startup
let g:coc_start_at_startup = v:false

" Enable syntax
syntax on

" Enable use of FZF
set rtp+=/usr/local/opt/fzf
" https://github.com/junegunn/fzf/blob/master/README-VIM.md#starting-fzf-in-a-popup-window
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

" Enable distraction free editing
" Color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

" Configure vim-slime to allow for sending text in a buffer to a live REPL
let g:slime_target = "tmux"
let g:slime_paste_file = "$HOME/.slime_paste"

