" Set the shell to ensure the terminal launches a login shell to read
" bash_profile
set shell=bash\ -l
nnoremap <Space> <Nop>
let mapleader = " "

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

" Find files using Telescope command-line sugar.
" https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#usage
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Enable distraction free editing
" Color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

" Delete trailing whitespace on save...
" https://vim.fandom.com/wiki/Remove_unwanted_spaces#Automatically_removing_all_trailing_whitespace
autocmd BufWritePre * :%s/\s\+$//e

" Markdown mappings
autocmd Syntax markdown :iabbrev <buffer> -[ -<Space>[<Space>]
call plug#begin()
Plug 'mattn/emmet-vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.6' }
Plug 'smithbm2316/centerpad.nvim'
call plug#end()

