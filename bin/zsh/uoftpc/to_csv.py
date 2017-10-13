#!/usr/bin/env python

import re
import argparse
import csv
import itertools
import sys

def main():
    parser = argparse.ArgumentParser(description="convert to csv")
    parser.add_argument('files', nargs='+')
    parser.add_argument('--field', nargs='+', required=True,
            help="'bytes_per_second' 'bytes_per_second = (.*)'")
    parser.add_argument('--start')
    args = parser.parse_args()

    if len(args.field) % 2 != 0:
        parser.error("--field is pairs of two (field name and pattern with 1 group)")

    fpats = {}
    field_order = []
    for field, pattern in grouper(args.field, 2):
        if pattern == 'default':
            fpats[field] = r'{field} = (.*)'.format(**locals())
        else:
            fpats[field] = pattern
        field_order.append(field)

    def open_file(file):
        if file == "-":
            return sys.stdin
        else:
            return open(file, 'r')
    def close_file(file):
        if file == sys.stdin:
            pass
        else:
            file.close()
    def lines(file):
        for line in file:
            yield line.rstrip()

    files = None
    if args.files == []:
        files = [sys.stdin]
    else:
        files = [open_file(f) for f in args.files]

    first = [True]
    writer = csv.writer(sys.stdout)
    def output(d):
        if first[0]:
            writer.writerow(field_order)
            first[0] = False
        writer.writerow([d[f] for f in field_order])

    d = {}
    for f in files:
        for l in lines(f):
            for field in fpats.keys():
                m = re.search(fpats[field], l)
                if m:
                    if field in d:
                        # Already saw this field, next record starting.
                        output(d)
                        d = {}
                    d[field] = m.group(1)
                    break
            if args.start and re.search(args.start, l):
                output(d)
                d = {}
        if d != {}:
            output(d)
            d = {}

    for f in files:
        close_file(f)

# https://docs.python.org/2/library/itertools.html
def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return itertools.izip_longest(fillvalue=fillvalue, *args)

if __name__ == '__main__':
    main()
