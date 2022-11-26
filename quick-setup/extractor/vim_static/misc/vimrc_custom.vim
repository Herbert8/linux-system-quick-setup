" 参考配置 http://www.ruanyifeng.com/blog/2018/09/vimrc.html


" 设置字体
" set guifont=Source\ Code\ Pro:h14


" 打开行号
set number

" 关闭行号
" set nonumber

" 不与 Vi 兼容（采用 Vim 自己的操作命令）。
set nocompatible

" 打开语法高亮。自动识别代码，使用多种颜色显示。
syntax on

" 在底部显示，当前处于命令模式还是插入模式。
set showmode

" 命令模式下，在底部显示，当前键入的指令。
set showcmd

" 支持使用鼠标。
" set mouse=a

" 使用 utf-8 编码。
set encoding=utf-8

" 启用256色。
set t_Co=256

" 指定 背景色风格
set background=dark

" 指定 colorscheme
colorscheme murphy

" 开启文件类型检查，并且载入与该类型对应的缩进规则。
filetype indent on

" 显示光标所在的当前行的行号，其他行都为相对于该行的相对行号。
" set relativenumber

" 光标所在的当前行高亮。
set cursorline

" set textwidth=80

" 关闭自动折行
set nowrap

" 在状态栏显示光标的当前位置（位于哪一行哪一列）。
set  ruler

" 光标遇到圆括号、方括号、大括号时，自动高亮对应的另一个圆括号、方括号和大括号。
set showmatch

" 搜索时，高亮显示匹配结果。
set hlsearch

" 输入搜索模式时，每输入一个字符，就自动跳到第一个匹配的结果。
set incsearch

" 出错时，发出视觉提示，通常是屏幕闪烁。
set visualbell

" 打开文件监视。如果在编辑过程中文件发生外部改变（比如被别的编辑器编辑了），就会发出提示。
set autoread

" 命令模式下，底部操作指令按下 Tab 键自动补全。第一次按下 Tab，会显示所有匹配的操作指令的清单；第二次按下 Tab，会依次选择各个指令。
set wildmenu



" 缩进相关配置，具体参考 https://segmentfault.com/a/1190000021133524

" ts是 tabstop 的缩写，设 TAB 宽 4 个空格（默认 8 个空格）
" tabstop 选项可以简写为 ts，:set tabstop=4 命令和 :set ts=4 命令是等效的。
set ts=4

" 智能缩进
" set smartindent

set shiftwidth=4

" 设置 expandtab 选项后，在插入模式下，会把按 Tab 键所插入的 tab 字符替换为合适数目的空格。
" 如果确实要插入 tab 字符，需要按 CTRL-V 键，再按 Tab 键。
set expandtab

set softtabstop=4

" 显示不可见字符
"set listchars=eol:↩︎,tab:->,trail:␣
set listchars=tab:->,trail:␣
set list


