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

class Round(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def main(self):
        args = self.args
        parser = self.parser

        inp = sys.stdin
        for line in inp:
            line = line.rstrip()
            xs = re.split(r"({0})".format(dot_util.FLOAT_RE), line)
            rounded = [str(self.maybe_round(x)) for x in xs]
            new_line = ''.join(rounded)
            print(new_line)

    def maybe_round(self, x):
        args = self.args

        if not re.match(dot_util.FLOAT_RE, x):
            return x
        num = dot_util.as_number(x)
        if type(num) == int:
            return num
        return np.round(num, args.precision)

def main():
    parser = argparse.ArgumentParser("Round all number in input")
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('--precision', '-p', type=int, default=2,
                        help="number of decimal places to round to")
    args = parser.parse_args()

    round = Round(args, parser)
    round.main()

if __name__ == "__main__":
    main()
