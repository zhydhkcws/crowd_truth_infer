import math,csv,random
import numpy as np
import read_distribution as cdis
import sys

class Conf_Aware:
    def __init__(self,e2wl,w2el,label_set,datatype):
        self.e2wl = e2wl
        self.w2el = w2el
        self.weight = dict()
        self.label_set = label_set
        self.datatype = datatype

    def examples_truth_calculation(self):
        self.truth = dict()

        if self.datatype == 'continuous':
             for example, worker_label_set in self.e2wl.items():
                temp = 0
                for worker, label in worker_label_set:
                    temp = temp + self.weight[worker] * float(label)

                self.truth[example] = temp

        else:
            for example, worker_label_set in self.e2wl.items():
                temp = dict()
                for worker, label in worker_label_set:
                    if (temp.has_key(label)):
                        temp[label] = temp[label] + self.weight[worker]
                    else:
                        temp[label] = self.weight[worker]

                max = 0
                for label, num in temp.items():
                    if num > max:
                        max = num

                candidate = []
                for label, num in temp.items():
                    if max == num:
                        candidate.append(label)

                self.truth[example] = random.choice(candidate)

    def workers_weight_calculation(self):
        self.weight = dict()
        weight_sum = 0
        for worker, example_label_set in self.w2el.items():
            ns = len(example_label_set)
            if ns <= 30:
                chi_s = self.chi_square_distribution[ns][1-self.alpha/2]
            else:
                chi_s = 0.5 * pow(self.normal_distribution[1-self.alpha/2] + pow(2*ns-1 , 0.5) ,2)
            #print ns, chi_s
            dif = 0
            for example, label in example_label_set:
                if self.datatype == 'continuous':
                    dif = dif + (self.truth[example]-float(label))**2
                else:
                    if self.truth[example]!=label:
                        dif = dif + 1
            if dif==0:
                print worker, ns, dif, chi_s / (dif + 0.00001)

            self.weight[worker] = chi_s / (dif + 0.000000001)
            weight_sum = weight_sum + self.weight[worker]

        for worker in self.w2el.keys():
            self.weight[worker] = self.weight[worker] / weight_sum


    def Init_truth(self):
        self.truth = dict()

        if self.datatype == 'continuous':
            for example, worker_label_set in self.e2wl.items():
                temp = []
                for _, label in worker_label_set:
                    temp.append(float(label))

                self.truth[example] = np.median(temp)  # using median as intial value
                #self.truth[example] = np.mean(temp)  # using mean as initial value


        else:
            # using majority voting to obtain initial value
            for example, worker_label_set in self.e2wl.items():
                temp = dict()
                for _, label in worker_label_set:
                    if (temp.has_key(label)):
                        temp[label] = temp[label] + 1
                    else:
                        temp[label] = 1

                max = 0
                for label, num in temp.items():
                    if num > max:
                        max = num

                candidate = []
                for label, num in temp.items():
                    if max == num:
                        candidate.append(label)

                self.truth[example] = random.choice(candidate)

    def get_e2lpd(self):

        if self.datatype == 'continuous':
            return self.truth
        else:
            e2lpd = dict()
            for example, worker_label_set in self.e2wl.items():
                temp = dict()
                sum = 0.0
                for worker, label in worker_label_set:
                    if (temp.has_key(label)):
                        temp[label] = temp[label] + self.weight[worker]
                    else:
                        temp[label] = self.weight[worker]
                    sum = sum + self.weight[worker]

                for label in temp.keys():
                    temp[label] = temp[label] / sum

                e2lpd[example] = temp

            return e2lpd

    def get_workerquality(self):
        sum_worker = sum(self.weight.values())
        norm_worker_weight = dict()
        for worker in self.weight.keys():
            norm_worker_weight[worker] = self.weight[worker] / sum_worker
        return norm_worker_weight

    def Run(self,alpha,iterr,inital_weight):
        self.chi_square_conf, self.chi_square_distribution = cdis.read_chi_square_distribution()
        self.normal_conf,self.normal_distribution = cdis.read_normal_distribution()
        self.alpha = alpha
        self.Init_truth()
        self.weight = inital_weight
        while iterr > 0:
            #print getaccuracy(sys.argv[2], self.truth, datatype)
            self.examples_truth_calculation()
            self.workers_weight_calculation()

            iterr -= 1

        return self.get_e2lpd(), self.weight



###################################
# The above is the EM method (a class)
# The following are several external functions
###################################

def getaccuracy(truthfile, predict_truth, datatype):
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth

    tcount = 0
    count = 0

    for e, ptruth in predict_truth.items():

        if e not in e2truth:
            continue

        count += 1

        if datatype=='continuous':
            tcount = tcount + (ptruth-float(e2truth[e]))**2 #root of mean squared error
            #tcount = tcount + math.fabs(ptruth-float(e2truth[e])) #mean of absolute error
        else:
            if ptruth == e2truth[e]:
                tcount += 1

    if datatype=='continuous':
        return pow(tcount/count,0.5)  #root of mean squared error
        #return tcount/count  #mean of absolute error
    else:
        return tcount*1.0/count

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

def inital_distance_calculation(datatype,answer,truth):
    if datatype == 'continuous':
        return (float(answer) - float(truth))**2
    elif datatype == 'categorical':
        if answer != truth:
            return 1.0
        else:
            return 0.0
    else:
        print 'datatype error!'

def inital_qualification(datafile,datatype):
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)
    inital_weight = dict()

    for line in reader:
        worker, example, answer, truth = line
        if inital_weight.has_key(worker):
            inital_weight[worker] = inital_weight[worker] + inital_distance_calculation(datatype,answer,truth)
        else:
            inital_weight[worker] = inital_distance_calculation(datatype,answer,truth)

    weight_sum = 0.0

    for worker in inital_weight.keys():
        weight_sum = weight_sum + inital_weight[worker]

    for worker in inital_weight.keys():
        inital_weight[worker] = inital_weight[worker] / weight_sum

    return inital_weight

if __name__ == "__main__":

    # if len(sys.argv)>=4 and sys.argv[3] == 'continuous':
    #     datatype = r'continuous'
    # else:
    #     datatype = r'categorical'

    datafile = sys.argv[1]
    datatype = sys.argv[3]
    e2wl, w2el, label_set = gete2wlandw2el(datafile)

    qualificationfile = sys.argv[2]
    inital_weight = inital_qualification(qualificationfile, datatype)

    e2lpd, weight = Conf_Aware(e2wl,w2el,label_set,datatype).Run(0.05,100,inital_weight)

    print weight # print worker quality
    print e2lpd

    # truthfile = sys.argv[2]
    # accuracy = getaccuracy(truthfile, predict_truth, datatype)
    # print accuracy
