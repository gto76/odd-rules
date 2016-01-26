#!/usr/bin/python3
#
# Usage: display-graph.py 
# 

import sys
import re

import csv
import matplotlib.pyplot as plt

def main():
  reader = csv.reader(open(sys.argv[1], newline='\n'), delimiter=',', quotechar='"')
  rdr = list(reader)
  column1 = [row[0] for row in rdr]
  column2 = [row[1] for row in rdr]
  plt.plot(column1, column2, 'ro')
  plt.show()

if __name__ == '__main__':
  main()
