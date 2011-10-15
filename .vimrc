cd ~/workspace
syntax on
" set expandtab smarttab shiftwidth=4 softtabstop=4 tabstop=8 ts=4 
" set hlsearch
"set autoindent
:map <C-v> "+gP
:map <C-c> "+y
:map <C-x> "+x
set backspace=2
set tabpagemax=20
set number
:map <C-n> <Esc>:tabn<Enter>
:map <C-p> <Esc>:tabp<Enter>
:map! <C-s> <Esc>:w<Enter>

:syntax on
:set tabstop=4
":set cindent
":set smartindent
":set bs=2
:set shiftwidth=4
:set expandtab
colorscheme desert

" ctags
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>

:set ruler

filetype on
filetype plugin on 
filetype indent on

:let mapleader = ','
map <Leader>n :NERDTreeToggle<CR>
let g:CommandTCancelMap='<Esc>'
let g:CommandTSelectNextMap=['<Tab>', '<Down>']
let g:CommandTSelectPrevMap=['<S-x>', '<Up>']
" to fix issues with command-t <Up> and <Down> terminal keys (see :h vt100-cursor-keys)
"set notimeout		" don't timeout on mappings
"set ttimeout		" do timeout on terminal key codes
"set timeoutlen=100	" timeout after 100 msec

let perl_fold = 1
let sh_fold_enabled = 1
let ruby_fold = 1
let php_folding = 1
" open all folds by default
:set nofoldenable
:set foldmethod=syntax

set textwidth=90
" automatically re-adjust paragraphs on edits (a), but dont mess up pasted comments (w)
set formatoptions+=w 

set noincsearch

cmap <C-v> <C-r>"

function! GetBufferList()
  redir =>buflist
  silent! ls
  redir END
  return buflist
endfunction

function! ToggleList(bufname, pfx)
  let buflist = GetBufferList()
  for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    if bufwinnr(bufnum) != -1
      exec(a:pfx.'close')
      return
    endif
  endfor
  if a:pfx == 'l' && len(getloclist(0)) == 0
      echohl ErrorMsg
      echo "Location List is Empty."
      return
  endif
  let winnr = winnr()
  exec(a:pfx.'open')
  if winnr() != winnr
    wincmd p
  endif
endfunction

nmap <silent> <leader>l :call ToggleList("Location List", 'l')<CR>
nmap <silent> <leader>e :call ToggleList("Quickfix List", 'c')<CR>

set ofu=syntaxcomplete#Complete

autocmd! bufwritepost .vimrc source ~/.vimrc

" Use CTRL-S for saving, also in Insert mode
noremap <C-S>		:update<CR>
vnoremap <C-S>		<C-C>:update<CR>
inoremap <C-S>		<C-O>:update<CR>

" CTRL-X and SHIFT-Del are Cut
vnoremap <C-X> "+x
inoremap <C-X> <Esc>"+x<Return>i

" CTRL-C and CTRL-Insert are Copy
vnoremap <C-C> "+y

" CTRL-V and SHIFT-Insert are Paste
vnoremap <C-V>		"+gP
inoremap <C-V> <Esc>"+gP<Return>i

set t_Co=256
