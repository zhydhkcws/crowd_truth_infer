import os
import commands
import math
import csv
import random
import ConfigParser 


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



def getaccuracy(datafile, truthfile, e2lpd, partialtruthfile):
    label_set = get_label_set(datafile) 
    # in case that e2lpd does not have data in the truthfile, then we randomly sample a label from label_set
    
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth


    f = open(partialtruthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        del e2truth[example]
    
    

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



def run_datasets(python_command, datasets, methods, iterations, splits):

    for dataset in datasets:
        print "########"+dataset+"########"
        
        for method in methods:
            
            if not os.path.isdir(r'./truth_methods/' + method):
                continue

            # dataset & method

            datafile = r"'./datasets/" + dataset + r"/answer.csv'"
            truthfile = r"'./datasets/" + dataset + r"/truth.csv'"

            accuracies = []
            for iteration in range(iterations):
                tempresults = []
                for foldno in splits:
                    
                    partialtruthfile = r"'./truth_data_kfolder/" + dataset + '/' + str(iteration) \
                               + r"/truth_" + str(foldno) + ".csv'"

                    command = python_command + r'./truth_methods/' + method + r'/method.py ' \
                             + datafile + ' ' + partialtruthfile + ' ' + '"categorical"' 
                    output = commands.getoutput(command).split('\n')[-1]
                    
                    accuracy = getaccuracy(eval(datafile), eval(truthfile), eval(output), eval(partialtruthfile))
                    tempresults.append(str(accuracy))

                    print method + str(iteration) + '_' + str(foldno) + ": " + str(accuracy)

                accuracies.append(tempresults)
        
            # dataset & method finished
            
            folder = r'./output/exp-3' 
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            folder = folder + r'/singlelabel' 
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            folder = folder + '/' + dataset
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            # accuracy
            f = open(folder + '/' + 'accuracy_' + method, 'w')
            for tempresults in accuracies:
                f.write('\t'.join(tempresults) + '\n')
            f.close()




if __name__ == '__main__':

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    # split the data in the "./truth_data_kfolder" folder
    # import generate_truth_kfolderdata
    # iterations = eval(cf.get("exp-3", "iterations"))
    # splits = eval(cf.get("exp-3", "splits"))
    # generate_truth_kfolderdata.generate_truth_kfolderdata(r'./truth_data_kfolder', iterations, splits)
    
    # get the results of each dataset and each method in "./output/exp-3" folder
    datasets_singlelabel = eval(cf.get("exp-3", "datasets_singlelabel"))
    truth_singlelabel = eval(cf.get("exp-3", "truth_singlelabel"))
    python_command = eval(cf.get("exp-3", "python_command"))
    iterations = eval(cf.get("exp-3", "iterations"))
    splits = eval(cf.get("exp-3", "splits"))
    run_datasets(python_command, datasets_singlelabel, truth_singlelabel, iterations, splits)

    # draw graph in "./exp-3-graph" folder
    import plot_exp3_singlelabel
    plot_exp3_singlelabel.plot()
    

    
    