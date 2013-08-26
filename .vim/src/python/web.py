#!/usr/bin/env python
import os, commands

def browse_gui(url):
    os.system('chromium-browser ' + commands.mkarg(url))

def browse_terminal(url):
    os.system('w3m ' + commands.mkarg(url))

def browse(url):
    browse_terminal(url)
