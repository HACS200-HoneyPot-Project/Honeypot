if exists("b:did_ftplugin")
	finish
endif
let b:did_ftplugin = 1

inoremap {<CR> {<CR>}<Esc>ko
inoremap [<CR> [<CR>]<Esc>ko
inoremap ({<CR> ({<CR>});<Esc>ko
inoremap ([<CR> ([<CR>]);<Esc>ko
inoremap (<CR> (<CR>);<Esc>ko

set tabstop=2
set softtabstop=2
set shiftwidth=2
