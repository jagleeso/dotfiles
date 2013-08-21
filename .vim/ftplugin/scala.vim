set makeprg=sbt\ -Dsbt.log.noformat=true\ compile
map <localleader>m <Esc>:SBT compile<CR>:QFix!<CR>
 
set efm=%E\ %#[error]\ %f:%l:\ %m,%C\ %#[error]\ %p^,%-C%.%#,%Z,
       \%W\ %#[warn]\ %f:%l:\ %m,%C\ %#[warn]\ %p^,%-C%.%#,%Z,
       \%-G%.%#
