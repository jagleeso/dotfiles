#!/usr/bin/env python
import urllib

def imfeelinglucky(query):
    # btnI=1 query parameter triggers i'm feeling lucky
    return 'http://www.google.com/search?q=' + urllib.quote_plus(query) + '&btnI=1'
