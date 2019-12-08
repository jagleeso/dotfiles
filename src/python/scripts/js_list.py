#!/usr/bin/env python
import json
import sys

def main():
    """Convert argument string to json list string."""
    sys.stdout.write(json.dumps(sys.argv[1:]))

if __name__ == '__main__':
    main()

