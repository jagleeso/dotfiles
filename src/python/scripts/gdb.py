#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import os
import shutil
import re
import pprint

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
            # out, ret = dot_util.run_cmd(cmdline, errcode=True)
            try:
                out = dot_util.run_cmd(cmdline)
            except Exception as e:
                import ipdb; ipdb.set_trace()
                raise e
            # if ret != 0:
            #     dot_util.log("gdbserver stopped; restarting")
            #     time.sleep(0.5)

    def check_paths(self, src, dst):
        if not os.path.exists(src):
            print "{src} doesn't exist; skip.".format(**locals())
            return False
        if not self.args.clobber and os.path.exists(dst):
            print "{dst} already exists; skip (use -f).".format(**locals())
            return False
        return True

    def recover(self, path):
        if not self.is_bkup_file(path):
            path = self.bkup_file(path)
        assert self.is_bkup_file(path)
        new_path = self.recov_file(path)
        if not self.check_paths(path, new_path):
            return False
        self.move_file(path, new_path)

    def move_file(self, old_path, new_path):
        if self.args.copy:
            shutil.copy(old_path, new_path)
        else:
            shutil.move(old_path, new_path)

    def bkup(self, path):
        new_path = self.bkup_file(path)
        if not self.check_paths(path, new_path):
            return False
        self.move_file(path, new_path)

def main():
    parser = argparse.ArgumentParser("file.ext -> file.ext.bkup")
    parser.add_argument('cmd', nargs='*')
    # parser.add_argument('--debug', action='store_true',
    #         help="debug")
    parser.add_argument('-p', '--port', type=int,
                        default=1234)
    parser.add_argument('--gdbserver', default="gdbserver")
    args = parser.parse_args()

    if dot_util.which(args.gdbserver) is None:
        parser.error("Couldn't find --gdbserver = {gdbserver}".format(
            gdbserver=args.gdbserver))

    gdb = GDB(args, parser)
    gdb.main()

if __name__ == "__main__":
    main()
