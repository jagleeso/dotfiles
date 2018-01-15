#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import os
import shutil
import re
import pprint
from os.path import join as _j, abspath as _P, dirname as _d, realpath as _r, basename as _b

import dot_util
import time


class GDB(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def main(self):
        args = self.args
        parser = self.parser

        gdbserver_cmd = [args.gdbserver, "localhost:{port}".format(port=args.port)] + args.cmd
        cmdline = dot_util.sanitize_cmdline(gdbserver_cmd)

        while True:
            out, ret = dot_util.run_cmd(cmdline,
                                        errcode=True,
                                        to_stdout=True,
                                        tee_file=args.out)
            if ret != 0:
                dot_util.log("gdbserver stopped; restarting")
                time.sleep(0.5)

def main():
    parser = argparse.ArgumentParser("file.ext -> file.ext.bkup")
    parser.add_argument('cmd', nargs='*')
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('-p', '--port', type=int,
                        default=1234)
    parser.add_argument('--gdbserver', default="gdbserver")
    parser.add_argument('--out', help="log output")
    args = parser.parse_args()

    if args.out is None:
        args.out = 'gdb.txt'

    if dot_util.which(args.gdbserver) is None:
        parser.error("Couldn't find --gdbserver = {gdbserver}".format(
            gdbserver=args.gdbserver))

    if args.out:
        print('Logging output to: {path}'.format(
            path=_P(args.out)))

    gdb = GDB(args, parser)
    gdb.main()

if __name__ == "__main__":
    main()
