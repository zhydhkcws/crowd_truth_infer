
# this is a demo to run the file.

import commands
import sys
import random

if len(sys.argv) != 4 and len(sys.argv) != 5:
    print "usage: %s %s %s %s %s" % \
          (sys.argv[0], "method_file", "answer_file", "result_file", "(decision-making/single-label/continuous)")
    exit(0)

method_file, answer_file, result_file = sys.argv[1:4]


if len(sys.argv) == 5:
    tasktype = sys.argv[4]
    assert tasktype in ['decision-making', 'single-label', 'continuous']

if tasktype in ['decision-making', 'single-label']:
    tasktype = 'categorical'

output = commands.getoutput("python \"" + method_file + "\" \"" + answer_file + "\" " + tasktype).split('\n')[-1]

e2lpd = eval(output)

e2truth = {}
for e in e2lpd:
    if type(e2lpd[e]) == type({}):
        temp = 0
        for label in e2lpd[e]:
            if temp < e2lpd[e][label]:
                temp = e2lpd[e][label]

        candidate = []

        for label in e2lpd[e]:
            if temp == e2lpd[e][label]:
                candidate.append(label)

        truth = random.choice(candidate)

    else:
        truth = e2lpd[e]

    e2truth[e] = truth

with open(result_file, "w") as f:
    f.write("question,result\n")
    for e in e2truth:
        f.write(str(e) + "," + str(e2truth[e]) + "\n")
