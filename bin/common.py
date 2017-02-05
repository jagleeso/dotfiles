#!/usr/bin/env python
# -*- coding: utf-8 -*-
import subprocess
import os

DIR = os.path.dirname(os.path.realpath(__file__))

def sh_run(*args):
    cmd = ["{DIR}/common.sh".format(DIR=DIR)] + list(args)
    env = dict(os.environ)
    env['RUN_COMMON'] = 'yes'
    subprocess.check_call(cmd, env=env)
