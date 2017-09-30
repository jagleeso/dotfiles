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
