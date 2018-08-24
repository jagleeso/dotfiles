#!/usr/bin/env python
from __future__ import print_function
import argparse
import os
import textwrap
import re
import sys
import subprocess
import itertools
from pprint import pprint
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
            'gdb',
            # 'arm-linux-gdb',
            # 'aarch64-linux-android-gdb',
            # 'aarch64-linux-gdb',
            ]:
        path = which(program)
        if path is not None:
            return program
DEFAULT_ARM_GDB = find_gdb()


# backtrace C++ library:
# https://github.com/bombela/backward-cpp
"""
#31   Object "python3", at 0x53c1cf, in PyEval_EvalFrameEx
#30   Object "python3", at 0x540198, in 
#29   Object "python3", at 0x53bd91, in PyEval_EvalFrameEx
#28   Object "python3", at 0x540198, in 
#27   Object "python3", at 0x53b7e3, in PyEval_EvalFrameEx
#26   Object "python3", at 0x53b7e3, in PyEval_EvalFrameEx
#25   Object "python3", at 0x53c1cf, in PyEval_EvalFrameEx
#24   Object "python3", at 0x5406de, in 
#23   Object "python3", at 0x53c1cf, in PyEval_EvalFrameEx
#22   Object "python3", at 0x5406de, in 
#21   Object "python3", at 0x53b7e3, in PyEval_EvalFrameEx
#20   Object "python3", at 0x53b7e3, in PyEval_EvalFrameEx
#19   Object "python3", at 0x53bd91, in PyEval_EvalFrameEx
#18   Object "python3", at 0x540198, in 
#17   Object "python3", at 0x53c1cf, in PyEval_EvalFrameEx
#16   Object "python3", at 0x5406de, in 
#15   Object "python3", at 0x53bba5, in PyEval_EvalFrameEx
#14   Object "python3", at 0x5c1796, in PyObject_Call
#13   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65c6fca, in 
#12   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65d3019, in _ctypes_callproc
#11   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65d888a, in ffi_call
#10   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65d8e1f, in ffi_call_unix64
#9    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c5df866, in MXImperativeInvokeEx
#8    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c5df518, in MXImperativeInvokeImpl(void*, int, void**, int*, void***, int, char const**, char const**)
#7    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9be47b6b, in mxnet::Imperative::Invoke(mxnet::Context const&, nnvm::NodeAttrs const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&)
#6    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9be473f5, in mxnet::Imperative::InvokeOp(mxnet::Context const&, nnvm::NodeAttrs const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&, std::vector<mxnet::OpReqType, std::allocator<mxnet::OpReqType> > const&, mxnet::DispatchMode, mxnet::OpStatePtr)
#5    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9be53a9a, in mxnet::imperative::PushFCompute(std::function<void (nnvm::NodeAttrs const&, mxnet::OpContext const&, std::vector<mxnet::TBlob, std::allocator<mxnet::TBlob> > const&, std::vector<mxnet::OpReqType, std::allocator<mxnet::OpReqType> > const&, std::vector<mxnet::TBlob, std::allocator<mxnet::TBlob> > const&)> const&, nnvm::Op const*, nnvm::NodeAttrs const&, mxnet::Context const&, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, std::vector<mxnet::Resource, std::allocator<mxnet::Resource> > const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&, std::vector<mxnet::MultiVersionedNDArray*, std::allocator<mxnet::MultiVersionedNDArray*> > const&, std::vector<unsigned int, std::allocator<unsigned int> > const&, std::vector<mxnet::OpReqType, std::allocator<mxnet::OpReqType> > const&)
#4    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c58c780, in mxnet::Engine::PushSync(std::function<void (mxnet::RunContext)>, mxnet::Context, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, mxnet::FnProperty, int, char const*, bool)
#3    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c58d717, in mxnet::engine::NaiveEngine::PushAsync(std::function<void (mxnet::RunContext, mxnet::engine::CallbackOnComplete)>, mxnet::Context, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, std::vector<mxnet::engine::Var*, std::allocator<mxnet::engine::Var*> > const&, mxnet::FnProperty, int, char const*, bool)
#2    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c59a9e9, in mxnet::Engine::PushContext(mxnet::Context)
#1    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c59c51f, in backward::StackTraceImpl<backward::system_tag::linux_tag>::load_here(unsigned long)
#0    Object "/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so", at 0x7fff9c59e27b, in unsigned long backward::details::unwind<backward::StackTraceImpl<backward::system_tag::linux_tag>::callback>(backward::StackTraceImpl<backward::system_tag::linux_tag>::callback, unsigned long)
"""

# MXNet
'''
Stack trace returned 10 entries:
[bt] (0) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(dmlc::StackTrace[abi:cxx11]()+0x59) [0x7f53e9ed61a4]
[bt] (1) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(dmlc::LogMessageFatal::~LogMessageFatal()+0x2a) [0x7f53e9ed64be]
[bt] (2) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(mxnet::MultiVersionedNDArray::IsUniqueView(long) const+0x189) [0x7f53ec583a4b]
[bt] (3) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(mxnet::kvstore::KVStoreLocal::PushImpl(std::vector<int, std::allocator<int> > const&, std::vector<mxnet::MultiVersionedNDArray, std::allocator<mxnet::MultiVersionedNDArray> > const&, int)+0x320) [0x7f53eccda5fe]
[bt] (4) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(mxnet::kvstore::KVStoreLocal::Push(std::vector<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, std::allocator<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > > > const&, std::vector<mxnet::MultiVersionedNDArray, std::allocator<mxnet::MultiVersionedNDArray> > const&, int)+0xaa) [0x7f53ecd07472]
[bt] (5) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(MXKVStorePushEx+0x18b) [0x7f53ecc7e9fe]
[bt] (6) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(ffi_call_unix64+0x4c) [0x7f5446c44e20]
[bt] (7) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(ffi_call+0x2eb) [0x7f5446c4488b]
[bt] (8) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(_ctypes_callproc+0x49a) [0x7f5446c3f01a]
[bt] (9) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(+0x9fcb) [0x7f5446c32fcb]
'''

def main():
    parser = argparse.ArgumentParser(description="debug kernel module oops by showing last line number")
    parser.add_argument("--input", default="-",
        help="for things like unwind_backtrace+0x0/0xe8, print context")
    parser.add_argument("--obj",
        help="default obj.o file")
    parser.add_argument("--gdb",
        default=DEFAULT_ARM_GDB,
        help="gdb command")
    parser.add_argument("--just-first", action="store_true",
        help="Just lookup the first function+0x1c in a line")
    parser.add_argument("--debug", action="store_true",
                        help="debug")
    parser.add_argument("--no-silent", action="store_true",
                        help="By default, it just outputs .gdb.stacktrace which must be "
                             "sourced in gdb; use this to also try to load the symbols in "
                             "gdb and print it")
    args = parser.parse_args()

    args.silent = not args.no_silent

    if os.path.exists('.gdbinit') and os.getcwd() != os.path.expandvars('$HOME'):
        parser.error("WARNING: .gdbinit is in this directory, run from another place to avoid sourcing it.")

    if not any(f is not None for f in [args.input]):
        parser.error("need a file")

    inp_parser = InputParser(args.input, args=args)
    ds = inp_parser.parse()
    assert ds is not None

    bt = Backtrace(ds, args.obj, args.gdb, args=args)
    lines = bt.backtrace()
    if not args.silent:
        for line in lines:
            print(line)
    else:
        # Echo input to output
        for line in inp_parser.lines:
            print(line)

def file_handle(string_or_handle):
    if type(string_or_handle) == str:
        if string_or_handle == '-':
            return sys.stdin
        return open(string_or_handle)
    return string_or_handle

objdump_hex_re = r"(?:[\da-f]+)"
hex_re = r"(?:[\da-f]+)"
offset_re = r"(?:0x[\da-zA-Z]+)"
function_re = r"(?:[_a-zA-Z][a-zA-Z\d_]*)"
srcline_re = r"(?:({function_re})\+({offset_re}))".format(**locals())
"""
#14   Object "python3", at 0x5c1796, in PyObject_Call
#13   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65c6fca, in
"""
backward_re = r'^\s*#\d+\s+Object "(?P<obj>[^"]+)", at 0x(?P<offset>{hex_re}), in'.format(hex_re=hex_re)

"""
[bt] (1) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(dmlc::LogMessageFatal::~LogMessageFatal()+0x2a) [0x7f53e9ed64be]
[bt] (9) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(+0x9fcb) [0x7f5446c32fcb]
"""
mxnet_re = r'\[bt\] \(\d+\) (?P<obj>[^(]+)\(.*\) \[0x(?P<offset>{hex_re})\]'.format(hex_re=hex_re)

def test_re():

    backward_str_01 = '#14   Object "python3", at 0x5c1796, in PyObject_Call'
    assert re.search(backward_re, backward_str_01)

    backward_str_02 = '#13   Object "/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so", at 0x7ffff65c6fca, in'
    assert re.search(backward_re, backward_str_02)

    mxnet_str_01 = "[bt] (1) /home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so(dmlc::LogMessageFatal::~LogMessageFatal()+0x2a) [0x7f53e9ed64be]"
    assert re.search(mxnet_re, mxnet_str_01)

    mxnet_str_02 = "[bt] (9) /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so(+0x9fcb) [0x7f5446c32fcb]"
    assert re.search(mxnet_re, mxnet_str_02)

class InputParser:
    def __init__(self, inp, args):
        self.inp = inp
        self.ds = []
        self.f = file_handle(self.inp)
        self.args = args
        self.lines = []

    def parse_input(self, input, just_first):

        offset_re = r'^({objdump_hex_re}):'.format(objdump_hex_re=objdump_hex_re)
        hex_re = r'(0x{objdump_hex_re})'.format(objdump_hex_re=objdump_hex_re)

    def _srcline_matches(self, line, regex):
        if self.args.just_first:
            m = re.search(regex, line)
            if not m:
                return []
            return [m.groups()]
        return re.findall(regex, line)

    def find_matches(self, line, regex, get_match, get_append):
        matched = False
        seen = set()
        for m in self._srcline_matches(line, regex):
            matched = True

            val = get_match(m)
            if val in seen:
                continue
            seen.add(val)

            d = get_append(val)
            self.ds.append(d)
        return matched

    @property
    def debug(self):
        return self.args.debug

    def parse(self):

        # mxnet_re = r'\[bt\] \(\d+\) (?P<obj>[^(]+)\(.*\) \[0x(?P<offset>{hex_re})\]'.format(hex_re=hex_re)
        def mxnet_match(m):
            obj, offset = m
            return (obj, offset)
        def mxnet_append(val):
            obj, offset = val
            return {
                'obj': obj,
                'offset': offset,
            }

        # backward_re = r'^\s*#\d+\s+Object "(?P<obj>[^"]+)", at 0x(?P<offset>{hex_re}), in'.format(hex_re=hex_re)
        def backward_match(m):
            obj, offset = m
            return (obj, offset)
        def backward_append(val):
            obj, offset = val
            return {
                'obj': obj,
                'offset': offset,
            }

        # srcline_re = r"(?:({function_re})\+({offset_re}))".format(**locals())
        def func_match(m):
            function, offset = m
            return (function, offset)
        def func_append(val):
            function, offset = val
            return {
                'function': function,
                'offset': offset,
            }

        # offset_re = r"(?:0x[\da-zA-Z]+)"
        def offset_match(m):
            offset = m[0]
            return offset
        def offset_append(val):
            offset = val
            return {
                'offset': offset,
            }

        # hex_re = r"(?:[\da-z]{8})"
        def hex_match(m):
            offset = m[0]
            return offset
        def hex_append(val):
            offset = val
            return {
                'offset': offset,
            }

        for line in self.f:
            line = line.rstrip()
            self.lines.append(line)

            if self.find_matches(line, mxnet_re, mxnet_match, mxnet_append):
                continue

            if self.find_matches(line, backward_re, backward_match, backward_append):
                continue

            if self.find_matches(line, srcline_re, func_match, func_append):
                continue

            if self.find_matches(line, offset_re, offset_match, offset_append):
                continue

            if self.find_matches(line, hex_re, hex_match, hex_append):
                continue

        self.f.close()
        return self.ds

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

class Backtrace:
    '''

    :param ds:
    [{
        ['function':'some_func,']       # Optional.
        'offset':0x2a                   # If function not provided, use as absolute offset into object file,
                                        # o/w, use as offset from function.
        'obj':"some/object_file.o",
     },
     ...]
    :param obj:
    :param gdb:
    :return:
    '''
    def __init__(self, ds, obj=None, gdb=DEFAULT_ARM_GDB, args=None):
        self.ds = ds
        self.obj = obj
        self.gdb = gdb
        self.args = args

    def _split_by_obj(self):
        assert self.obj is None and all('obj' in d for d in self.ds)
        grouped_ds = my_groupby(self.ds, lambda d: d['obj'])
        lines = []
        for obj, entries in grouped_ds:
            if self.debug:
                pprint({'mode':'_split_by_obj', 'entries':entries, 'obj':obj})
            ret = self._gdb_backtrace(entries, obj)
            if not self.args.silent:
                lines.extend(ret)
        return lines

    def backtrace(self):
        if self.obj is None and all('obj' in d for d in self.ds):
            return self._split_by_obj()
        return self._gdb_backtrace(self.ds, self.obj)

    def _gdb_backtrace(self, ds, obj):
        if self.debug:
            pprint({'ds':ds, 'obj':obj})
        if os.path.exists('.gdbinit') and os.getcwd() != os.path.expandvars('$HOME'):
            raise RuntimeError("WARNING: .gdbinit is in this directory, run from another place to avoid sourcing it.")
        with open('.gdbinit.koops', 'w') as gdbinit:
            def write(string, d={}):
                try:
                    gdbinit.write(textwrap.dedent(string.format(**d)))
                except Exception as e:
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
                else:
                    raise NotImplementedError("Not sure how to convert to 'list *(0x<offset>)': {d}".format(d=d))
                # elif type(d) == str and re.match(r'(0x)?[0-9a-z]', d):
                #     write("""
                #     list *(0x{offset})
                #     """, {'offset':parse_offset(d)})
            if not self.args.silent:
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

        if self.args.silent:
            return

        cmd = [self.gdb, obj, '-x', '.gdbinit.koops']
        if self.debug:
            pprint({'cmd':cmd})
        output = subprocess.check_output(cmd)
        # proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        lines = []
        for line in re.split('\n', output):
            line = line.rstrip()
            if should_error(line):
                raise GDBError("ERROR: " + line)
            if should_skip(line):
                continue
            if line == '':
                continue
            lines.append(line)
        return lines

    @property
    def debug(self):
        return self.args.debug

def union(d1, d2):
    return dict(d1.items() + d2.items())

def strip_hex_prefix(string):
    return re.sub('^0x', '', string)

def parse_offset(string):
    return strip_hex_prefix(string)
    # return strip_hex_prefix(decaddr(string))

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
        for i in range(0, 8):
            key |= first_byte_of_key << i*8
        return {'decaddr':'0x' + _hex(_int(addr) ^ key),
                'key':'0x' + _hex(key)}
    return map(__d, addrs)

def my_groupby(xs, key=None):
    return [(k, list(g)) for k, g in itertools.groupby(xs, key)]

if __name__ == '__main__':
    main()
