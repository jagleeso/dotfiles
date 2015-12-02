" put this line first in ~/.vimrc
set nocompatible | filetype indent plugin on | syn on
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
colorscheme kolor
" colorscheme jellybeans

" ctags
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
noremap <Leader>g :tselect<CR>

" if we visually select text, search for that text from our current cursor
vmap <C-f> y/<C-r>"<CR>

:set ruler

nnoremap <silent> <c-w>t :tabnew<CR>

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
map <Leader>y :TagbarToggle<CR>
let NERDTreeIgnore=['\~$', '\.class$']
" let g:CommandTCancelMap='<Esc>'
" let g:CommandTSelectNextMap=['<Tab>', '<Down>']
" let g:CommandTSelectPrevMap=['<S-x>', '<Up>']

nnoremap <silent> <Leader>p :CtrlP<CR>
nnoremap <silent> <Leader>P :CtrlPMRUFiles<CR>
let g:ctrlp_map = '<Leader>p'
" nnoremap <silent> <Leader>b :CommandTBuffer<CR>
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/](target|\.(git|hg|svn))$',
    \ 'file': '\v\.(exe|so|dll|class|o)$',
    \ }
let g:ctrlp_extensions = ['funky']
let g:ctrlp_max_files=0
let g:ctrlp_working_path_mode = ''
nnoremap <Leader>f :CtrlPFunky<Cr>
let g:ctrlp_follow_symlinks = 1
let g:ctrlp_clear_cache_on_exit = 0

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

" set noincsearch
set incsearch

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

command! -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
  if exists("g:qfix_win") && a:forced == 0
    cclose
    unlet g:qfix_win
  else
    copen 10
    let g:qfix_win = bufnr("$")
  endif
endfunction

nmap <silent> <leader>l :call ToggleList("Location List", 'l')<CR>
" nmap <silent> <leader>d :call ToggleList("Quickfix List", 'c')<CR>

" nmap <script> <silent> <leader>d :call ToggleLocationList()<CR>
nmap <script> <silent> <leader>q :copen<CR>
" aug QFClose
"   au!
"   au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
" aug END

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
noremap <C-q> :q<CR>
vnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>

" map <Leader>m <Esc>:make<Up><CR>
map <Leader>m <Esc>:Make<CR>
map <Leader>h :lcd %:h<CR>:e<CR>

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

" set verbose=9
" let loaded_matchparen = 0
" DoMatchParen

let g:ctrlp_working_path_mode = ''

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
fun! SetupVAM()
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


  let g:vim_addon_manager.plugin_sources['togglelist'] = {"type": "git", "url": "git://github.com/milkypostman/vim-togglelist", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['puppet-syntax'] = {"type": "git", "url": "git://github.com/puppetlabs/puppet-syntax-vim", "branch" : "master"}
  " let g:vim_addon_manager.plugin_sources['vim-css-color'] = {"type": "git", "url": "git://github.com/skammer/vim-css-color", "branch" : "master"}
  " faster startup: https://github.com/skammer/vim-css-color/issues/3
  let g:vim_addon_manager.plugin_sources['vim-css-color'] = {"type": "git", "url": "git://github.com/ap/vim-css-color", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-backbone'] = {"type": "git", "url": "git://github.com/mklabs/vim-backbone", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-dustjs'] = {"type": "git", "url": "git://github.com/jimmyhchan/dustjs.vim", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-clojure-static'] = {"type": "git", "url": "git://github.com/guns/vim-clojure-static", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-fireplace'] = {"type": "git", "url": "git://github.com/tpope/vim-fireplace", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-classpath'] = {"type": "git", "url": "git://github.com/tpope/vim-classpath", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-redl'] = {"type": "git", "url": "git://github.com/dgrnbrg/vim-redl", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['ag'] = {"type": "git", "url": "git://github.com/rking/ag.vim", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-move'] = {"type": "git", "url": "git://github.com/matze/vim-move", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['ghcmod-vim'] = {"type": "git", "url": "git://github.com/eagletmt/ghcmod-vim", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['neocomplete'] = {"type": "git", "url": "git://github.com/Shougo/neocomplete.vim", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-scala-derekwyatt'] = {"type": "git", "url": "git://github.com/derekwyatt/vim-scala", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['snippets-good'] = {"type": "git", "url": "git://github.com/garbas/vim-snipmate", "branch" : "master"}
  " get foldmethod=syntax fix
  let g:vim_addon_manager.plugin_sources['Rainbow_Parentheses_Improved_Master'] = {"type": "git", "url": "git://github.com/oblitum/rainbow", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-nerd-tree'] = {"type": "git", "url": "https://github.com/scrooloose/nerdtree.git", "branch" : "master"}
  let g:vim_addon_manager.plugin_sources['vim-kolor'] = {"type": "git", "url": "https://github.com/jagleeso/vim-kolor.git", "branch" : "master"}

  let plugins = [
    \ 'ack',
    \ 'Align%294',
    \ 'IndentAnything',
    \ 'matchit.zip',
    \ 'The_NERD_tree',
    \ 'Supertab',
    \ 'surround',
    \ 'tComment',
    \ 'xml',
    \ 'indenthtml',
    \ 'Tagbar',
    \ 'groovyindent',
    \ 'Simple_Javascript_Indenter',
    \ 'fugitive',
    \ 'SmartCase',
    \ 'marvim',
    \ 'fugitive',
    \ 'togglelist',
    \ 'Super_Shell_Indent',
    \ 'Jinja',
    \ 'puppet-syntax',
    \ 'github_theme',
    \ 'vim-dustjs',
    \ 'vim-css-color',
    \ 'vim-clojure-static',
    \ 'vim-fireplace',
    \ 'vim-classpath',
    \ 'vim-redl',
    \ 'vimpager',
    \ 'ag',
    \ 'gitignore%2557',
    \ 'vim-move',
    \ 'ghcmod-vim',
    \ 'vim-scala-derekwyatt',
    \ 'snippets-good',
    \ 'vim-snippets',
    \ 'Tail_Bundle',
    \ 'jellybeans',
    \ 'vim-nerd-tree',
    \ 'dispatch',
    \ 'vim-kolor',
    \ 'goyo',
    \ 'ctrlp'
    \ ]

    " \ 'LargeFile',
    " \ 'clang_complete',
    " \ 'NERD_tree_Project',
    " \ 'The_NERD_tree',
    " \ 'Rainbow_Parentheses_Improved_Master',
    " \ 'rainbow_parentheses',
    " \ 'paredit',

    " \ 'better-snipmate-snippet',
    " tired of the snipmate related errors when used tab to autocomplete; not worth it
    " \ 'snipmate-snippets',
    " \ 'snipmate',

    " useful haskell plugins that take a little more effort to setup
    " \ 'neco-ghc',
    " \ 'neocomplete',
    " \ 'vimproc',
    
  call vam#ActivateAddons(plugins,{'auto_install' : 0})
endf
call SetupVAM()

" vim-addon-sbt
fun! SBT_JAR()
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

" Use ctrl-[hjkl] to select the active split!
map <silent> <c-k> :wincmd k<CR>
map <silent> <c-j> :wincmd j<CR>
map <silent> <c-h> :wincmd h<CR>
map <silent> <c-l> :wincmd l<CR>

map <silent> <c-w>t :tabnew<CR>

vmap <C-j> <Plug>MoveBlockDown
vmap <C-k> <Plug>MoveBlockUp

" stolen from vim-clojure
" let g:rbpt_colorpairs = [
" \ ['darkyellow', 'orangered3'],
" \ ['darkgreen', 'orange2'],
" \ ['blue', 'yellow3'],
" \ ['darkmagenta', 'olivedrab4'],
" \ ['red', 'green4'],
" \ ['darkyellow', 'paleturquoise3'],
" \ ['darkgreen', 'deepskyblue4'],
" \ ['blue', 'darkslateblue'],
" \ ['darkmagenta', 'darkviolet'],
" \ ]

" au VimEnter * RainbowParenthesesToggle
" au Syntax * RainbowParenthesesLoadRound
" au Syntax * RainbowParenthesesLoadSquare
" au Syntax * RainbowParenthesesLoadBraces

" let g:rainbow_active = 1

" http://vim.wikia.com/wiki/Copy_search_matches
function! CopyMatches(reg)
    let hits = []
    %s//\=len(add(hits, submatch(0))) ? submatch(0) : ''/ge
    let reg = empty(a:reg) ? '+' : a:reg
    execute 'let @'.reg.' = join(hits, "\n") . "\n"'
endfunction
command! -register CopyMatches call CopyMatches(<q-args>)

let g:paredit_mode = 1
let g:paredit_smartjump = 1

let vimpager_disable_x11 = 1

" http://dysfunctionalprogramming.co.uk/blog/2013/08/15/fight-with-tools/

" Keep cursor away from edges of screen.
set so=14

" Highlight cursor line.
augroup CursorLine
  au!
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  au VimEnter,WinEnter,BufWinEnter * setlocal cursorcolumn
  au WinLeave * setlocal nocursorline
  au WinLeave * setlocal nocursorcolumn
augroup END

au VimEnter,WinEnter,BufWinEnter * :call CheckVimrc()
if !exists("*CheckVimrc")
func CheckVimrc()
    " let filedir = expand('%:p:h')
    " let vimfile = filedir . '/.vimrc'
    let vimfile = getcwd() . '/.vimrc'
    if filereadable(l:vimfile) && expand('~/.vimrc') != l:vimfile
        execute 'source ' . l:vimfile
    endif
endfunction
endif

func! CdFileDir()
    let dir = expand('%:p:h')
    execute 'lcd ' . l:dir
endfunction
map <leader>h <esc>:call CdFileDir()<cr>

" Mouse usage enabled in normal mode.
set mouse=a
" Set xterm2 mouse mode to allow resizing of splits with mouse inside Tmux.
set ttymouse=xterm2

" have spellcheck on by default (just don't hightlight it)
set spell
hi clear SpellBad

set tabpagemax=50

autocmd BufNewFile,BufRead *.cl set ft=c

" Trigger prompt to reload changed files on buffer enter.
au FocusGained,BufEnter * checktime

if !exists("*CheckForCustomConfiguration")
    " can't redefine functions in use (which it will be on reloading ~/.vimrc
    if !&diff
        " if we're vimdiff-ing across machines, don't source remote's vimrc
        au BufNewFile,BufRead * call CheckForCustomConfiguration(expand('%:p:h'))
        au BufEnter * call CheckForCustomConfiguration(getcwd())
    endif

    function CheckForCustomConfiguration(dir)
        " Check for .vim.custom in the directory containing the newly opened file
        let g:pwd = a:dir
        let custom_config_file = a:dir . '/.vimrc'
        if filereadable(custom_config_file)
            exe 'source' custom_config_file
        endif
    endfunction
endif

let g:goyo_width = 120
au BufNewFile,BufRead *_defconfig setl keywordprg=kconf
au BufNewFile,BufRead Kconfig setl keywordprg=kconf
map <Leader>f <Esc>:!realpath % \| tr -d '\n' \| cboard<CR>
map <Leader>F <Esc>:call system("echo " . shellescape(expand("%") . ":" . line(".")) . "\| tr -d '\n' \| cboard")<CR>

nmap <C-f> :tnext<CR>

" uoftpc
source ~/.vimrc.uoftpc

source ~/.vimrc.samsung.private
