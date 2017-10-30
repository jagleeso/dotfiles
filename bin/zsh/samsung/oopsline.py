#!/usr/bin/env python
import argparse
import os
import textwrap
import re
import sys
import subprocess
from os import environ as env

def each_procline(proc):
    while True:
        line = proc.stdout.readline()
        if line != '':
            yield line.rstrip()
        else:
            break

def which(fname):
    proc = subprocess.Popen(['which', fname], stdout=subprocess.PIPE)
    try:
        return next(each_procline(proc))
    except StopIteration:
        return None

def find_gdb():
    for program in [
            'arm-linux-gdb',
            'aarch64-linux-android-gdb',
            'aarch64-linux-gdb',
            ]:
        path = which(program)
        if path is not None:
            return program
DEFAULT_ARM_GDB = find_gdb()

def main():
    parser = argparse.ArgumentParser(description="debug kernel module oops by showing last line number")
    parser.add_argument("--lastkmsg",
        help="last kmsg log")
    parser.add_argument("--input",
        help="for things like unwind_backtrace+0x0/0xe8, print context")
    parser.add_argument("--obj",
        help="module.o file")
    parser.add_argument("--gdb",
        default=DEFAULT_ARM_GDB,
        help="gdb command")
    parser.add_argument("--kernel",
        default=env['KERN'] + '/vmlinux.o',
        help="gdb command")
    parser.add_argument("--just-first", action="store_true",
        help="Just lookup the first function+0x1c in a line")
    args = parser.parse_args()

    if os.path.exists('.gdbinit') and os.getcwd() != os.path.expandvars('$HOME'):
        parser.error("WARNING: .gdbinit is in this directory, run from another place to avoid sourcing it.")

    if not any(f is not None for f in [args.lastkmsg, args.input]):
        parser.error("need a file")

    ds = None
    dargs = None

    if args.lastkmsg is not None:
        d = parse_lastkmsg(args.lastkmsg)
        print "Call trace:"
        for t in d['trace']:
            print t
        ds = [d]
        dargs = vars(args)
    elif args.input is not None:
        ds = parse_input(args.input, args.just_first)
        dargs = vars(args)

    assert ds is not None and \
            dargs is not None

    if args.lastkmsg is not None:
        if args.obj is None:
            mod = ds[0]['module']
            if mod:
                args.obj = env['HOME'] + "/android/{mod}/{mod}.o".format(**locals())

    if not args.obj:
        args.obj = args.kernel

    if not args.obj:
        parser.error("need --obj")
    if not os.path.isfile(args.obj):
        obj = args.obj
        parser.error("{obj} doesn't exist".format(**locals()))

    for k in ['lastkmsg', 'input']:
        del dargs[k]
    del dargs['just_first']
    del dargs['kernel']
    
    for line in oopsline(ds, **dargs):
        print line

def file_handle(string_or_handle):
    if type(string_or_handle) == str:
        if string_or_handle == '-':
            return sys.stdin
        return open(string_or_handle)
    return string_or_handle

objdump_hex_re = r"(?:[\da-f]+)"
hex_re = r"(?:[\da-z]{8})"
offset_re = r"(?:0x[\da-zA-Z]+)"
function_re = r"(?:[_a-zA-Z][a-zA-Z\d_]*)"
srcline_re = r"(?:({function_re})\+({offset_re}))".format(**locals())

def parse_input(input, just_first):
    ds = []
    f = file_handle(input)
    def find_matches(regex, seen, get_match, get_append):
        def srcline_matches(line, regex):
            if just_first:
                m = re.search(regex, line)
                if not m:
                    return []
                return [m.groups()]
            return re.findall(regex, line)
        matched = False
        for m in srcline_matches(line, regex):
            matched = True

            val = get_match(m)
            if val in seen:
                continue
            func_seen.add(val)

            d = get_append(val)
            ds.append(d)
        return matched

    func_seen = set()
    offset_seen = set()
    hex_seen = set()

    offset_re = r'^({objdump_hex_re}):'.format(objdump_hex_re=objdump_hex_re) 
    hex_re = r'(0x{objdump_hex_re})'.format(objdump_hex_re=objdump_hex_re)

    def func_match(m):
        function, offset = m
        return (function, offset)
    def func_append(val):
        function, offset = val
        return {
            'function': function,
            'offset': offset,
            }
    def offset_match(m):
        offset = m[0]
        return offset 
    def offset_append(val):
        offset = val
        return {
            'offset': offset,
            }
    def hex_match(m):
        offset = m[0]
        return offset 
    def hex_append(val):
        offset = val
        return {
            'offset': offset,
            }

    for line in f:
        if find_matches(srcline_re, func_seen, func_match, func_append):
            continue

        if find_matches(offset_re, offset_seen, offset_match, offset_append):
            continue

        if find_matches(hex_re, hex_seen, hex_match, hex_append):
            continue

    f.close()
    return ds

def parse_lastkmsg(lastkmsg):
    d = {}
    f = file_handle(lastkmsg)
        
    for line in f:
        m = re.search(r"Internal error: Oops:", line)
        if m:
            break
    function = None
    offset = None
    for line in f:
        m = re.search(r"Modules linked in: ([^(]+)\(", line)
        if m:
            d['module'] = m.group(1)
            continue
        m = re.search(r"PC is at {srcline_re}/".format(**globals()), line)
        if m:
            function = m.group(1)
            offset = m.group(2)
            break
    assert function
    assert offset
    d['function'] = function
    d['offset'] = offset
    trace = []
    for line in f:
        m = re.search(r"\[<{hex_re}>\] \({function_re}\+{offset_re}".format(**globals()), line)
        if m:
            trace.append(line.rstrip())
            continue
        m = re.search(r"---\[ end trace .* \]---", line)
        if m:
            break
    d['trace'] = trace
    # read the rest so it doesn't get piped to gdb
    for line in f:
        pass
    f.close()

    return d

class GDBError(Exception):
    pass

def oopsline(ds, obj, gdb=DEFAULT_ARM_GDB):
    if os.path.exists('.gdbinit') and os.getcwd() != os.path.expandvars('$HOME'):
        raise RuntimeError("WARNING: .gdbinit is in this directory, run from another place to avoid sourcing it.")
    with open('.gdbinit.koops', 'w') as gdbinit:
        def write(string, d={}):
            try:
                gdbinit.write(textwrap.dedent(string.format(**d)))
            except Exception, e:
                import pdb; pdb.set_trace()
                raise e
        # list *({function})+{offset}
        for d in ds:
            if 'function' in d and 'offset' in d:
                write("""
                list *({function}+{offset})
                """, d)
            elif 'offset' in d:
                d['offset'] = parse_offset(d['offset'])
                write("""
                list *(0x{offset})
                """, d)
            elif type(d) == str and re.match(r'(0x)?[0-9a-z]', d):
                write("""
                list *(0x{offset})
                """, {'offset':parse_offset(d)})
        write("quit")

    # 0x28ca40 is in set_in_fips_err (crypto/testmgr.c:163).
    skip_until_match = r'^0x[0-9a-f]+ is in |^{objdump_hex_re}:\s+'.format(objdump_hex_re=objdump_hex_re)
    # skip_until_match = r'^f'.format(objdump_hex_re=objdump_hex_re)
    found = [False]
    def should_skip(line):
        if not found[0] and re.search(skip_until_match, line):
            found[0] = True
        return not found[0]

    def should_error(line):
        return re.search(r'Reading symbols from .*\(no debugging symbols found\)', line)

    cmd = [gdb, obj, '-x', '.gdbinit.koops']
    output = subprocess.check_output(cmd)
    # proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in re.split('\n', output):
        line = line.rstrip()
        if should_error(line):
            raise GDBError("ERROR: " + line)
        if should_skip(line):
            continue
        if line == '':
            continue
        yield line
    
def union(d1, d2):
    return dict(d1.items() + d2.items())

def strip_hex_prefix(string):
    return re.sub('^0x', '', string)

def parse_offset(string):
    return strip_hex_prefix(decaddr(string))

def last_module_loaded(lastkmsg):
    with open(lastkmsg) as f:
        for line in f:
            m = re.search(r"Modules linked in: ([^(]+)\(", line)
            if m:
                return m.group(1)

def decaddr(addr):
    return _d(addr)[0]['decaddr']

def _int(hex_string):
    """
    Convert a string of hex characters into an integer 

    >>> _int("ffffffc000206028")
    18446743798833766440L
    """
    return int(hex_string, 16)
def _hex(integer):
    return re.sub('^0x', '', hex(integer)).rstrip('L')
def _d(*addrs):
    """
    Assume key is like 
    0x1111111111111111
    Guess key, then decrypt used guessed key.
    """
    def __d(addr):
        addr = re.sub('^0x', '', addr)
        first_4bits = int(addr[0], 16)
        first_byte_of_key = (0xf ^ first_4bits) << 4 | (0xf ^ first_4bits)
        key = 0
        for i in xrange(0, 8):
            key |= first_byte_of_key << i*8
        return {'decaddr':'0x' + _hex(_int(addr) ^ key),
                'key':'0x' + _hex(key)}
    return map(__d, addrs)

if __name__ == '__main__':
    main()
