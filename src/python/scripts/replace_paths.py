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
PATH_CHAR_REGEX = r"[^/ ':]"
PATH_REGEX = r"(?:/?(?:{PC}+/)+(?:{PC}+)?|/{PC}+)".format(
    PC=PATH_CHAR_REGEX)

def win2dos(path):
    p = path
    # /mnt/c/ -> C:/
    p = re.sub(r'^/mnt/([a-zA-Z]+)', r'\1:', p)
    # C:/Users/James -> C:\Users\James
    p = re.sub(r'/', '\\\\', p)
    return p

# Keep track of directories from which make is called so we
# can figure out absolute file paths from compiler errors that use relative paths.
#
# make[1]: Entering directory '/home/james/clone/some/junk'
MAKE_DIR_REGEX = r'make\[\d+\]: Entering directory .*?(?P<make_dir>{PATH_REGEX})'.format(
    PATH_REGEX=PATH_REGEX)

class ReplacePaths(ShellScript):
    def __init__(self, args, parser):
        super(ReplacePaths, self).__init__(args, parser)

    @staticmethod
    def path_str(path, wsl_windows_path=False, make_dirs=[], debug=False):
        def _path_str(path):
            path_str = None
            if os.path.exists(path):
                path_str = os.path.realpath(path)
                if wsl_windows_path:
                    path_str = win2dos(path_str)
            return path_str


        new_path = _path_str(path)
        if new_path is not None:
            if debug:
                pprint.pprint({'#':1, 'new_path':new_path})
            return new_path
        # Append make_dir to the relative path.
        # If it exists.
        for make_dir in make_dirs:
            make_rel_path = os.path.join(make_dir, path)
            new_path = _path_str(make_rel_path)
            if new_path is not None:
                if debug:
                    pprint.pprint({'#':2, 'new_path':new_path})
                return new_path
        if debug:
            pprint.pprint({'#':3, 'path':path})
        return path


    @staticmethod
    def full_path(line, wsl_windows_path=False, make_dirs=[]):
        debug = False
        start_end = []
        # if re.search(r'src/core/symbolic.cc:35:65: error: ‘node’ was not declared in this scope', line):
        #     pprint.pprint({'line':line, 'make_dirs':make_dirs})
        n_matches = 0
        for m in re.finditer(r'(?P<path>{path_pattern})'.format(
                path_pattern=PATH_REGEX), line):
            start_end.append((m.start(), m.end()))
            n_matches += 1
        # if re.search(r'src/core/symbolic.cc:35:65: error: ‘node’ was not declared in this scope', line):
        #     print("  n_matches={n_matches}".format(**locals()))
        new_line = StringIO()
        last_end = 0
        for (start, end) in start_end:
            # Write anything before the match, but after the last match
            new_line.write(line[last_end:start])
            path = line[start:end]
            new_path = ReplacePaths.path_str(path, wsl_windows_path, make_dirs, debug=debug)
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
        make_dirs = []
        # pprint.pprint(locals())
        while True:
            line = f.readline()
            if line == '':
                break
            line = line.rstrip()

            # if re.search(r'^make', line):
            #     pprint.pprint({'line':line, 'MAKE_DIR_REGEX':MAKE_DIR_REGEX})
            m = re.search(MAKE_DIR_REGEX, line)
            if m:
                make_dirs.append(m.group('make_dir'))
                pprint.pprint({'make_dirs':make_dirs})

            new_line = line.replace(remote, local)
            if full_path:
                # if re.search(r'src/core/symbolic.cc:35:65: error: ‘node’ was not declared in this scope', line):
                #     import ipdb; ipdb.set_trace()
                new_line = ReplacePaths.full_path(new_line, wsl_windows_path, make_dirs)

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
                                       wsl_windows_path=dot_util.IS_WSL)


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
    # parser.add_argument('--wsl-windows-path', action='store_true',
    #                     help=r"if using windows subsystem on linux (WSL), "
    #                          r"output paths like C:\Users\James\...")
    parser.add_argument('--debug', action='store_true',
                        help="debug")
    args = parser.parse_args()

    if args.debug:
        pprint.pprint(args)

    replace_paths = ReplacePaths(args, parser)
    replace_paths.run()

if __name__ == "__main__":
    main()
