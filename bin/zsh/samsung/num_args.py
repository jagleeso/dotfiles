#!/usr/bin/env python
import re
import argparse
import contextlib
import sys

def main():
    parser = argparse.ArgumentParser("count # of func args")
    parser.add_argument("--func",
            help="name of func")
    parser.add_argument("--input",
            help="name of func")
    parser.add_argument("--gdb", action='store_true', 
            help="name of func")
    parser.add_argument("--keep", action='store_true', 
            help="name of func")
    parser.add_argument("--summary-stats", action='store_true', 
            help="do summary statistics")
    args = parser.parse_args()

    input = None
    if args.input:
        input = open(args.input)
    else:
        input = sys.stdin

    if args.summary_stats:
        summary_stats(input)
        return

    with contextlib.closing(input):
        def scan_func(func, line=None, slurplines=False):
            if line is None:
                lines = []
            else:
                lines = [line]

            string = ''
            for line in input:
                line = line.rstrip('\n')
                if args.keep:
                    lines.append(line)
                m = re.search(r'^\d+\s*(.*)', line)
                if m:
                    string = string + m.group(1)
                elif not slurplines:
                    break

            m = re.search(func + r'\s*\(', string)
            if not m:
                for line in lines:
                    print line
                return
            junk, start = m.span()
            parens_open = 1
            end = start
            nargs = 0
            parens_open = 1
            for i, c in enumerate(string[start:], start=start):
                if c == '(':
                    parens_open += 1
                    continue
                if c == ')':
                    parens_open -= 1
                    if parens_open == 0:
                        end = i
                        break
                    continue
                if c == ',' and parens_open == 1:
                    nargs += 1
            if re.search(r'^\s*void\s*$', string[start:end]):
                nargs = 0
            else:
                nargs += 1

            print nargs
            for line in lines:
                print line
        if args.gdb:
            for line in input:
                line = line.rstrip('\n')
                # 0xffffffc00008607c is in migrate_irqs (arch/arm64/kernel/irq.c:98).
                m = re.search(r'^0x[^\s]+ is in ([^\s]+) \([^)]+\)\.', line)
                if m:
                    func = m.group(1)
                    scan_func(func, line)
                elif args.keep:
                    print line
        elif args.func:
            scan_func(args.func, None, slurplines=True)

def summary_stats(input):
    func = None
    nargs = None
    it = iter(input)
    try:
        while True:
            line = it.next()
            m = re.search(r'^([a-zA-Z][a-zA-Z0-9\._]+)$', line)
            if m:
                func = m.group(1)
                line = it.next()
                m = re.search(r'^(\d+)$', line)
                if m and nargs is None:
                    nargs = int(m.group(1))
                else:
                    nargs = None
                print "{func} {nargs}".format(**locals())
                func = None
                nargs = None
                while True:
                    line = it.next()
                    if re.search(r'^\s*$', line):
                        break

    except StopIteration:
        pass
    if re.search(r'^\s*$', line):
        if func is not None:
            print "{func} {nargs}".format(**locals())
        func = None
        nargs = None

if __name__ == '__main__':
    main()
