" <leader>r == re-run kernel module, disassemble iram + ram
map <buffer> <leader>g 
            \ma
            \:%!( cd $IRAM/kmod; make clean; make run )
            \&& ( echo "\n>> TCM_CODE:"  && crun adb_sudo cat /sys/kernel/debug/tcm_code \| mem_bin.py \| disasm )
            \<CR>
            \`a

            " \&& ( echo "\n>> COHERENT:"  && crun adb_sudo cat /sys/kernel/debug/coherent \| mem_bin.py \| disasm )
            " \&& ( echo "\n>> IRAM:"      && crun adb_sudo cat /sys/kernel/debug/iram     \| mem_bin.py \| disasm )
            " \&& ( echo "\n>> RAM:"       && crun adb_sudo cat /sys/kernel/debug/ram      \| mem_bin.py \| disasm )
            " \&& ( echo "\n>> VEC:"  && crun adb_sudo cat /sys/kernel/debug/vec  \| mem_bin.py \| disasm )

" use assembly syntax highlighting
set filetype=asm
syntax on
" for some reason syntax on re-enables spelling syntax highlighting...
set spell
hi clear SpellBad
