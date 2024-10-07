" Custom Syntax Highlighting Rules "
" Function Braces { }
hi jsFuncBraces   ctermfg=81
" Function Arguments function(arg) {}
hi jsFuncArgs     ctermfg=172
" Function Call func()
hi jsFuncCall     ctermfg=141
" Function Keys  { func : function() {} }
hi jsFunctionKey  ctermfg=141

syntax keyword jsRequire    require
hi link jsRequire           Keyword
hi link jsAsyncKeyword      Noise
