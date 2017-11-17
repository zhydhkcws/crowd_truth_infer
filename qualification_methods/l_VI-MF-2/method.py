__author__ = 'JasonLee'

import commands
import sys
import os

filepath = os.path.abspath(sys.argv[1])
quali_file = os.path.abspath(sys.argv[2])

os.chdir(os.path.dirname(__file__))


commands.getoutput("matlab -nojvm -nodisplay -nosplash -r " + "\"" +
                   "filename = '" + filepath + "'; " +
                   "quali_file = '" + quali_file + "'; " +
                   "prepare\" -logfile log")

e2lpd = {}
with open('result.csv') as f:
    for line in f:
        parts = line.strip().split(",")
        e2lpd[parts[0]] = {'0': float(parts[1]), '1': float(parts[2])}

print e2lpd