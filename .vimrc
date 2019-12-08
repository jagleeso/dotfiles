" put this line first in ~/.vimrc

set nocompatible              " be iMproved, required
" YouCompleteMe needs this.
set encoding=utf-8

call plug#begin('~/.vim/plugged')

" let Vundle manage Vundle, required
Plug 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plug commands between vundle#begin/end.
" plugin on GitHub repo
" Plug 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plug 'L9'
Plug 'kien/ctrlp.vim'
Plug 'kopischke/vim-fetch'
" Plug 'tComment'
Plug 'tomtom/tcomment_vim'
Plug 'git://github.com/zeis/vim-kolor.git'
Plug 'https://github.com/scrooloose/nerdtree.git'

" This plugin maps <leader>t* to stuff; screws up plain-old <leader>t for symbol search.
" Plug 'Align'
Plug 'junegunn/vim-easy-align'

Plug 'vim-scripts/IndentAnything'
Plug 'vim-scripts/matchit.zip'
" Plug 'https://github.com/ervandew/supertab.git'
Plug 'https://github.com/tpope/vim-surround.git'
" Plug 'Tagbar'
Plug 'majutsushi/tagbar'
Plug 'travisjeffery/vim-gotosymbol'
" Plug 'marvim'
Plug 'chamindra/marvim'
Plug 'vim-scripts/AnsiEsc.vim'
Plug 'git://github.com/milkypostman/vim-togglelist'
" Plug 'vimpager'
Plug 'rkitover/vimpager'
Plug 'https://github.com/rking/ag.vim.git'
Plug 'git://github.com/matze/vim-move'
Plug 'https://github.com/vim-scripts/Tail-Bundle.git'
Plug 'https://github.com/tpope/vim-dispatch.git'
Plug 'https://github.com/vim-scripts/Conque-GDB.git'
" Plug
" 'neoclide/coc.nvim'
" Plug 'https://github.com/Valloric/YouCompleteMe.git'
" Need to upgrade vim for this to work.
" Plug 'fatih/vim-go'
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
" Plug 'dense-analysis/ale'

" https://sherif.io/2016/05/30/favorite-vim-plugins.html
Plug 'airblade/vim-gitgutter'

Plug 'nathanaelkane/vim-indent-guides'

Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'reedes/vim-colors-pencil'
Plug 'sjl/badwolf'
Plug 'itchyny/lightline.vim'
" Plug 'junegunn/goyo.vim'

" Plug 'easymotion/vim-easymotion'

Plug 'https://github.com/davidhalter/jedi-vim.git'

" Optional:
Plug 'honza/vim-snippets'

" imap <C-BS> <C-W>
" noremap! <C-BS> <C-w>
" noremap! <C-h> <C-w>

" if you use Vundle, load plugins:
" Plug 'ervandew/supertab'
Plug 'SirVer/ultisnips'

" " make YCM compatible with UltiSnips (using supertab)
" let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
" let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
" let g:SuperTabDefaultCompletionType = '<C-n>'

" " better key bindings for UltiSnipsExpandTrigger
" let g:UltiSnipsExpandTrigger = "<tab>"
" let g:UltiSnipsJumpForwardTrigger = "<tab>"
" let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" Git plugin not hosted on GitHub
" Plug 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plug 'file:///home/gmarik/path/to/plugin'
" " The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
" Plug 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plug 'ascenator/L9', {'name': 'newL9'}

" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clangd-completer' }
" --clang-completer


" Initialize plugin system
call plug#end()

"
" coc.nvim ccls support.
"

" if executable('ccls')
"     " https://github.com/MaskRay/ccls/wiki/coc.nvim
"     " https://github.com/neoclide/coc.nvim/blob/f3f43f58543135495d411ed948ac9ba2eca0880a/doc/coc.txt#L1020
"     call coc#config('languageserver', {
"                     \ 'ccls': {
"                     \   "command": "ccls",
"                     \   "trace.server": "verbose",
"                     \   "filetypes": ["c", "cpp", "cuda", "objc", "objcpp"],
"                     \   "rootPatterns": [".ccls-root", "compile_commands.json"],
"                     \   "initializationOptions": {
"                     \      "cache": {
"                     \        "directory": ".ccls-cache"
"                     \      }
"                     \    }
"                     \ }
"                     \})
"
"     " nmap <silent> <M-j> <Plug>(coc-definition)
"     " nmap <silent> <C-,> <Plug>(coc-references)
"     " nn <silent> K :call CocActionAsync('doHover')<cr>
"     "
"     " set updatetime=300
"     " au CursorHold * sil call CocActionAsync('highlight')
"     " au CursorHoldI * sil call CocActionAsync('showSignatureHelp')
"
"     " if hidden is not set, TextEdit might fail.
"     set hidden
"
"     " Some servers have issues with backup files, see #649
"     set nobackup
"     set nowritebackup
"
"     " Better display for messages
"     set cmdheight=2
"
"     " You will have bad experience for diagnostic messages when it's default 4000.
"     set updatetime=300
"
"     " don't give |ins-completion-menu| messages.
"     set shortmess+=c
"
"     " always show signcolumns
"     set signcolumn=yes
"
"     " Use tab for trigger completion with characters ahead and navigate.
"     " Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
"     inoremap <silent><expr> <TAB>
"           \ pumvisible() ? "\<C-n>" :
"           \ <SID>check_back_space() ? "\<TAB>" :
"           \ coc#refresh()
"     inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
"
"     function! s:check_back_space() abort
"       let col = col('.') - 1
"       return !col || getline('.')[col - 1]  =~# '\s'
"     endfunction
"
"     " Use <c-space> to trigger completion.
"     inoremap <silent><expr> <c-space> coc#refresh()
"
"     " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
"     " Coc only does snippet and additional edit on confirm.
"     inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
"     " Or use `complete_info` if your vim support it, like:
"     " inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
"
"     " Use `[g` and `]g` to navigate diagnostics
"     nmap <silent> [g <Plug>(coc-diagnostic-prev)
"     nmap <silent> ]g <Plug>(coc-diagnostic-next)
"
"     " Remap keys for gotos
"     nmap <silent> gd <Plug>(coc-definition)
"     nmap <silent> gy <Plug>(coc-type-definition)
"     nmap <silent> gi <Plug>(coc-implementation)
"     nmap <silent> gr <Plug>(coc-references)
"
"     " Use K to show documentation in preview window
"     nnoremap <silent> K :call <SID>show_documentation()<CR>
"
"     function! s:show_documentation()
"       if (index(['vim','help'], &filetype) >= 0)
"         execute 'h '.expand('<cword>')
"       else
"         call CocAction('doHover')
"       endif
"     endfunction
"
"     " Highlight symbol under cursor on CursorHold
"     autocmd CursorHold * silent call CocActionAsync('highlight')
"
"     " Remap for rename current word
"     nmap <leader>rn <Plug>(coc-rename)
"
"     " Remap for format selected region
"     xmap <leader>f  <Plug>(coc-format-selected)
"     nmap <leader>f  <Plug>(coc-format-selected)
"
"     augroup mygroup
"       autocmd!
"       " Setup formatexpr specified filetype(s).
"       autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
"       " Update signature help on jump placeholder
"       autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
"     augroup end
"
"     " Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
"     xmap <leader>a  <Plug>(coc-codeaction-selected)
"     nmap <leader>a  <Plug>(coc-codeaction-selected)
"
"     " Remap for do codeAction of current line
"     nmap <leader>ac  <Plug>(coc-codeaction)
"     " Fix autofix problem of current line
"     nmap <leader>qf  <Plug>(coc-fix-current)
"
"     " Create mappings for function text object, requires document symbols feature of languageserver.
"     xmap if <Plug>(coc-funcobj-i)
"     xmap af <Plug>(coc-funcobj-a)
"     omap if <Plug>(coc-funcobj-i)
"     omap af <Plug>(coc-funcobj-a)
"
"     " Use <C-d> for select selections ranges, needs server support, like: coc-tsserver, coc-python
"     nmap <silent> <C-d> <Plug>(coc-range-select)
"     xmap <silent> <C-d> <Plug>(coc-range-select)
"
"     " Use `:Format` to format current buffer
"     command! -nargs=0 Format :call CocAction('format')
"
"     " Use `:Fold` to fold current buffer
"     command! -nargs=? Fold :call     CocAction('fold', <f-args>)
"
"     " use `:OR` for organize import of current buffer
"     command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
"
"     " Add status line support, for integration with other plugin, checkout `:h coc-status`
"     set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
"
"     " Using CocList
"     " Show all diagnostics
"     nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
"     " Manage extensions
"     nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
"     " Show commands
"     nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
"     " Find symbol of current document
"     nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
"     " Search workspace symbols
"     nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
"     " Do default action for next item.
"     nnoremap <silent> <space>j  :<C-u>CocNext<CR>
"     " Do default action for previous item.
"     nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
"     " Resume latest coc list
"     nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
"
" endif


"
" Plugin configuration:
"

" Plug 'junegunn/vim-easy-align'
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" Plug 'airblade/vim-gitgutter'
" Update signs when file is saved
autocmd BufWritePost * GitGutter

" Plug 'nathanaelkane/vim-indent-guides'
let g:indent_guides_guide_size = 1
let g:indent_guides_color_change_percent = 3
let g:indent_guides_enable_on_vim_startup = 1

" Plug 'SirVer/ultisnips'
let g:UltiSnipsExpandTrigger= "<c-f>"
let g:UltiSnipsJumpForwardTrigger = "<c-f>"

"
" End plugin configuration
"

filetype plugin indent on
" To ignore plugin indent changes, instead use:
"filetype plugin on

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
set tabstop=8
set shiftwidth=4
set softtabstop=4
set backspace=indent,eol,start
":set cindent
":set smartindent
:set shiftwidth=4
:set expandtab
colorscheme badwolf
" colorscheme kolor
" colorscheme jellybeans

" ctags
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
noremap <Leader>g :tselect<CR>
set tags-=./TAGS
set tags-=TAGS

" if we visually select text, search for that text from our current cursor
vmap <C-f> y/<C-r>"<CR>

:set ruler

nnoremap <silent> <c-w>t :tabnew<CR>

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

" Search for tags in the current buffer (same key binding as intellij).
nnoremap <silent> <Leader>t :CtrlPBufTag<CR>
nnoremap <silent> <Leader>p :CtrlP<CR>
" let g:ctrlp_map = '<Leader>p'
nnoremap <silent> <Leader>P :CtrlPMRUFiles<CR>

" nmap <silent> <Leader>p :FZF<CR>
let g:ctrlp_map = '<Leader>0'

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

" set nowrap

" set noincsearch
set incsearch

" cmap <C-v> <C-r>"

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

" let g:SuperTabDefaultCompletionType = "context"
" let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']

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
noremap <C-S>		:update!<CR><Esc>
vnoremap <C-S>		<C-C>:update!<CR><Esc>
inoremap <C-S>		<C-O>:update!<CR><Esc>

" CTRL-X and SHIFT-Del are Cut
" vnoremap <C-X> "+x
" inoremap <C-X> <Esc>"+x<Return>i

" CTRL-C and CTRL-Insert are Copy
" vnoremap <C-C> "+y

if executable('xclip')
    " Use xclip for seamless remote copy/paste.
    " https://defuse.ca/blog/clipboard-over-ssh-with-vim.html
    vmap "+y :!xclip -f -sel clip
    map "+p :r!xclip -o -sel clip
endif

" CTRL-V and SHIFT-Insert are Paste
" vnoremap <C-V>		"+gP
" inoremap <C-V> <Esc>"+gP<Return>i

" set t_Co=256
"
noremap <C-q> :q<CR>
vnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>

" map <Leader>m <Esc>:make<Up><CR>
silent! unmap <Leader>m
map <Leader>m <Esc>:Make<Up><CR>

set wildmode=longest,list,full
set wildmenu

" replace visually selected text in the whole buffer
vnoremap <C-r> "hy:%s/<C-r>h//gc<left><left><left>
vnoremap <C-t> "hy:%s/\c<C-r>h/\=SmartCase('')/gc<left><left><left><left><left>

let vimrplugin_underscore = 0

" set diffopt=filler,iwhite
set diffopt=filler
" if &diff
"     " diff mode
"     set diffopt+=iwhite
" endif

" set verbose=9
" let loaded_matchparen = 0
" DoMatchParen
" :NoMatchParen

let g:ctrlp_working_path_mode = ''

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

call tcomment#type#Define("gsp_block", "<%%--%s--%%>\n     ")
call tcomment#type#Define("gsp", "<%%-- %s --%%>")

call tcomment#type#Define('cmake',               '# %s'             )
"
" to change the macro storage location use the following 
" let marvim_store = '/usr/local/share/projectX/marvim' 
let marvim_find_key = '<Leader>r' " change find key from <F2> to 'space'
let marvim_store_key = '<Leader>d'     " change store key from <F3> to 'ms'
" let marvim_register = 'c'       " change used register from 'q' to 'c'
" let marvim_prefix = 0           " disable default syntax based prefix
command! MarSave call Marvim_macro_store()
command! MarSearch call Marvim_search()

function! ToggleYcm()
    let s:prev = g:ycm_auto_trigger
    let g:ycm_auto_trigger = !g:ycm_auto_trigger
    if s:prev
        echo "YCM auto-complete disabled"
    else
        echo "YCM auto-complete enabled"
    endif
endfunction
command! ToggleYcm call ToggleYcm()

set t_te= t_ti=
let g:easytags_auto_update = 0
set history=200

set keywordprg=~/.vim/bin/imfeelinglucky.py

map + <C-A>
map _ <C-X>

" Use ctrl-[hjkl] to select the active split!
noremap <silent> <c-k> :wincmd k<CR>
noremap <silent> <c-j> :wincmd j<CR>
noremap <silent> <c-h> :wincmd h<CR>
noremap <silent> <c-l> :wincmd l<CR>
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
" hi clear SpellBad

map <c-f> :tnext<CR>
set autoread

map <silent> <leader>f <esc>:!echo % \| xargs realpath \| xsel --clipboard -i<cr><cr>
map <silent> <leader>F <esc>:!echo % \| xargs realpath \| sed 's/$/:<C-R>=line(".")<cr>/' \| xsel --clipboard -i<cr><cr>

" Trigger prompt to reload changed files on buffer enter.
au FocusGained,BufEnter * checktime

set tabpagemax=50

autocmd BufNewFile,BufRead *.cl set ft=c

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
map <Leader>f <Esc>:!realpath % \| tr -d '\n' \| xsel --clipboard -i<CR>
map <Leader>F <Esc>:call system("echo " . shellescape(expand("%") . ":" . line(".")) . "\| tr -d '\n' \| xsel --clipboard -i")<CR>

nmap <C-f> :tnext<CR>

let g:ConqueGdb_Leader = '`'
command! MarSave call Marvim_macro_store()
command! MarRun call Marvim_search()

" " https://github.com/vheon/dotvim/blob/5321347027c21e4c22dc6fcea4cc315052ed25f1/vimrc
" let g:ycm_global_ycm_extra_conf = '~/.ycm.py'
" let g:ycm_confirm_extra_conf    = 0
" " let g:ycm_global_ycm_extra_conf = g:dotvim.'/ycm.py'
" " let g:ycm_extra_conf_vim_data   = ['&filetype']
" let g:ycm_seed_identifiers_with_syntax = 1
" " Autocomplete keeps replacing text as I type for this filetypes...
" let g:ycm_min_num_of_chars_for_completion = 99
" let g:ycm_auto_trigger = 0
" " Until I figure out why lets just disable it...
" " Doesn't work.. still triggers.. just use ToggleYcm
" " let g:ycm_filetype_specific_completion_to_disable = {
" "             \ 'sh': 1
" "             \}

" imap <C-\> <Plug>snipMateNextOrTrigger
" let g:snips_trigger_key = '<C-\>'
imap <C-J> <esc>a<Plug>snipMateNextOrTrigger
smap <C-J> <Plug>snipMateNextOrTrigger

" AlignMapsClean

" uoftpc
" source ~/.vimrc.uoftpc

" source ~/.vimrc.samsung.private

function! AddSystemTags()
   if filereadable("/usr/include/c++/tags")
       set tags+=/usr/include/c++/tags
   endif
endfunction
call AddSystemTags()

" Maps F2 to go to next compile error.
" Maps leader-F2 to go to previous compile error.
" NOTE: shift+F2 (i.e. <S-F2>) doesn't work
" This link advises against modifiers + F-keys:
" https://superuser.com/questions/508655/map-shift-f3-in-vimrc
map <silent> <F2> :cnext<CR>
map <silent> <Leader><F2> :cprev<CR>

source ~/.vimrc.rocm
