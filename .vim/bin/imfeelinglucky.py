#!/usr/bin/env python
import google, web, sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="search for a query using googles 'I'm feeling lucky'")
    # Interface to view search result in
    interface_options = parser.add_mutually_exclusive_group()
    interface_options.add_argument("--term", action="store_true")
    interface_options.add_argument("--gui", action="store_true")
    parser.add_argument("query", nargs="+")
    args = parser.parse_args()

    url = google.imfeelinglucky(' '.join(args.query))
    if args.term or (not args.term and not args.gui):
        # either they chose terminal, or provided no interface so default to terminal
        web.browse_terminal(url)
    else:
        web.browse_gui(url)

if __name__ == '__main__':
    main()
