" :map <C-v> "+gP
" :map <C-c> "+y
" :map <C-x> "+x
set backspace=2
set tabpagemax=20
set number
set colorcolumn=100
:map <C-n> <Esc>:tabn<Enter>
:noremap <C-p> <Esc>:tabp<Enter>
:map! <C-s> <Esc><Esc>:w<Enter>

set hlsearch
:syntax on
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set backspace=indent,eol,start
":set cindent
":set smartindent
:set shiftwidth=4
:set expandtab
colorscheme jellybeans

" ctags
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>

" if we visually select text, search for that text from our current cursor
vmap <C-f> y/<C-r>"<CR>

:set ruler

filetype on
filetype plugin on 
filetype indent on

" map keys for window resizing
if bufwinnr(1)
    " map <C--> <C-W>+ " inc height
    " map <C-=> <C-W>- " dec height
    map _ <C-W>< " inc height
    map + <C-W>> " dec height
endif

let g:mapleader = ','
let g:maplocalleader = ','
map <Leader>n :NERDTreeToggle<CR>
map <Leader>N :NERDTreeFind<CR>
" let g:CommandTCancelMap='<Esc>'
" let g:CommandTSelectNextMap=['<Tab>', '<Down>']
" let g:CommandTSelectPrevMap=['<S-x>', '<Up>']

nnoremap <silent> <Leader>p :CtrlP<CR>
nnoremap <silent> <Leader>P :CtrlPMRUFiles<CR>
let g:ctrlp_map = '<Leader>p'
" nnoremap <silent> <Leader>b :CommandTBuffer<CR>
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn)$',
    \ 'file': '\v\.(exe|so|dll|class)$',
    \ }

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

" http://vim.runpaint.org/display/working-with-long-lines/
" 'when a line is more than four characters away from the right-hand margin, it is broken'
set wrapmargin=4
" hardline wrap text past 90 characters
" set textwidth=90
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

command -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
  if exists("g:qfix_win") && a:forced == 0
    cclose
    unlet g:qfix_win
  else
    copen 10
    let g:qfix_win = bufnr("$")
  endif
endfunction

nmap <silent> <leader>d :call ToggleList("Location List", 'l')<CR>:syntax on<CR>
nmap <silent> <leader>c :call ToggleList("Quickfix List", 'c')<CR>:syntax on<CR>

" set ofu=syntaxcomplete#Complete
" let g:SuperTabDefaultCompletionType = "<c-p>"
" "<C-X><C-O>"
" let g:SuperTabDefaultCompletionType = "context"
" let g:SuperTabDefaultCompletionType = "<C-X><C-O>"

" Completion using a syntax file: http://vim.wikia.com/wiki/VimTip498
set complete+=k
au FileType * exe('setl dict+='.$VIMRUNTIME.'/syntax/'.&filetype.'.vim')

let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']

let g:ftplugin_sql_omni_key_right = '<Right>'
let g:ftplugin_sql_omni_key_left  = '<Left>'

" inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
" inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"
" inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
" inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
" inoremap <expr> <PageDown> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<PageDown>"
" inoremap <expr> <PageUp>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<PageUp>"
" inoremap <silent> <Esc> <C-r>=pumvisible() ? "\<C-y>" : "\<Esc>"<CR>
" inoremap <expr> <C-d> pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
" inoremap <expr> <C-u> pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"
set completeopt+=longest

" auto reload of vimrc on change
autocmd! bufwritepost .vimrc source ~/.vimrc

" Use CTRL-S for saving, also in Insert mode
noremap <C-S>		:update<CR><Esc>
vnoremap <C-S>		<C-C>:update<CR><Esc>
inoremap <C-S>		<C-O>:update<CR><Esc>

" CTRL-X and SHIFT-Del are Cut
" vnoremap <C-X> "+x
" inoremap <C-X> <Esc>"+x<Return>i

" CTRL-C and CTRL-Insert are Copy
" vnoremap <C-C> "+y

" CTRL-V and SHIFT-Insert are Paste
" vnoremap <C-V>		"+gP
" inoremap <C-V> <Esc>"+gP<Return>i

" set t_Co=256
"
noremap <C-Q> :q<CR>
vnoremap <C-Q> :q<CR>
inoremap <C-Q> <Esc>:q<CR>

map <Leader>m <Esc>:make<Up><CR>

set wildmode=longest,list,full
set wildmenu

" replace visually selected text in the whole buffer
vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>
vnoremap <C-t> "hy:%s/\c<C-r>h/\=SmartCase('')/gc<left><left><left><left><left>

nmap <LocalLeader>sv <Plug>RSendSelection
imap <LocalLeader>sv <Plug>RSendSelection
vmap <LocalLeader>sv <Plug>RSendSelection

nmap <LocalLeader>sl <Plug>RSendLine
imap <LocalLeader>sl <Plug>RSendLine
vmap <LocalLeader>sl <Plug>RSendLine

nmap <LocalLeader>sf <Plug>RSendFile
imap <LocalLeader>sf <Plug>RSendFile
vmap <LocalLeader>sf <Plug>RSendFile
let vimrplugin_underscore = 0

set diffopt=filler,iwhite
au BufEnter *.hs compiler ghc
let g:ghc="/usr/bin/ghc"
let g:haddock_browser="/usr/bin/firefox"

" set verbose=9
" let loaded_matchparen = 0
" DoMatchParen

let g:ctrlp_working_path_mode = ''

"
" Tagbar
" 

nmap <Leader>l :TagbarToggle<CR>

" let g:tagbar_type_javascript = {
"     \ 'ctagsbin' : '~/bin/jsctags'
" \ }

"
" Vim Addon Manager
"

set runtimepath+=~/.vim/vim-addon-manager
" "vim-scala@behaghel"

" call vam#ActivateAddons(["ack", "Align%294", "IndentAnything", "matchit.zip", "The_NERD_tree", "Rename%1928", "vim-addon-sbt", "screen", "snipmate", "SuperTab_continued.", "surround", "tComment", "ctrlp"])

" setting up EnVim
fun SetupVAM()
  let g:vim_addon_manager = {}
  let g:vim_addon_manager.plugin_sources = {}
  " let g:vim_addon_manager.plugin_sources['ensime'] = {"type": "git", "url": "git://github.com/aemoncannon/ensime.git", "branch" : "scala-2.9"}
  " let g:vim_addon_manager.plugin_sources['envim'] = {"type": "git", "url": "git://github.com/jlc/envim.git", "branch" : "master"}
  " let g:vim_addon_manager.plugin_sources['ensime-common'] = {"type": "git", "url": "git://github.com/jlc/ensime-common.git", "branch" : "master"}
  " let g:vim_addon_manager.plugin_sources['vim-async-beans'] = {"type": "git", "url": "git://github.com/jlc/vim-async-beans.git", "branch" : "master"}
  " let g:vim_addon_manager.plugin_sources['vim-addon-async'] = {"type": "git", "url": "git://github.com/jlc/vim-addon-async.git", "branch" : "master"}
  " let g:vim_addon_manager.plugin_sources['vim-scala-behaghel'] = {'type': 'git', 'url': 'git://github.com/behaghel/vim-scala.git'}
"    \ 'ensime',
"    \ 'vim-addon-async',
"    \ 'vim-async-beans',
"    \ 'ensime-common',
"    \ 'envim',
"    \ 'vim-scala-behaghel',
"    \ 'Rename%1928',
"    \ 'screen',
"    \ 'vim-addon-sbt',

    " some kind of bug with setting up python path by jedi plugin when 
    " installed use vim_addon_manager

    " let g:vim_addon_manager.plugin_sources['jedi'] = {"type": "git", "url": "git://github.com/davidhalter/jedi-vim", "branch" : "master"}

    " \ 'jedi',
  let g:vim_addon_manager.plugin_sources['togglelist'] = {"type": "git", "url": "git://github.com/milkypostman/vim-togglelist", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['puppet-syntax'] = {"type": "git", "url": "git://github.com/puppetlabs/puppet-syntax-vim", "branch" : "master"}

  let plugins = [
    \ 'ack',
    \ 'Align%294',
    \ 'IndentAnything',
    \ 'matchit.zip',
    \ 'The_NERD_tree',
    \ 'snipmate-snippets',
    \ 'snipmate',
    \ 'SuperTab%1643',
    \ 'surround',
    \ 'tComment',
    \ 'xml',
    \ 'indenthtml',
    \ 'Tagbar',
    \ 'groovyindent',
    \ 'Simple_Javascript_Indenter',
    \ 'fugitive',
    \ 'dbext',
    \ 'SmartCase',
    \ 'easytags',
    \ 'marvim',
    \ 'fugitive',
    \ 'togglelist',
    \ 'perlomni',
    \ 'Super_Shell_Indent',
    \ 'Jinja',
    \ 'puppet-syntax',
    \ 'vimpager',
    \ 'ctrlp'
    \ ]

    " \ 'SearchComplete',

  call vam#ActivateAddons(plugins,{'auto_install' : 0})
endf
call SetupVAM()

" vim-addon-sbt
fun SBT_JAR()
    return "/usr/share/sbt/0.11.3/sbt-launch.jar"
endfun

let g:SimpleJsIndenter_BriefMode = 1

" let g:dbext_default_profile_DBNAME = 'type=MYSQL:user=root:dbname=DBNAME'
" let g:dbext_default_profile = 'DBNAME'
" let g:omni_sql_include_owner = 0

" clipboard integration
" http://vim.wikia.com/wiki/Mac_OS_X_clipboard_sharing#Comments
if has('win64')|| has('win32') || has('mac')
    " mac/windows
    set clipboard=unnamed
else
    " linux
    set clipboard=unnamedplus
endif

" make ctrl+arrow work in vim when we're attached to tmux
if &term =~ '^screen'
    " tmux will send xterm-style keys when its xterm-keys option is on
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
endif

call tcomment#DefineType("gsp_block", "<%%--%s--%%>\n     ")
call tcomment#DefineType("gsp", "<%%-- %s --%%>")

call tcomment#DefineType('cmake',               '# %s'             )
"
" to change the macro storage location use the following 
" let marvim_store = '/usr/local/share/projectX/marvim' 
let marvim_find_key = '<Leader>r' " change find key from <F2> to 'space'
let marvim_store_key = '<Leader>d'     " change store key from <F3> to 'ms'
" let marvim_register = 'c'       " change used register from 'q' to 'c'
" let marvim_prefix = 0           " disable default syntax based prefix

set t_te= t_ti=
let g:easytags_auto_update = 0
set history=200

set keywordprg=~/.vim/bin/imfeelinglucky.py

map + <C-A>
map _ <C-X>
