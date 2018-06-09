#!/usr/bin/env python3

import json
import os
import urllib.request

def find_my_iphone():
    request('https://nickficano.com/api/icloud/fmi', {
        'apple_id': os.environ.get('APPLE_ID'),
        'password': os.environ.get('ICLOUD_PASSWORD'),
    })


def request(url, payload):
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url)
    req.add_header('Content-Type', 'application/json; charset=utf-8')
    urllib.request.urlopen(req, data)

if __name__ == '__main__':
    find_my_iphone()
