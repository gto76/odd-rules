#!/usr/bin/python3
#
# Usage: display-graph.py 
# 

import sys
import re

import csv
import matplotlib.pyplot as plt

def main():
  reader = csv.reader(open('random-rules-dist', newline='\n'), delimiter=',', quotechar='"')
  rdr = list(reader)
  plt.plot(rdr)
  plt.show()

if __name__ == '__main__':
  main()
