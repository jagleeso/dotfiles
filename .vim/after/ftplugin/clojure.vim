command! Use :exe s:Use(<f-args>)

let g:clojure_repl_use = [
            \     'clojure.pprint',
            \     'clojure.repl',
            \ ]

function! s:Use()
    for module in g:clojure_repl_use
        execute "Eval (use '".l:module.")"
    endfor
endfunction

nnoremap <Leader>e :Eval (pprint )<left>
