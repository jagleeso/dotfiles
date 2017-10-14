#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import shutil
import re
import pprint

import dot_util
from dot_util import ShellScript

class Replace(ShellScript):
    def __init__(self, args, parser):
        super(Replace, self).__init__(args, parser)

    def run(self):
        args = self.args
        parser = self.parser
        with ShellScript.as_input_stream(args.file) as f, \
             ShellScript.as_output_stream(args.out) as out:
            for line in f:
                line = line.rstrip()
                new_line = re.sub(args.pattern, args.replacement, line)
                out.write(new_line)
                out.write("\n")

def main():
    parser = argparse.ArgumentParser("Replace text")
    parser.add_argument('--file', default='-',
            help="file (default = stdin)")
    parser.add_argument('--out', default='-',
                        help="output (default = stdout)")
    parser.add_argument('-r', '--replacement',
                        help="replacement string")
    parser.add_argument('-p', '--pattern',
                        help="pattern to replace")
    parser.add_argument('--debug', action='store_true',
                        help="debug")
    args = parser.parse_args()

    if args.debug:
        pprint.pprint(args)

    replace = Replace(args, parser)
    replace.run()

if __name__ == "__main__":
    main()
