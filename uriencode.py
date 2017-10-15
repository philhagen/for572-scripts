#!/usr/bin/python
import urllib
import sys

for line in sys.stdin:
	sys.stdout.write(urllib.quote(line))
