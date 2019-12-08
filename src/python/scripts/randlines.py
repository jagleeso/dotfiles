#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import copy
import random
import csv
import os
import shutil
import re
import pprint
import sys
import textwrap

# import numpy as np

import dot_util

class RandLines:
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def main(self):
        """
        Input:
            1
            2
            3
        Output:
            1
            3
            2
        """
        args = self.args
        parser = self.parser

        inp = sys.stdin

        lines = list(self.read_lines(inp))


        if args.insert is None:
            random_lines = self.random_shuffle(lines)
        else:
            with open(args.insert) as f:
                inserts = list(self.read_lines(f))
            random_lines = self.random_inserts(lines, inserts)

        for i, line in enumerate(random_lines):
            print(line)

    def random_shuffle(self, lines):
        random_lines = copy.copy(lines)
        random.shuffle(random_lines)
        return random_lines

    def random_inserts(self, lines, inserts):
        random_lines = copy.copy(lines)
        for insert in inserts:
            i = random.randint(0, len(random_lines))
            random_lines.insert(i, insert)
        return random_lines

    def read_lines(self, it):
        for line in it:
            line = line.rstrip()
            yield line


def main():
    parser = argparse.ArgumentParser("randomize input lines.")
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('--insert', help=textwrap.dedent("""
    File containing lines that we should random insert into standard input.  

    Some notes:
    - original order of standard input is maintained.
    - lines may be inserted as the first line, or the last line. 
    """))
    args = parser.parse_args()

    rand_lines = RandLines(args, parser)
    rand_lines.main()

if __name__ == "__main__":
    main()
