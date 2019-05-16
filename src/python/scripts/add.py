#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

import argparse
import os
import shutil
import re
import pprint
import sys
import numpy as np

import dot_util
import textwrap

class Add(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser

    def _init_input(self):
        args = self.args

        if args.file is not None:
            self.inp = open(args.file, 'r')
        else:
            self.inp = sys.stdin

    def empty_line(self, line):
        return re.search(r'^\s*$', line)

    def main(self):
        args = self.args
        parser = self.parser

        self._init_input()

        lines = [line.rstrip() for line in self.inp if not self.empty_line(line)]

        if self.args.skip_header:
            sample_text = lines[1]
        else:
            sample_text = lines[0]
        self.AddendType = get_addend_type(sample_text)
        if self.AddendType is None:
            print("ERROR: Failed to guess addend type from sample text: \"{t}\"".format(t=sample_text))
            sys.exit(1)
        self.AddendObj = self.AddendType()

        def maybe_skip(xs):
            if self.args.skip_header:
                return xs[1:]
            return xs

        # the_sum = 0.
        values = []
        for i, line in enumerate(maybe_skip(lines)):
            value = self.AddendObj.value(line)
            values.append(value)
            # the_sum += value

        self.output("Sum", np.sum(values))
        self.output("Avg", np.mean(values))
        self.output("Std", np.std(values))
        self.output("Min", np.min(values))
        self.output("Max", np.max(values))

    def output(self, name, value):
        print("> {name} = {value}".format(name=name, value=self.AddendObj.pretty(value)))

class Addend(object):
    def __init__(self, regex):
        self.regex = regex

    def add(self, text_01, text_02):
        value_01 = self.value(text_01)
        value_02 = self.value(text_02)
        return value_01 + value_02

    def is_addend(self, text):
        m = re.search(self.regex, text)
        if m:
            return True
        return False

    def value(self, text):
        assert self.is_addend(text)
        m = re.search(self.regex, text)
        return float(m.group('value'))

    def pretty(self, value):
        return str(value)

class NumberAddend(Addend):
    def __init__(self):
        regex = r'(?P<value>{float})'.format(float=dot_util.FLOAT_RE)
        super(NumberAddend, self).__init__(regex)

class PercentAddend(Addend):
    def __init__(self):
        regex = r'(?P<value>{float})\s*%'.format(
                float=dot_util.FLOAT_RE)
        super(PercentAddend, self).__init__(regex)

    def pretty(self, value):
        return "{v}%".format(v=value)

TIME_UNITS = {
    'sec':['seconds', 'sec'],
    'ms':['milliseconds', 'msec', 'ms'],
    'us':['microseconds', 'usec', 'us'],
    'ns':['nanoseconds', 'nsec', 'ns'],
}
def _mk_or_re(choices):
    return "(?:{regex})".format(regex='|'.join(choices))
TIME_UNIT_REGEXES = dict((unit, _mk_or_re(TIME_UNITS[unit])) for unit in TIME_UNITS.keys())
TIME_UNIT_RE = _mk_or_re(dot_util.flatten(TIME_UNITS.values()))
BASE_TIME_UNIT = 'sec'
class TimeAddend(Addend):
    def __init__(self):
        regex = self._time_regex(TIME_UNIT_RE)
        super(TimeAddend, self).__init__(regex)

    def _time_regex(self, unit_re):
        regex = r'(?P<time_as_unit>{float})\s*(?P<unit>{unit})'.format(
            float=dot_util.FLOAT_RE, unit=unit_re)
        return regex

    def value(self, text):
        assert self.is_addend(text)

        time_as_unit = None
        for unit, unit_re in TIME_UNIT_REGEXES.items():
            regex = self._time_regex(unit_re)
            m = re.search(regex, text)
            if m:
                time_as_unit = float(m.group('time_as_unit'))
                break
        assert time_as_unit is not None

        value = to_sec(time_as_unit, unit)

        return value

    def pretty(self, value):
        return pretty_time(value)

SEC_IN_SEC = 1.
MS_IN_SEC = 1e3
US_IN_SEC = 1e6
NS_IN_SEC = 1e9

UNIT_NAMES = ['sec', 'ms', 'us', 'ns']
UNIT_IN_SEC = [SEC_IN_SEC, MS_IN_SEC, US_IN_SEC, NS_IN_SEC]

def to_sec(time_as_unit, unit):
    for i, (time_unit, sec_as_unit) in enumerate(zip(UNIT_NAMES, UNIT_IN_SEC)):
        if time_unit == unit:
            return time_as_unit / sec_as_unit
    assert False

def pretty_time(time_sec, use_space=False):
    def format_str(time_as_unit, unit):
        if use_space:
            return "{time} {unit}".format(time=time_as_unit, unit=unit)
        return "{time}{unit}".format(time=time_as_unit, unit=unit)

    if time_sec == 0 or time_sec > 1:
        return format_str(time_sec, 'sec')
    for i, (time_unit, sec_as_unit) in enumerate(zip(UNIT_NAMES, UNIT_IN_SEC)):
        time_as_unit = time_sec*sec_as_unit
        if time_as_unit > 1 or i == len(UNIT_NAMES) - 1:
            return format_str(time_as_unit, time_unit)
    assert False

ADDEND_TYPES = [
    PercentAddend,
    TimeAddend,
    NumberAddend,
]
def get_addend_type(text):
    for AddendType in ADDEND_TYPES:
        AddendInstance = AddendType()
        if AddendInstance.is_addend(text):
            return AddendType
    return None
    # assert False

def main():
    parser = argparse.ArgumentParser(textwrap.dedent("""
    Add together human-readable data.
    """))
    parser.add_argument('--file',
                        help="file input (default stdin)")
    parser.add_argument('--debug', action='store_true',
            help="debug")
    # parser.add_argument('--stat', action='store_true',
    #                     help="debug")
    parser.add_argument('--skip-header', action='store_true',
                        help="Skip first line")
    # parser.add_argument('--match',
    #                     help="Using matching group $1 as the addend")
    args = parser.parse_args()

    add = Add(args, parser)
    add.main()

if __name__ == "__main__":
    main()
