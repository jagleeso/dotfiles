#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

from os.path import dirname as _d, basename as _b, exists as _e
import argparse
import os
import shutil
import re
import pprint
from glob import glob
import pprint

class Bkup(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def new_bkup_file(self, path):
        bkup_files = self._bkup_files(_d(path))
        # import ipdb; ipdb.set_trace()
        if len(bkup_files) == 0:
            return "{path}.bkup".format(**locals())
        new_id = max(self.bkup_file_idx(p) for p in bkup_files) + 1
        return "{path}.{new_id}.bkup".format(**locals())

    def bkup_file_idx(self, bkup_file):
        assert self.is_bkup_file(bkup_file)
        m = re.search(r'\.(?P<id>\d+)\.bkup$', bkup_file)
        if not m:
            return 0
        return int(m.group('id'))

    def _bkup_files(self, root):
        bkup_files = [p for p in glob('{root}/*'.format(root=root)) \
                if self.is_bkup_file(p)]
        return bkup_files

    def guess_bkup_file(self, root):
        bkup_files = self._bkup_files(root)
        if len(bkup_files) > 1:
            ss = StringIO()
            for bkup_file in bkup_files:
                ss.write("  {bkup_file}\n".format(bkup_file=bkup_file))
            self.error("Couldn't guess bkup file; choices:\n{choices}".format(choices=ss.getvalue()))
        return bkup_files[0]

    def error(self, msg):
        print("ERROR: {msg}".format(msg=msg))
        sys.exit(1)

    def recov_file(self, path):
        return re.sub(r'(?:\.\d+)\.bkup$', '', path)

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
            print("{src} doesn't exist; skip.".format(**locals()))
            return False
        if not self.args.clobber and os.path.exists(dst):
            print("{dst} already exists; skip (use -f).".format(**locals()))
            return False
        return True

    def recover(self, path):
        if not self.is_bkup_file(path):
            path = self.guess_bkup_file(_d(path))
        assert self.is_bkup_file(path)
        new_path = self.recov_file(path)
        if not self.check_paths(path, new_path):
            return False
        self.move_file(path, new_path)

    @property
    def debug(self):
        return self.args.debug

    @property
    def verbose(self):
        return self.args.verbose

    def move_file(self, old_path, new_path):
        if self.args.copy:
            if self.debug or self.verbose:
                print("Copy: {old_path} -> {new_path}".format(**locals()))
            if not self.debug:
                shutil.copy(old_path, new_path)
            return
        if self.debug or self.verbose:
            print("Move: {old_path} -> {new_path}".format(**locals()))
        if not self.debug:
            shutil.move(old_path, new_path)

    def bkup(self, path):
        new_path = self.new_bkup_file(path)
        assert not _e(new_path)
        if not self.check_paths(path, new_path):
            return False
        self.move_file(path, new_path)

def main():
    parser = argparse.ArgumentParser("file.ext -> file.ext.bkup")
    parser.add_argument('files', nargs='*')
    parser.add_argument('--debug', action='store_true',
            help="debug")
    parser.add_argument('--verbose', action='store_true',
            help="verbose")
    parser.add_argument('-c', '--copy', action='store_true',
            help="instead of moving the file, copy it")
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
