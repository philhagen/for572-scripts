#!/usr/bin/python

import fileinput

def generate_domain(year, month, day):
    """Generates a domain by the current date"""
    domain = ""
    for i in range(16):
        year = ((year ^ 8 * year) >> 11) ^ ((year & 0xFFFFFFF0) << 17)
        month = ((month ^ 4 * month) >> 25) ^ 16 * (month & 0xFFFFFFF8)
        day = ((day ^ (day << 13)) >> 19) ^ ((day & 0xFFFFFFFE) << 12)
        domain += chr(((year ^ month ^ day) % 25) + 97)
    return domain

for line in fileinput.input():
    (y, m, d) = line.split('-')
    print generate_domain(int(y), int(m), int(d))
