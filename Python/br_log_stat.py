#!/usr/bin/env python
# -*- encoding: utf-8 -*-
import json
import re
import sys

class MODE:
    stat = 0
    data = 1
    result = 2
    noout = 3

mode = MODE.stat

if len(sys.argv) == 1:
    ins = sys.stdin
else:
    filename = sys.argv[1]
    if filename in ['-d', '--data']:
        mode = MODE.data
        ins = open(sys.argv[2]) if len(sys.argv) > 2 else sys.stdin
    elif filename in ['-r', '--result']:
        mode = MODE.result
        ins = open(sys.argv[2]) if len(sys.argv) > 2 else sys.stdin
    elif filename in ['-n', '--noout']:
        mode = MODE.noout
        ins = open(sys.argv[2]) if len(sys.argv) > 2 else sys.stdin
    else:
        ins = open(filename)

stat = {
    'succeed': 0,
    'failed': 0,
    'xy_slide': {
        'succeed': 0,
        'failed': 0,
    },
    'x_slide': {
        'succeed': 0,
        'failed': 0,
    },
    'result': {
        'score51': 0,
        'error': 0,
        'banip': 0,
        'other': 0,
    }
}


def slog(message):
    sys.stdout.write('\r' + message)
    sys.stdout.flush()

def calculate(data):
    try:
        data['rate'] = data['succeed'] * 100.0 / (data['succeed'] + data['failed'])
        data['rate'] = str(int(round(data['rate']))) + '%'
    except:
        data['rate'] = '--%'

while 1:
    line = ins.readline()
    if not line:
        break

    m = re.search('BR_DEBUG[^{]*({.*})', line)
    if not m:
        continue

    data = json.loads(m.group(1))
    if 'success' not in data:
        continue

    if data['success']:
        stat['succeed'] += 1
        if data['xy_slide']:
            stat['xy_slide']['succeed'] += 1
        else:
            stat['x_slide']['succeed'] += 1

    else:
        stat['failed'] += 1
        if data['xy_slide']:
            stat['xy_slide']['failed'] += 1
        else:
            stat['x_slide']['failed'] += 1

        if mode == MODE.data:
            print(repr(data['val_data']))
        elif mode == MODE.result:
            print(data['result'])

        if data['result'] == '{"score":51,"success":false}':
            stat['result']['score51'] += 1;
        elif data['result'] == '{"error":"error","success":false}':
            stat['result']['error'] += 1
        elif re.search('Oops! your page is missing!!!', data['result']):
            stat['result']['banip'] += 1
        else:
            stat['result']['others'] += 1

    if 'filename' not in dir() and mode == MODE.stat:
        calculate(stat)
        calculate(stat['xy_slide'])
        calculate(stat['x_slide'])
        slog('success rate: {}    xy_success: {}    x_success: {}    count: {} '
            .format(stat['rate'], stat['xy_slide']['rate'],
            stat['x_slide']['rate'], stat['succeed'] + stat['failed']))


if mode == MODE.stat:
    if 'filename' not in dir():
        slog('                                                               '
            + '                                                               ')
        slog('')
    calculate(stat)
    calculate(stat['xy_slide'])
    calculate(stat['x_slide'])
    print(json.dumps(stat, indent=4, sort_keys=True))
