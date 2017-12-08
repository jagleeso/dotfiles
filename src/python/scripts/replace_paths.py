#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import shutil
import re
import pprint
import string
import textwrap
import unittest
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

import sys

import dot_util
from dot_util import ShellScript

ERROR_PATTERN_DEFAULT = r'\berror\b'
PATH_REGEX = r'(?:/?(?:[^/ :]+/)+(?:[^/ :]+)?|/[^/ :]+)'

def win2dos(path):
    p = path
    # /mnt/c/ -> C:/
    p = re.sub(r'^/mnt/([a-zA-Z]+)', r'\1:', p)
    # C:/Users/James -> C:\Users\James
    p = re.sub(r'/', '\\\\', p)
    return p

class ReplacePaths(ShellScript):
    def __init__(self, args, parser):
        super(ReplacePaths, self).__init__(args, parser)

    @staticmethod
    def path_str(path, wsl_windows_path=False):
        path_str = None
        if os.path.exists(path):
            path_str = os.path.realpath(path)
            if dot_util.IS_WSL and wsl_windows_path:
                path_str = win2dos(path_str)
        else:
            path_str = path
        return path_str

    @staticmethod
    def full_path(line, wsl_windows_path=False):
        start_end = []
        for m in re.finditer(r'(?P<path>{path_pattern})'.format(
                path_pattern=PATH_REGEX), line):
            start_end.append((m.start(), m.end()))
        new_line = StringIO()
        last_end = 0
        for (start, end) in start_end:
            # Write anything before the match, but after the last match
            new_line.write(line[last_end:start])
            path = line[start:end]
            new_path = ReplacePaths.path_str(path, wsl_windows_path)
            new_line.write(new_path)
            last_end = end
        # Write anything after the last match
        new_line.write(line[last_end:])
        return new_line.getvalue()

    @staticmethod
    def replace_paths(f, out, local, remote, error_pattern=ERROR_PATTERN_DEFAULT,
                      full_path=True, debug=False, wsl_windows_path=False):
        # for line in f:
        #     line = line.rstrip()
        while True:
            line = f.readline()
            if line == '':
                break
            line = line.rstrip()

            new_line = line.replace(remote, local)
            if full_path:
                new_line = ReplacePaths.full_path(new_line, wsl_windows_path)

            if error_pattern is not None and re.search(error_pattern, new_line, re.IGNORECASE):
                if debug:
                    sys.stderr.write("ERROR LINE:\n")
                sys.stderr.write(new_line)
                sys.stderr.write("\n")
                sys.stderr.flush()
            else:
                out.write(new_line)
                out.write("\n")
                out.flush()

    def run(self):
        args = self.args
        parser = self.parser
        # NOTE:
        # For line in ... buffers lines.
        # You need to use readine
        #
        # while True:
        #     line = sys.stdin.readline()
        #     if not line:
        #         break
        #     sys.stdout.write(line)
        #
        # for line in iter(sys.stdin, ''):
        #     sys.stdout.write(line)
        with ShellScript.as_input_stream(args.file) as f, \
             ShellScript.as_output_stream(args.out) as out:
            ReplacePaths.replace_paths(f, out, args.local, args.remote,
                                       debug=args.debug,
                                       wsl_windows_path=args.wsl_windows_path)


def main():
    parser = argparse.ArgumentParser("Replace paths in text")
    parser.add_argument('--file', default='-',
                        help="file (default = stdin)")
    parser.add_argument('--out', default='-',
                        help="output (default = stdout)")
    parser.add_argument('--local', required=True,
                        help="local path (replacement)")
    parser.add_argument('--remote', required=True,
                        help="remote path (pattern to replace)")
    parser.add_argument('--error-pattern', default=ERROR_PATTERN_DEFAULT,
                        help="if line contains --error-pattern (case insensitive), " \
                             "output to stderr not stdout")
    parser.add_argument('--full-path', action='store_true',
                        help="replace with full path, if it exists locally")
    parser.add_argument('--wsl-windows-path', action='store_true',
                        help=r"if using windows subsystem on linux (WSL), "
                             r"output paths like C:\Users\James\...")
    parser.add_argument('--debug', action='store_true',
                        help="debug")
    args = parser.parse_args()

    if args.debug:
        pprint.pprint(args)

    replace_paths = ReplacePaths(args, parser)
    replace_paths.run()

if __name__ == "__main__":
    main()
