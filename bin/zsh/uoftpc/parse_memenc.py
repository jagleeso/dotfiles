#!/usr/bin/env python
import sys
import re

d = {}
for line in sys.stdin:
    line.rstrip()
    m = re.search(r'iterations: (\d+)', line)
    if m:
        d['iterations'] = int(m.group(1))
        continue
    m = re.search(r'repetitions: (\d+)', line)
    if m:
        d['repetitions'] = int(m.group(1))
        continue
    m = re.search(r'time \(ms\): (\d+)', line)
    if m:
        if 'time' not in d:
            d['time'] = []
        d['time'].append(m.group(1))
        continue
    m = re.search(r'bytes_per_iteration: (\d+)', line)
    if m:
        d['bytes_per_iteration'] = int(m.group(1))
        d['time_str'] = '+'.join(d['time'])
        eqn = "({iterations}*{bytes_per_iteration}/1024/1024)/(({time_str})/({repetitions}*1000))".format(**d)
        print eqn
        result = (float(d['iterations'])*d['bytes_per_iteration']/1024.0/1024.0)/((float(eval(d['time_str'])))/(d['repetitions']*1000.0))
        print result
        d = {}
        continue

