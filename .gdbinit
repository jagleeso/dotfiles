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
dashboard -layout source stack expressions
dashboard stack -style limit 5
dashboard stack -style compact True
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
