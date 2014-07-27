" <leader>g = disassemble compiled asm.s
"
" gg^/deadbeef<CR>kvggD^nnjvGDgg^ == delete everything between the two 0xdeadbeef's
" map <buffer> <leader>g :%!make asm && cat asm.o \| disasm<CR> gg^/deadbeef<CR>kvggD^nnjvGDgg^
map <buffer> <leader>g 
            \:%!(cd $IRAM/scripts/c; make asm && cat obj/local/armeabi-v7a/objs-debug/asm/asm.o \| disasm);
            \<CR>
            \gg^/deadbeef<CR>kvggD^nnjvGDgg^
            " \ma
            " \`a

" use assembly syntax highlighting
set filetype=asm
syntax on
" for some reason syntax on re-enables spelling syntax highlighting...
set spell
hi clear SpellBad
