import numpy as np
import matplotlib.pyplot as plt
import os 
import random


def plot_data(dataset, results):
    #clear the file
    f = open(r'./output/exp-1-graph/' + 'Accuracy' + '_' + dataset + '.data', 'w')
    f.close()
    
    f = open(r'./output/exp-1-graph/' + 'Accuracy' + '_' + dataset + '.data', 'a')
    f.write(str(results))
    f.close()
    
    length = len(results[random.choice(results.keys())])
    
    plt.figure()
    plt.title(dataset)
    plt.xlabel('Average Number of Answers for Each Task')
    plt.ylabel('Accuracy')
    
    plots = []
    labels = []
    for method in results:
        labels.append('_'.join(method.split('_')[1:]))       
        X = results[method]
        plots.append(plt.plot(range(1, length + 1 , 1), X, label='_'.join(method.split('_')[1:])))
    
    plt.axis([0, length + 1 , 0 , 1])
    plt.legend(loc ='lower right')
    
    plt.savefig('./output/exp-1-graph/' + 'Accuracy' + '_' + dataset + '.png')
    

def get_datafile(datafile):
    X = []

    f = open(datafile,'r')
    
    for line in f.xreadlines():
        if not line:
            continue
        line = line.strip()
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
    folder = r'./output/exp-1/single_label'

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
            
        plot_data(dataset, accuracy)
        


if __name__ == "__main__":
    plot()


