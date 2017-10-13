#!/usr/bin/env python
import cProfile
import pstats
import StringIO
import argparse
import sys

def main():
    parser = argparse.ArgumentParser("pstats")
    parser.add_argument('prof')
    args = parser.parse_args()

    stats = pstats.Stats(args.prof, stream=sys.stdout)
    stats.print_stats()
    
if __name__ == '__main__':
    main()
