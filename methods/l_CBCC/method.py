cd__author__ = 'JasonLee'

import sys
import commands
import os

sep = ","
exec_cs = True

if __name__ == '__main__':
    # if len(sys.argv) != 3:
    #     print "usage: %s %s %s" % (sys.argv[0], "answer_file", "truth_file")
    answer_filename = sys.argv[1]

    answer_list = []

    with open(answer_filename) as f:
        f.readline()
        for line in f:
            if not line:
                continue
            parts = line.strip().split(sep)
            item_name, worker_name, worker_label = parts[:3]
            answer_list.append([worker_name, item_name, worker_label])

    os.chdir(os.path.dirname(__file__))

    with open("Data/CF.csv", "w") as f:
        for piece in answer_list:
            f.write(",".join(piece) + "\n")

    if exec_cs:
        commands.getoutput("/bin/rm Results/endpoints.csv")
        commands.getoutput("mono CommunityBCCSourceCode.exe")

    e2lpd = {}
    with open("Results/endpoints.csv") as f:
        for line in f:
            parts = line.strip().split(sep)
            e2lpd[parts[0]] = {}
            for i, v in enumerate(parts[1:]):
                e2lpd[parts[0]][str(i)] = float(v)

    print e2lpd