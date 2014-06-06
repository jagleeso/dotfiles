" <leader>r == re-run kernel module, disassemble iram
map <buffer> <leader>g :%!( cd $IRAM/kmod; make clean; make run ) && crun adb_sudo cat /sys/kernel/debug/iram \| mem_bin.py \| disasm<CR>
" use assembly syntax highlighting
set filetype=asm
syntax on
" for some reason syntax on re-enables spelling syntax highlighting...
set spell
hi clear SpellBad
