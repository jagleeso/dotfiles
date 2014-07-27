" <leader>g == re-run script
map <buffer> <leader>g 
            \ma
            \:%!adjust_iram.py --input $KERN/iram.iram_words.txt
            \<CR>
            \`a

" crun adb_sudo cat /sys/kernel/debug/iram | adjust_iram.py --input -

" use assembly syntax highlighting
set filetype=asm
syntax on
" for some reason syntax on re-enables spelling syntax highlighting...
set spell
hi clear SpellBad
