#!/usr/bin/env python
import os, commands

def browse(url):
    os.system('w3m ' + commands.mkarg(url))
