#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import shutil
import re
import pprint
import sys
import numpy as np

import dot_util

class Uniq(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def _init_input(self):
        args = self.args

        if args.file is not None:
            self.inp = open(args.file, 'r')
        else:
            self.inp = sys.stdin

    def main(self):
        args = self.args
        parser = self.parser

        '''
        Print all the lines as-as.
        However, for groups of lines that start/end with --start/end-regex, 
        Only print those on their first occurence (remove duplicates).
        '''

        saw_start = False

        self._init_input()

        pat_lines = []
        '''
        seen_pats[tuple(pattern lines)] = {
            'first_line_idx': the start index of the first occurence of this pattern,
            'len': number of lines in the pattern,
        }
        
        seen_pats[i = line index] = {
            'first_line_idx': the start index of the first occurence of this pattern,
            'len': number of lines in the pattern,
        }
        '''
        seen_pats_by_lines = {}
        seen_pats_by_idx = {}

        lines = [line.rstrip() for line in self.inp]

        for i, line in enumerate(lines):

            m = re.search(args.start_regex, line)
            if m:
                if saw_start and not args.allow_restart:
                    parser.error('Line {i}: Saw --start-regex again before --end-regex (use --allow-restart to allow);\n  {line}'.format(
                        i=i + 1,
                        line=line,
                    ))
                saw_start = True

            if saw_start:
                pat_lines.append(line)

                m = re.search(args.end_regex, line)
                if m:
                    pat_lines_ = tuple(pat_lines)
                    if pat_lines_ not in seen_pats_by_lines:
                        seen_pats_by_lines[pat_lines_] = {
                            'first_line_idx':i,
                            'len':len(pat_lines_),
                        }
                    seen_pats_by_idx[i] = seen_pats_by_lines[pat_lines_]
                    saw_start = False
                    pat_lines = []
                    continue

        i = 0
        while i < len(lines):
            if i in seen_pats_by_idx:
                pat = seen_pats_by_idx[i]
                if i == pat['first_line_idx']:
                    for j in range(pat['len']):
                        print(lines[i])
                        i += 1
                elif args.print_removed:
                    print('(duplicate pattern of length {len} removed)'.format(
                        len=pat['len']))
                continue

            print(lines[i])
            i += 1

    def maybe_round(self, x):
        args = self.args

        if not re.match(dot_util.FLOAT_RE, x):
            return x
        num = dot_util.as_number(x)
        if type(num) == int:
            return num
        return np.round(num, args.precision)

def main():
    parser = argparse.ArgumentParser("Return unique occurences of multi-line text blob. "
                                     "--start-regex marks start, --end-regex marks end.")
    parser.add_argument('--file',
                        help="file input (default stdin)")
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('--print-removed', action='store_true',
                        help="print a notice when duplicate lines have been removed.")
    parser.add_argument('--allow-restart', action='store_true',
                        help="Allow two --start-regex's before a single --end-regex; just gobble it into 1 big pattern")
    parser.add_argument('--start-regex',
                        help="Start regex for multi-line blob of text.")
    parser.add_argument('--end-regex',
                        help="End regex for multi-line blob of text.")
    args = parser.parse_args()

    uniq = Uniq(args, parser)
    uniq.main()

if __name__ == "__main__":
    main()
