#!/usr/bin/env python
import sys
import re

def lines():
    for line in sys.stdin:
        yield line.rstrip()

func = None
func_lines = []
saw_stp = False
print_func = [False]
def check_func():
    if print_func[0]:
        print
        for line in func_lines:
            print line
    print_func[0] = False
for line in lines():
    if saw_stp:
        print_func[0] = not re.search(r'(mov|add)\tx29, sp', line)
        saw_stp = False
    # ffffffc00008a0e8 <walk_stackframe>:
    m = re.search(r'^[a-z0-9]{16} <(?P<func>[^>]+)>:', line)
    if m:
        check_func()
        func = m.group('func')
        func_lines = [line]
        saw_stp = False
        continue
    # ffffffc00008a0e8:	a9bd7bfd 	stp	x29, x30, [sp,#-48]!
    m = re.search(r'stp\tx29, x30', line)
    if m:
        saw_stp = True
    func_lines.append(line)
check_func()
