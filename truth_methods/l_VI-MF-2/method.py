__author__ = 'JasonLee'

import commands
import sys
import os
import math

filepath = os.path.abspath(sys.argv[1])
known_path = os.path.abspath(sys.argv[2])

os.chdir(os.path.dirname(__file__))

commands.getoutput("matlab -nojvm -nodisplay -nosplash -r " + "\"" +
                   "filename = '" + filepath + "'; " +
                   "known_truth = '" + known_path + "'; " +
                   "prepare\" -logfile log")

e2lpd = {}
with open('result.csv') as f:
    for line in f:
        parts = line.strip().split(",")
        e2lpd[parts[0]] = {'0': float(parts[1]), '1': float(parts[2])}

w2cm = {}
with open('quality.csv') as f:
    for line in f:
        parts = line.strip().split(",")
        w2cm[parts[0]] = {}
        label_count = int(math.sqrt(len(parts) - 1))
        for i in range(label_count):
            w2cm[parts[0]][str(i)] = {}
            for j in range(label_count):
                w2cm[parts[0]][str(i)][str(j)] = float(parts[i * label_count + j + 1])


print w2cm
print e2lpd

