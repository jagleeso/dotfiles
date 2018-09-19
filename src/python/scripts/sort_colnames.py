#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import re
import sys
import csv
from os.path import join as _j, exists as _e, basename as _b, dirname as _d, abspath as _a

import dot_util

class SortColnames(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def check_args(self):
        parser = self.parser
        args = self.args

        if args.file is not None and args.file != '-' and not _e(args.file):
            parser.error("--file={file} doesn't exist".format(
                file=args.file))

    def main(self):
        args = self.args
        parser = self.parser

        if args.file is None or args.file == '-':
            inp = sys.stdin
        else:
            inp = open(args.file)

        reader = csv.reader(inp, delimiter=args.delim)
        rows = list(reader)
        num_rows = len(rows[0])
        if len(rows) == 0:
            return
        num_cols = len(rows[0])
        def get_column(rows, col_idx):
            return [rows[row_idx][col_idx] for row_idx in range(len(rows))]
        cols = [get_column(rows, col_idx) for col_idx in range(num_cols)]

        def header_name(column):
            return column[0]
        cols.sort(key=header_name)

        def get_row(cols, row_idx):
            return [cols[col_idx][row_idx] for col_idx in range(len(cols))]

        for i in range(num_rows):
            row = get_row(cols, i)
            print(args.delim.join(row))

def main():
    parser = argparse.ArgumentParser("Reorder csv file by column (alphabetically)")
    parser.add_argument("--file")
    parser.add_argument("--delim", "-d", help="delimiter", default=",")
    args = parser.parse_args()

    sort_colnames = SortColnames(args, parser)
    sort_colnames.check_args()
    sort_colnames.main()

if __name__ == "__main__":
    main()
