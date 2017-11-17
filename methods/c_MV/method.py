import copy
import random
import sys
import csv


class MV:

    def __init__(self,e2wl,w2el,label_set):

        self.e2wl = e2wl
        self.w2el = w2el
        self.workers = self.w2el.keys()
        self.label_set = label_set


    def Run(self):

        e2wl = self.e2wl
        e2lpd={}
        for e in e2wl:
            e2lpd[e]={}

            # multi label
            for label in self.label_set:
                e2lpd[e][label] = 0
            # e2lpd[e]['0']=0
            # e2lpd[e]['1']=0

            for item in e2wl[e]:
                label=item[1]
                e2lpd[e][label]+= 1

            # alls=e2lpd[e]['0']+e2lpd[e]['1']
            alls = 0
            for label in self.label_set:
                alls += e2lpd[e][label]
            if alls!=0:
                # e2lpd[e]['0']=1.0*e2lpd[e]['0']/alls
                # e2lpd[e]['1']=1.0*e2lpd[e]['1']/alls
                for label in self.label_set:
                    e2lpd[e][label] = 1.0 * e2lpd[e][label] / alls
            else:
                # e2lpd[e]['0']=0.5
                # e2lpd[e]['1']=0.5
                for label in self.label_set:
                    e2lpd[e][label] = 1.0 / len(self.label_set)

        # return self.expand(e2lpd)
        return e2lpd


def gete2wlandw2el(datafile):
    e2wl = {}
    w2el = {}
    label_set=[]
    
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, worker, label = line
        if example not in e2wl:
            e2wl[example] = []
        e2wl[example].append([worker,label])

        if worker not in w2el:
            w2el[worker] = []
        w2el[worker].append([example,label])

        if label not in label_set:
            label_set.append(label)

    return e2wl,w2el,label_set


if __name__ == "__main__":
    datafile = sys.argv[1]
    e2wl,w2el,label_set = gete2wlandw2el(datafile)
    e2lpd = MV(e2wl,w2el,label_set).Run()

    print e2lpd
    

