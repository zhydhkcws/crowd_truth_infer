__author__ = 'JasonLee'
import csv
import numpy as np
import sys

def getmean(e2l):
    e2a = {}
    for example in e2l:
        mean = np.mean(e2l[example])
        e2a[example] = mean

    return e2a

def gete2l(datafile):
    e2l = {}
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, worker, label = line
        if example not in e2l:
            e2l[example] = []
        e2l[example].append(float(label))

    return e2l

if __name__ == "__main__":
    datafile = sys.argv[1]
    e2l = gete2l(datafile)
    e2a = getmean(e2l)

    print e2a
