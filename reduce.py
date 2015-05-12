#!/usr/bin/env python

import fileinput

kv = dict()

for line in fileinput.input():
    key = line.split('\t')[0]
    val = int(line.split('\t')[1])
    if key not in kv.keys():
        kv[key] = val
    else:
        kv[key] = kv[key] + val

for key in sorted(kv.keys()):
    print(key + '\t' + str(kv[key]))
