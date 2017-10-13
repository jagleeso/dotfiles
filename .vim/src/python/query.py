#!/usr/bin/env python
import urllib

def imfeelinglucky(query):
    # btnI=1 query parameter triggers i'm feeling lucky
    return 'http://www.google.com/search?q=' + urllib.quote_plus(query) + '&btnI=1'

def hoogle(query):
    """
    Query haskell's Hoogle.
    """
    return 'http://www.haskell.org/hoogle/?hoogle=' + urllib.quote_plus(query)

_filetype_to_query_fn = {
        'haskell': hoogle,
        }
def with_filetype(filetype, query):
    """
    Based on the filetype, return a url that searches our query (or just 
    default to google).
    """
    query_fn = _filetype_to_query_fn.get(filetype, imfeelinglucky)
    return query_fn(query)
