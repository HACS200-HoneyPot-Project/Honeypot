colorscheme molokai
filetype plugin indent on
set background=dark

set nocompatible
set softtabstop=2
set tabstop=2
set backspace=indent,eol,start
set expandtab
set shiftwidth=2
set showmatch
set mouse=a
if has("mouse_sgr")
  set ttymouse=sgr
else
  set ttymouse=xterm2
end
syntax enable

set ruler
set showcmd

set smartcase

set statusline+=%f
set ls=2
set number

set linebreak

set formatoptions+=r

" Setup the vundle runtime "
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-fugitive'
Plugin 'pangloss/vim-javascript'
Plugin 'maxmellon/vim-jsx-pretty'
Plugin 'ntpeters/vim-better-whitespace'
Plugin 'ervandew/supertab'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'wsdjeg/vim-fetch'

" All Vundle plugins must be declared before this line "
call vundle#end()
filetype plugin indent on

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exec = 'eslint_d'

let g:syntastic_filetype_map = { "javascriptreact": "javascript" }

let g:vim_jsx_pretty_highlight_close_tag = 1

" Autofix entire buffer with eslint_d:
nnoremap <leader>f mF:%!eslint_d --stdin --fix-to-stdout<CR>`F

" tmux setting
if !empty($TMUX)
  set t_Co=256
  set term=screen-256color
endif

let g:airline_powerline_fonts = 1
let g:airline_theme = 'hybridline'

set cursorline
highlight CursorLineNr cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE

highlight link jsGlobalObjects Special
highlight link jsTemplateBraces Special
highlight link jsGlobalNodeObjects Keyword

set wildmenu
set wildmode=list:longest
set wildignorecase
