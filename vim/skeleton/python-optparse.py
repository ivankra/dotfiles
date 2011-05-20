#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, optparse

def main():
    parser = optparse.OptionParser()
    parser.add_option('-q', dest='quiet')
    (options, args) = parser.parse_args()
    

if __name__ == '__main__':
    main()
