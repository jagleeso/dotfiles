#!/usr/bin/env python
import sys
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--start-byte", type=int, default=0)
    parser.add_argument("--count", type=int)
    parser.add_argument("--file", required=True)
    args = parser.parse_args()

    f = open(args.file, 'rb')
    f.seek(0, 2)
    size = f.tell()
    f.seek(0)

    if args.count is None:
        args.count = size

    if args.start_byte + args.count > size:
        parser.error("Size is only {0} bytes long".format(size))

    f.seek(args.start_byte)
    for i in range(args.count):
        c = f.read(1)
        if not c:
            break
        sys.stdout.write(c)

if __name__ == '__main__':
    main()
