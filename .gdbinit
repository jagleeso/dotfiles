# set auto-solib-add 0

# TensorFlow
set auto-solib-add 1
# directory /home/james/clone/tensorflow
# directory /home/james/clone/tensorflow.patch

set print pretty on
set breakpoint pending on

python

import sys
import os

GDB_PRETTY_PRINTERS = os.path.join(
    os.path.expanduser('~'),
    'clone/gdb_printers__python',
)
if os.path.exists(GDB_PRETTY_PRINTERS):
    sys.path.insert(0, GDB_PRETTY_PRINTERS)
    from libstdcxx.v6.printers import register_libstdcxx_printers
    register_libstdcxx_printers (None)

end

source ~/.gdbinit.dashboard
# assembly

# NOTE: Set background color HTML color code to: #202020 in gnome-terminal for best results 
# with 'native' pygments color-scheme.
# We can try out pygments colors at:
#   https://pygments.org/demo/#try
dashboard -style syntax_highlighting native
dashboard -layout source stack expressions
dashboard stack -style limit 10
dashboard stack -style compact True
# Usually overly verbose... would be nice if it skipped non-primitives.
dashboard stack -style arguments False
# Give 20 source lines around the current line
dashboard source -style context 20

echo TIP:\n (1) Start a new tmux pane, and run "tty | cboard" in it\n (2) Run "dashboard -output <PASTE>" to redirect dashboard to it\n

# Refresh dashboard after 'up' and 'down'
#
# NOTE: hookpost-<CMD> works for any gdb command.
define hookpost-up
dashboard
end

define hookpost-down
dashboard
end

define hookpost-frame
dashboard
end

define hookpost-next
dashboard
end

define segaddr
p $_siginfo._sifields._sigfault.si_addr
end

# See "document str"
define str
    call (void)printf("> gdb: str $arg0\n")
    call $arg0.Print(std::cout, 1)
    call (void)printf("\n")
    # Flush anything that Print wrote to std::cout.
    call fflush(0)
end
document str
Helper function for calling Print method of object; 
assumes this method exists on arg0:

  class Object{ 
    void Print(std::ostream& out, int indent) const
  }
end

# set logging on
# echo Logging gdb output to ./gdb.log.txt
# set logging file gdb.log.txt
