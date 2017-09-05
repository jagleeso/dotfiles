#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import os
import shutil
import re
import pprint

class Bkup(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def bkup_file(self, path):
        return "{path}.bkup".format(**locals())

    def recov_file(self, path):
        return re.sub(r'\.bkup$', '', path)

    def is_bkup_file(self, path):
        return re.search(r'\.bkup$', path)

    def main(self):
        args = self.args
        parser = self.parser

        for path in args.files:
            if args.recover:
                self.recover(path)
            else:
                self.bkup(path)

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
        shutil.move(path, new_path)

    def bkup(self, path):
        new_path = self.bkup_file(path)
        if not self.check_paths(path, new_path):
            return False
        shutil.move(path, new_path)

def main():
    parser = argparse.ArgumentParser("file.ext -> file.ext.bkup")
    parser.add_argument('files', nargs='*')
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('-f', '--clobber', action='store_true',
            help="overwrite <file>.bkup if it already exists")
    parser.add_argument('-r', '--recover', action='store_true',
            help="file.ext.bkup -> file.ext")
    args = parser.parse_args()

    if args.debug:
        pprint.pprint(args)

    bkup = Bkup(args, parser)
    bkup.main()

if __name__ == "__main__":
    main()
