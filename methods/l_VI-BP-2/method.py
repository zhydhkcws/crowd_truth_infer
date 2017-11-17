__author__ = 'JasonLee'

import commands
import sys
import os
import math

filepath = os.path.abspath(sys.argv[1])

os.chdir(os.path.dirname(__file__))

commands.getoutput("matlab -nojvm -nodisplay -nosplash -r " + "\"" + "filename = '" +
                   filepath + "'; " + "prepare\" -logfile log")

e2lpd = {}
with open('result.csv') as f:
    for line in f:
        parts = line.strip().split(",")
        if math.isnan(float(parts[1])):
            e2lpd[parts[0]] = {'0': 0, '1': 0}
        else:
            e2lpd[parts[0]] = {'0': 0, '1': float(parts[1])}

print e2lpd