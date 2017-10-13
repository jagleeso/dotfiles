#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import csv
import os
import shutil
import re
import pprint
import sys
import textwrap

import numpy as np

import dot_util

class LatexTable(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def main(self):
        """
        e.g.

        \begin
        {table *}[htb]
        \centering
        \caption
        {Features
        tabulated
        with associated weight}
        \label
        {table::feature - weights}
        \begin
        {tabularx}
        {\textwidth}{ | X | X | X | X | X |}
        \hline
        i & $w_i$ & $stdev(x_i)$ & feature & $ | w_i * stdev(x_i) |$ \ \
                \hline
        3 & 0.00569 & 6.9395 & INDUS & 0.03948 \ \
                \hline
        7 & -0.00775 & 28.23746 & AGE & 0.21876 \ \
                \hline
        4 & 2.00735 & 0.24944 & CHAS & 0.50072 \ \
                \hline
        12 & 0.00796 & 93.22492 & B & 0.74246 \ \
                \hline
        1 & -0.096 & 8.52599 & CRIM & 0.81852 \ \
                \hline
        2 & 0.04926 & 24.07696 & ZN & 1.18615 \ \
                \hline
        5 & -17.41674 & 0.11468 & NOX & 1.99734 \ \
                \hline
        10 & -0.01185 & 170.71788 & TAX & 2.0233 \ \
                \hline
        11 & -0.98186 & 2.14113 & PTRATIO & 2.10229 \ \
                \hline
        9 & 0.25973 & 8.80527 & RAD & 2.28695 \ \
                \hline
        6 & 3.5138 & 0.71036 & RM & 2.49605 \ \
                \hline
        8 & -1.53236 & 2.06213 & DIS & 3.15994 \ \
                \hline
        13 & -0.49933 & 7.14908 & LSTAT & 3.56978 \ \
                \hline
        \end
        {tabularx}
        \end

        """
        args = self.args
        parser = self.parser

        inp = sys.stdin

        reader = csv.reader(inp, delimiter=args.delimiter)
        rows = [row for row in reader]

        self.n_rows = len(rows)
        self.n_cols = len(rows[0])

        self.print_header()
        for i, row in enumerate(rows):
            if len(row) != self.n_cols:
                parser.error("ERROR: number of columns varies between rows")
            self.print_line(i, row)
        self.print_footer()

    @staticmethod
    def escape_underscores(string):
        return re.sub(r'_', r'\_', string)

    def pr(self, string):
        out_string = textwrap.dedent(string).lstrip("\n")
        sys.stdout.write(out_string)

    def print_line(self, i, row):
        assert len(row) == self.n_cols
        escaped = [LatexTable.escape_underscores(x) for x in row]
        fields = " & ".join(escaped)
        self.pr(r"""
        \hline
        {fields} \\
        """.format(**locals()))
        if (i + 1) == self.n_rows:
            self.pr(r"""
            \hline
            """)

    def print_header(self):
        colstring = "|{0}|".format("|".join(["X"]*self.n_cols))
        self.pr(r"""
        \begin{table*}[htb]
        \centering
        \caption{Caption}
        \label{table::label}
        """)

        self.pr("""
        \\begin{{tabularx}}{{\\textwidth}}{{{colstring}}}
        """.format(**locals()))

    def print_footer(self):
        self.pr("""
        \end{tabularx}
        \end{table*}
        """)

def main():
    parser = argparse.ArgumentParser("Convert csv to latex table.")
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('--precision', '-p', type=int, default=2,
                        help="number of decimal places to round to")
    parser.add_argument('--delimiter', '-d', default='\t',
                        help="csv delimiter")
    args = parser.parse_args()

    latex_table = LatexTable(args, parser)
    latex_table.main()

if __name__ == "__main__":
    main()
