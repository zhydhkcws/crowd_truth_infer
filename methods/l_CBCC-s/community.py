__author__ = 'JasonLee'

import sys
import commands

sep = ","
exec_cs = True

if __name__ == '__main__':
    # if len(sys.argv) != 3:
    #     print "usage: %s %s %s" % (sys.argv[0], "answer_file", "truth_file")
    answer_filename = "answer.csv" # sys.argv[1]
    truth_filename = "truth.csv"   # sys.argv[2]
    answer_list = []
    truth_dict = {}
    with open(truth_filename) as f:
        for line in f:
            if not line:
                continue
            parts = line.strip().split(sep)
            truth_dict[parts[0]] = parts[1]

    with open(answer_filename) as f:

        for line in f:
            if not line:
                continue
            parts = line.strip().split(sep)
            item_name, worker_name, worker_label = parts[:3]
            answer_list.append([worker_name, item_name, worker_label, truth_dict[item_name]])

    with open("Data/CF.csv", "w") as f:
        for piece in answer_list[1:]:
            f.write(",".join(piece) + "\n")

    if exec_cs:
        commands.getoutput("/bin/rm Results/endpoints.csv")
        commands.getoutput("mono CommunityBCCSourceCode")

    with open("Results/endpoints.csv") as f:
        bccacc = f.readline().split(",")[1]
        cbccacc = f.readline().split(",")[1]

    print "bcc_acc: ", bccacc
    print "cbcc_acc:", cbccacc