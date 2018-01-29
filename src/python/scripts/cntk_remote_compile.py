#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import sys
import os
import shutil
import re
import pprint
from os.path import join as _j, abspath as _P, dirname as _d, realpath as _r, basename as _b

import dot_util
import time

class CNTKRemoteCompile(object):
    def __init__(self, args, parser, extra_args):
        self.args = args
        self.parser = parser
        self.extra_args = extra_args

    def main(self):
        args = self.args
        parser = self.parser
        extra_args = self.extra_args

        out, ret = dot_util.sh_script(["do_cntk_remote_compile", args.node] + extra_args,
                                      errcode=True,
                                      debug=args.debug,
                                      add_env={
                                          'RESTART_GDB':dot_util.yes_or_no(args.restart is not None),
                                          'RESTART_GDB_SH_SCRIPT':'' if args.restart is None else args.restart,
                                          'REMOTE_CNTK_HOME':args.remote_cntk_home,
                                          'LOCAL_CNTK_HOME':args.local_cntk_home,
                                      })
        return ret

def main():
    exports = dot_util.Exports()
    parser = argparse.ArgumentParser("compile cntk on remote machine")
    parser.add_argument('cmd', nargs='*')
    parser.add_argument('--restart',
                        choices=['gdb_cntk', 'gdb_cntk_unittest', 'gdb_cntk_unittest_local'],
                        help="restart remote emacs debugger.")
    parser.add_argument('--debug', action='store_true',
                        help="debug")
    parser.add_argument('--node',
                        help="remote node",
                        choices=exports.nodes,
                        default=exports.vars['REMOTE_LOGAN_NODE'])
    parser.add_argument('--remote-cntk-home',
                        help="remote CNTK directory",
                        required=True)
    parser.add_argument('--local-cntk-home',
                        help="local CNTK directory",
                        required=True)
    args, extra_args = parser.parse_known_args()

    scr = CNTKRemoteCompile(args, parser, extra_args)
    ret = scr.main()
    sys.exit(ret)

if __name__ == "__main__":
    main()
