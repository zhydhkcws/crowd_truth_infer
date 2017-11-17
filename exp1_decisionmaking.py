import os
import commands
import math
import csv
import random
import ConfigParser 
import time

def get_label_set(datafile):
    label_set=[]

    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        _, _, label = line

        if label not in label_set:
            label_set.append(label)

    return label_set


def getaccuracy(datafile, truthfile, e2lpd):
    label_set = get_label_set(datafile) 
    # in case that e2lpd does not have data in the truthfile, then we randomly sample a label from label_set
    assert label_set == ['0', '1'] or label_set == ['1', '0']
    
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth

    tcount = 0


    for e in e2truth:

        if e not in e2lpd:
            #randomly select a label from label_set
            truth = random.choice(label_set)
            if int(truth) == int(e2truth[e]):
                tcount += 1        
            
            continue

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

        if int(truth) == int(e2truth[e]):
            tcount += 1

    return tcount*1.0/len(e2truth)


def getfscore(datafile, truthfile, e2lpd):
    label_set = get_label_set(datafile) 
    # in case that e2lpd does not have data in the truthfile, then we randomly sample a label from label_set
    assert label_set == ['0', '1'] or label_set == ['1', '0']
    
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth

    fz = 0
    fm_pre = 0
    fm_rec = 0


    for e in e2truth:
        
        if int(e2truth[e]) == 1:
            fm_rec += 1
        
        if e not in e2lpd:
            #randomly select a label from label_set
            truth = random.choice(label_set)
            if int(truth) == 1:
                fm_pre += 1
                if int(e2truth[e]) == 1:
                    fz += 1        
            
            continue

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

        if int(truth) == 1:
            fm_pre += 1
            if int(e2truth[e]) == 1:
                fz += 1
    
    if fz == 0 or fm_pre == 0:
        return 0.0
    
    precision = fz*1.0/fm_pre
    recall = fz*1.0/fm_rec
    
    return 2.0*precision*recall/(precision + recall) 


def select_kfold(datafile):
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)
    
    count = 0
    examples = {}
    for line in reader:
        example, worker, label = line
        examples[example] = 0
        count += 1
    
    return int(math.ceil(count*1.0/len(examples)))


def get_y_scores(datafile, truthfile, e2lpd):

    label_set = get_label_set(datafile)
    label_set.sort()
    #print label_set
    if label_set != ['0', '1']:
        print "It's not binary!"
        print label_set
        return
    
    #print e2lpd 
    e2score = {}
    for e in e2lpd:
        if type(e2lpd[e]) == type({}):
            if '1' in e2lpd[e]:
                e2score[e] = e2lpd[e]['1']
            else:
                if '0' in e2lpd[e]:
                    e2score[e] = 0
                else:
                    e2score[e] = e2lpd[e][1]
        
        else:
            if int(e2lpd[e]) <= 0:
                e2score[e] = 0
            else:
                e2score[e] = 1 
        
    y_true = []
    y_scores = []

    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        if e2lpd.has_key(example):
            y_scores.append(float(e2score[example]))
            y_true.append(float(truth))
        else:
            y_scores.append(float(1.0/len(label_set)))
            y_true.append(float(truth))

    return [y_true, y_scores]



def run_datasets(python_command, datasets, methods, iterations):

    for method in methods:

        for dataset in datasets:
            print "########"+dataset+"########"

            kfold = select_kfold(r'./datasets/' + dataset + '/answer.csv')
        

            if not os.path.isdir(r'./methods/' + method):
                continue
            
            # dataset & method

            truthfile = r"'./datasets/" + dataset + r"/truth.csv'"

            accuracies = []
            fscores = []
            times = []
            for iteration in range(iterations):
                tempaccuracies = []
                tempfscores = []
                temptime = []
                for foldno in range(kfold):
                    datafile = r"'./data_kfolder/" + dataset + '/' + str(iteration) \
                               + r"/answer_" + str(foldno) + ".csv'"
                    
                    starttime = time.time()
                    output = commands.getoutput(python_command + r'./methods/' + method + r'/method.py '
                                  + datafile + ' ' + '"categorical"' ).split('\n')[-1]
                    duration = time.time() - starttime
                    
                    accuracy = getaccuracy(eval(datafile), eval(truthfile), eval(output))
                    fscore = getfscore(eval(datafile), eval(truthfile), eval(output))
                    
                    temptime.append(str(duration))
                    tempaccuracies.append(str(accuracy))
                    tempfscores.append(str(fscore))
                    
                    print method + str(iteration) + '_' + str(foldno) + ':' + str(duration)
                
                times.append(temptime)
                accuracies.append(tempaccuracies)
                fscores.append(tempfscores)
                
        
            # dataset & method finished
            folder = r'./output/exp-1/decision_making' 
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            folder = folder + '/' + dataset
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            # time
            f = open(folder + '/' + 'time_' + method, 'w')
            for tempresults in times:
                f.write('\t'.join(tempresults) + '\n')
            f.close()
            
            # accuracy
            f = open(folder + '/' + 'accuracy_' + method, 'w')
            for tempresults in accuracies:
                f.write('\t'.join(tempresults) + '\n')
            f.close()
            
            # fscore
            f = open(folder + '/' + 'fscore_' + method, 'w')
            for tempresults in fscores:
                f.write('\t'.join(tempresults) + '\n')
            f.close()
            
            # pr-curve
            datafile = r"'./datasets/" + dataset + r"/answer.csv'"
            truthfile = r"'./datasets/" + dataset + r"/truth.csv'"
            output = commands.getoutput(python_command + r'./methods/' + method + r'/method.py '
                                  + datafile + ' ' + '"categorical"' ).split('\n')[-1]
            y_scores = get_y_scores(eval(datafile), eval(truthfile), eval(output))
            
            f = open(folder + '/' + 'prcurve_' + method, 'w')
            f.write(str(y_scores))
            f.close()




if __name__ == '__main__':

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    # split the data in the "./data_kfolder" folder
    import generate_kfolderdata
    iterations = eval(cf.get("exp-1", "iterations"))
    generate_kfolderdata.generate_kfolderdata(r'./data_kfolder', iterations)
    
    # get the results of each dataset and each method in "./output/exp-1" folder
    datasets_decisionmaking = eval(cf.get("exp-1", "datasets_decisionmaking"))
    methods_decisionmaking = eval(cf.get("exp-1", "methods_decisionmaking"))
    python_command = eval(cf.get("exp-1", "python_command"))
    iterations = eval(cf.get("exp-1", "iterations"))
    run_datasets(python_command, datasets_decisionmaking, methods_decisionmaking, iterations)

    # draw graph in "./exp-1-graph" folder
#     import plot_exp1_decision_making
#     plot_exp1_decision_making.plot()
    

    
    