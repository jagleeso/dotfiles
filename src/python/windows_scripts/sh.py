#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import pprint

import subprocess

import sys

import os

try:
    from shlex import quote as quote_shell
except ImportError:
    from pipes import quote as quote_shell

class Sh(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    @staticmethod
    def quote_cmd(arguments):
        return [quote_shell(x) for x in arguments]

    @staticmethod
    def quote_cmd_as_str(arguments):
        return ' '.join(Sh.quote_cmd(arguments))

    @staticmethod
    def pythonpath():
        return os.path.join(os.path.expanduser('~'), 'clone', 'src', 'python')

    @staticmethod
    def suggest_setup():
        """
        Make sure things have been manually setup properly on Windows.
        """
        pythonpath = Sh.pythonpath()
        print("Failed to import things. To fix:")
        print("  (1) PYTHONPATH={pythonpath}".format(**locals()))

    def main(self):
        args = self.args
        parser = self.parser

        cmd = ["bash", "-c",
               Sh.quote_cmd_as_str(["WINDOWS_SCRIPT=yes", "zsh", "-i", "-c", Sh.quote_cmd_as_str(args.arguments)])]

        if self._dry_run:
            return

        try:
            dot_util.run_cmd(cmd,
                             stdout=sys.stdout,
                             stderr=sys.stderr,
                             silent=not self._debug)
        except subprocess.CalledProcessError as e:
            sys.exit(e.returncode)

    @property
    def _debug(self):
        return self._getopt('sh_debug', False)

    def _getopt(self, attr, default=None):
        return self.args.__dict__.get(attr, default)

    @property
    def _dry_run(self):
        return self._getopt('sh_dry_run', False)

    def _log(self, msg):
        if self._debug:
            print(msg)

try:
    import dot_util
except ImportError as e:
    Sh.suggest_setup()
    raise e

def main():
    parser = argparse.ArgumentParser(
        "Run a WSL command from the zsh shell.\n"
        "To run linux commands directly from windows you need to:\n"
        "(1) Add PYTHONPATH=C:\\Users\\<user>\\clone\\src\\python\\script\n"
        "(2) $ python -m windows_scripts.sh echo hi\n"
        "",
        add_help=False)
    parser.add_argument('arguments', nargs='*')
    parser.add_argument('--sh-dry-run', action='store_true',
                        help="dry run")
    parser.add_argument('--sh-help', action='store_true',
                        help="help with this script")
    parser.add_argument('--sh-debug', action='store_true',
                        help="debug this script")
    args = parser.parse_args()

    if args.sh_help:
        parser.print_usage()
        sys.exit(0)

    sh = Sh(args, parser)
    sh.main()

if __name__ == "__main__":
    main()
