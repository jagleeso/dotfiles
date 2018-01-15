#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import subprocess
import sys
import types
from os.path import expandvars as _e
from os.path import join as _j, abspath as _P, dirname as _d, realpath as _r
from glob import glob

import dot_config
import dot_util

#
# Configuration
#

ROOT = _d(_d(_d(_r(__file__))))
if not os.path.exists(ROOT):
    print ("ERROR: ROOT ({ROOT}) doesn't exist".format(ROOT=ROOT))
    sys.exit(1)

# Time to wait to connect to various things.
MAX_TIME_SEC = 60

COMMON_SH = _j(ROOT, "src/sh/common.sh")
EXPORTS_SH = _j(ROOT, "src/sh/exports.sh")

#
# End of configuration
#

def config_vars():
    ignore = set([
    '__builtins__',
    '__doc__',
    '__file__',
    '__name__',
    '__package__',
    '_prev_dir',
    ])
    for attr in dir(dot_config):
        if type(globals()[attr]) not in [types.ModuleType, types.FunctionType] and attr not in ignore:
            yield attr

def main():
    parser = argparse.ArgumentParser("description")
    parser.add_argument("--get-config")
    args = parser.parse_args()

    if args.get_config is not None:
        if not hasattr(dot_config, args.get_config):
            sys.stderr.write("Unknown config variable; try these:\n")
            for attr in config_vars():
                print ("  {attr}".format(**locals()))
            parser.print_usage()
            sys.exit(1)
        var = getattr(dot_config, args.get_config)
        print (var)
        return

    parser.error("Give a command")
    
if __name__ == '__main__':
    main()
