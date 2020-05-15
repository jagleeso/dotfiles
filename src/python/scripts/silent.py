#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from os.path import dirname as _d, basename as _b, exists as _e
import argparse
import tempfile
import os
import shutil
import re
import pprint
from glob import glob
import pprint
import subprocess
from io import StringIO
import sys
from contextlib import contextmanager

def print_log(msg):
    sys.stderr.write("[silent.py] ")
    sys.stderr.write(msg)
    sys.stderr.write("\n")

def print_file(path, out=sys.stdout):
    with open(path, "r") as f:
        shutil.copyfileobj(f, out)

class FileDeleterState:
    def __init__(self, keep):
        self.keep = keep

@contextmanager
def FileDeleter(path, keep_file=False):
    file_deleter = FileDeleterState(keep=keep_file)
    try:
        yield file_deleter
    finally:
        if not file_deleter.keep and os.path.exists(path):
            os.remove(path)

def run_cmd(args, cmd_argv):
    if args.temp_path is not None:
        args.keep_output = True

    if args.temp_path is not None:
        temp_path = args.temp_path
    else:
        os_fd, temp_path = tempfile.mkstemp(
            prefix="{prefix}_".format(prefix=args.out_prefix),
            suffix=".txt",
            dir=os.getcwd())
        os.close(os_fd)

    if args.keep_output or args.debug:
        print_log("Putting command output in {path}".format(path=temp_path))
    with FileDeleter(temp_path, keep_file=args.keep_output) as file_deleter, \
         open(temp_path, "w+b") as f:
        if args.debug:
            cmd_str = ' '.join(cmd_argv)
            print_log("$ {cmd}".format(cmd=cmd_str))
        proc = subprocess.Popen(cmd_argv, stdout=f, stderr=f)

        # retcode = proc.wait()
        # return 0

        try:
            retcode = proc.wait()
        except KeyboardInterrupt:
            # NOTE: child received sigint too... follow it's lead.
            while True:
                try:
                    print_log("Got ctrl-c; waiting for child to respond...")
                    retcode = proc.wait()
                    break
                except KeyboardInterrupt:
                    pass
            print_log("Got ctrl-c; cmd exited with status={ret} -- output so far:".format(ret=retcode))
            print_file(temp_path)
            return retcode

        if retcode != 0:
            if args.keep_err_output:
                file_deleter.keep = True
                print_log("(--keep-err-output) stdout/stderr saved @ {path}".format(path=temp_path))
            print_log("Saw non-zero exit-status; cmd output was:")
            print_file(temp_path)
            return retcode

        if args.keep_output:
            print_log("Normal exit-status=0; cmd output was:")
            print_file(temp_path)
        return retcode


def main():
    """
    $ silent.py --debug -- python my_script.py --help
    $ silent.py python my_script.py --help

    :return:
    """
    default_out_prefix = "silent"
    parser = argparse.ArgumentParser(
        "Only print output when command fails. Log output of command in same directory.",
        # DON'T recognize "--debug" as "--debug-silent-py" ( common name for cmdline option )
        allow_abbrev=False)
    parser.add_argument('--debug-silent-py', action='store_true',
            help="debug")
    parser.add_argument('--keep-output', action='store_true',
                        help="don't discard temp file that stores command output, even when command succeeds")
    parser.add_argument('--out-prefix',
                        help=(
                            "don't discard temp file that stores command output, even "
                            "when command succeeds; default = {dflt}").format(dflt=default_out_prefix))
    parser.add_argument('--silent-py-prefix', action='store_true',
                        help="don't discard temp file that stores command output, even when command succeeds")
    parser.add_argument('--keep-err-output', action='store_true',
                        help="keep output if command fails")
    parser.add_argument('--temp-path',
                        help="where to store command output; implies --keep-output")

    args = None
    cmd_argv = None
    if '--' in sys.argv:
        cmd_argv = sys.argv[sys.argv.index('--') + 1:]
        silent_argv = sys.argv[1:sys.argv.index('--')]
        # print("(1)")
        # pprint.pprint({
        #     'cmd_argv': cmd_argv,
        #     'silent_argv': silent_argv,
        # })
        args = parser.parse_args(silent_argv)
    else:
        silent_argv = sys.argv[1:]
        # cmd_argv = sys.argv[sys.argv.index('--') + 1:]
        # silent_argv = sys.argv[:sys.argv.index('--')]
        # print("(2)")
        # pprint.pprint({
        #     # 'cmd_argv': cmd_argv,
        #     'silent_argv': silent_argv,
        # })
        args, cmd_argv = parser.parse_known_args(silent_argv)
        # pprint.pprint({
        #     'cmd_argv': cmd_argv,
        #     # 'silent_argv': silent_argv,
        # })
    args.debug = args.debug_silent_py

    if args.out_prefix is None:
        args.out_prefix = default_out_prefix
    else:
        # If they gave --out-prefix, then they certainly want the output too.
        args.keep_output = True

    retcode = run_cmd(args, cmd_argv)
    sys.exit(retcode)

if __name__ == "__main__":
    main()
