#!/usr/bin/python
import urllib.parse
import sys

for line in sys.stdin:
    sys.stdout.write(urllib.parse.unquote(line))
