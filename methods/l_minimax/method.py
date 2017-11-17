__author__ = 'JasonLee'

import commands
import sys
import os

filepath = os.path.abspath(sys.argv[1])

os.chdir(os.path.dirname(__file__))

commands.getoutput("matlab -nojvm -nodisplay -nosplash -r " + "\"" + "filename = '" +
                   filepath + "'; " + "prepare\" -logfile log")

e2lpd = {}
with open('result.csv') as f:
    for line in f:
        parts = line.strip().split(",")
        e2lpd[parts[0]] = {}
        for i, v in enumerate(parts[1:]):
            e2lpd[parts[0]][str(i)] = float(v)

print e2lpd