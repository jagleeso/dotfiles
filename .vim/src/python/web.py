#!/usr/bin/env python
import os, commands
import platform

operating_system = None
if platform.mac_ver() != ('', ('', '', ''), ''):
    operating_system = 'Mac'
else:
    operating_system = platform.system()

_gui_open_cmd = None
if operating_system == 'Mac':
    _gui_open_cmd = 'open'
elif operating_system == 'Linux':
    _gui_open_cmd = 'gnome-open'
else:
    raise RuntimeError("Not sure how to open urls on {platform}".format(platform=operating_system))
def browse_gui(url):
    os.system(_gui_open_cmd + ' ' + commands.mkarg(url))

def browse_terminal(url):
    os.system('w3m ' + commands.mkarg(url))

def browse(url):
    browse_terminal(url)
