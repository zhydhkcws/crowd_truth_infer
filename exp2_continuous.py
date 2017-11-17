import os
import commands
import math
import csv
import random
import ConfigParser 
import time

# Mean Absolute Error (MAE), and Root Mean Square Error (RMSE)

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


def getMAE(datafile, truthfile, e2lpd):
    label_set = get_label_set(datafile) 
    # in case that e2lpd does not have data in the truthfile, then we randomly sample a label from label_set
    
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth

    value = 0
    

    for e in e2truth:

        if e not in e2lpd:
            #randomly select a label from label_set
            truth = random.choice(label_set)
            value += abs( float(truth) - float(e2truth[e]) )
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

        value += abs( float(truth) - float(e2truth[e]) )

    return value*1.0/len(e2truth)


def getRMSE(datafile, truthfile, e2lpd):
    label_set = get_label_set(datafile) 
    # in case that e2lpd does not have data in the truthfile, then we randomly sample a label from label_set
    
    e2truth = {}
    f = open(truthfile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        example, truth = line
        e2truth[example] = truth

    value = 0
    

    for e in e2truth:

        if e not in e2lpd:
            #randomly select a label from label_set
            truth = random.choice(label_set)
            value += ( float(truth) - float(e2truth[e]) )**2
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

        value += ( float(truth) - float(e2truth[e]) )**2

    return math.sqrt( value*1.0/len(e2truth) )


def run_datasets(python_command, datasets, methods, iterations):
    
    for method in methods:
        print "########" + method + "########"
        
        for dataset in datasets:
            
            if not os.path.isdir(r'./methods/' + method):
                continue
            
            # dataset & method

            truthfile = r"'./datasets/" + dataset + r"/truth.csv'"

            
            datafile = r"'./datasets/" + dataset + '/' + r"/answer.csv'"
            output = commands.getoutput(python_command + r'./methods/' + method + r'/method.py '
                                  + datafile + ' ' + '"categorical"' ).split('\n')[-1]
            
            originalMAE = getMAE(eval(datafile), eval(truthfile), eval(output))
            originalRMSE = getRMSE(eval(datafile), eval(truthfile), eval(output))
            
            MAEs = []
            RMSEs = []
            
            for iteration in range(iterations):
                
                tempfile = r"'./qualification_data_kfolder/" + dataset + '/' + str(iteration) + ".csv'"
                
                #print datafile, tempfile
                
                output = commands.getoutput(python_command + r'./qualification_methods/' + method + r'/method.py '
                                  + datafile + ' ' + tempfile + ' ' + '"categorical"' ).split('\n')[-1]
                
                MAE = getMAE(eval(datafile), eval(truthfile), eval(output))
                RMSE = getRMSE(eval(datafile), eval(truthfile), eval(output))
                    
                    
                MAEs.append(str(MAE))
                RMSEs.append(str(RMSE))
                    
                print dataset + str(iteration) 
            
            MAEs.insert(0, str(originalMAE))
            RMSEs.insert(0, str(originalRMSE))
            
            print MAEs
            print RMSEs
            
            # dataset & method finished
            folder = r'./output/exp-2/continuous' 
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            folder = folder + '/' + dataset
            if not os.path.isdir(folder):
                os.mkdir(folder)
            
            # MAE
            f = open(folder + '/' + 'MAE_' + method, 'w')
            f.write(str(MAEs))
            f.close()

            # RMSE
            f = open(folder + '/' + 'RMSE_' + method, 'w')
            f.write(str(RMSEs))
            f.close()




if __name__ == '__main__':

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    # split the data in the "./qualification_data_kfolder" folder
#     import generate_qualification_kfolderdata
#     iterations = eval(cf.get("exp-2", "iterations"))
#     generate_qualification_kfolderdata.generate_qualification_kfolderdata(r'./qualification_data_kfolder', iterations)

    # get the results of each dataset and each method in "./output/exp-2" folder
    datasets_continuous = eval(cf.get("exp-2", "datasets_continuous"))
    qualification_continuous = eval(cf.get("exp-2", "qualification_continuous"))
    python_command = eval(cf.get("exp-2", "python_command"))
    iterations = eval(cf.get("exp-2", "iterations"))
    run_datasets(python_command, datasets_continuous, qualification_continuous, iterations)

    

    
    