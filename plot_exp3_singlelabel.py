import numpy as np
import matplotlib.pyplot as plt
import os 
import random  
from sklearn import metrics
import sys
import math


def plot_data(dataset, results, metric):
    #clear the file
    f = open(r'./output/exp-3-graph/' + metric + '_' + dataset + '.data', 'w')
    f.close()
    
    f = open(r'./output/exp-3-graph/' + metric + '_' + dataset + '.data', 'a')
    f.write(str(results))
    f.close()
    
    length = len(results[random.choice(results.keys())])
    
    plt.figure()
    plt.title(dataset)
    plt.xlabel('Percentage of Known Truth (* 20% )')
    plt.ylabel(metric)
    
    plots = []
    labels = []
    
    mins = sys.maxint
    maxs = -sys.maxint
    
    for method in results:
        tempmin = min(results[method])
        tempmax = max(results[method])
        mins = min(mins, tempmin)
        maxs = max(maxs, tempmax)
    
    mins = math.floor(mins*100)/100
    maxs = math.ceil(maxs*100)/100
    
    
    for method in results:
        labels.append('_'.join(method.split('_')[1:]))       
        X = results[method]
        plots.append(plt.plot(range(0, length, 1), X, label='_'.join(method.split('_')[1:])))
    
    plt.axis([0, length + length/2 , mins , maxs])
    plt.legend(loc ='lower right')
    
    plt.savefig('./output/exp-3-graph/' + metric + '_' + dataset + '.png')
    

def get_datafile(datafile):
    X = []

    f = open(datafile,'r')
    
    for line in f.xreadlines():
        line = line.strip()
        if not line:
            continue
        line = line.split('\t')
        line_x = []
        for item in line:
            line_x.append(eval(item))
        X.append(line_x)
    
    f.close()
    
    n_sample = len(X)
    X = np.sum(X, axis=0) /n_sample

    return X

def plot():
    
    folder = r'./output/exp-3-graph'

    if not os.path.isdir(folder):
        os.mkdir(folder)
        
    folder = r'./output/exp-3/singlelabel'

    if not os.path.isdir(folder):
        os.mkdir(folder)

    datasets = os.listdir(folder)
    for dataset in datasets:
        if dataset[0] == '.':
            continue
        
        newfolder = folder + r'/' + dataset
        methods = os.listdir(newfolder)
        
        accuracy = {}
        for method in methods:
            if method[0] == '.':
                continue
            
            datafile = newfolder + r'/' + method
            accuracy[method] = get_datafile(datafile)
            
        plot_data(dataset, accuracy, 'Accuracy')
        
        
if __name__ == "__main__":
    plot()


