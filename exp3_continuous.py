import os
import commands
import math
import csv
import random
import ConfigParser 

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


def getMAE(datafile, truthfile, e2lpd, partialtruthfile):
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


def getRMSE(datafile, truthfile, e2lpd, partialtruthfile):
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


def run_datasets(python_command, datasets, methods, iterations, splits):

    for dataset in datasets:
        print "########"+dataset+"########"
        
        for method in methods:
            
            if not os.path.isdir(r'./truth_methods/' + method):
                continue

            # dataset & method

            datafile = r"'./datasets/" + dataset + r"/answer.csv'"
            truthfile = r"'./datasets/" + dataset + r"/truth.csv'"
            
            MAEs = []
            RMSEs = []
            for iteration in range(iterations):
                
                tempMAEs = []
                tempRMSEs = []
                
                for foldno in splits:
                    
                    partialtruthfile = r"'./truth_data_kfolder/" + dataset + '/' + str(iteration) \
                               + r"/truth_" + str(foldno) + ".csv'"

                    command = python_command + r'./truth_methods/' + method + r'/method.py ' \
                             + datafile + ' ' + partialtruthfile + ' ' + '"categorical"' 
                    output = commands.getoutput(command).split('\n')[-1]

                    MAE = getMAE(eval(datafile), eval(truthfile), eval(output), eval(partialtruthfile))
                    RMSE = getRMSE(eval(datafile), eval(truthfile), eval(output), eval(partialtruthfile))
                    tempMAEs.append(str(MAE))
                    tempRMSEs.append(str(RMSE))

                    print method + str(iteration) + '_' + str(foldno) 

                MAEs.append(tempMAEs)
                RMSEs.append(tempRMSEs)

        
            # dataset & method finished
            folder = r'./output/exp-3/continuous' 
            
            if not os.path.isdir(folder):
                os.mkdir(folder)

            folder = folder + '/' + dataset
            if not os.path.isdir(folder):
                os.mkdir(folder)

            f = open(folder + '/' + 'MAE' + '_' + method, 'w')
            for tempresults in MAEs:
                f.write('\t'.join(tempresults) + '\n')
            f.close()
            
            f = open(folder + '/' + 'RMSE' + '_' + method, 'w')
            for tempresults in RMSEs:
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
    datasets_continuous = eval(cf.get("exp-3", "datasets_continuous"))
    truth_continuous = eval(cf.get("exp-3", "truth_continuous"))
    python_command = eval(cf.get("exp-3", "python_command"))
    iterations = eval(cf.get("exp-3", "iterations"))
    splits = eval(cf.get("exp-3", "splits"))
    run_datasets(python_command, datasets_continuous, truth_continuous, iterations, splits)

    # draw graph in "./exp-3-graph" folder
    import plot_exp3_continuous
    plot_exp3_continuous.plot()
    

    
    