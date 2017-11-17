__author__ = 'JasonLee'

import commands
import sys
import os

filepath = os.path.abspath(sys.argv[1])
known_path = os.path.abspath(sys.argv[2])

os.chdir(os.path.dirname(__file__))

commands.getoutput("matlab -nojvm -nodisplay -nosplash -r " + "\"" +
                   "filename = '" + filepath + "'; " +
                   "known_truth = '" + known_path + "'; " +
                   "prepare\" -logfile log")

e2lpd = {}
with open('result.csv') as f:
    line = f.readline()
    labels = line.strip().split(",")
    for line in f:
        parts = line.strip().split(",")
        e2lpd[parts[0]] = {}
        for i, v in enumerate(parts[1:]):
            e2lpd[parts[0]][labels[i]] = v

print e2lpd