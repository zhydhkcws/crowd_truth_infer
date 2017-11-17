import numpy as np
import matplotlib.pyplot as plt
import os 
import random  
from sklearn import metrics


def plot_data(dataset, results, metric):
    #clear the file
    f = open(r'./output/exp-1-graph/' + metric + '_' + dataset + '.data', 'w')
    f.close()
    
    f = open(r'./output/exp-1-graph/' + metric + '_' + dataset + '.data', 'a')
    f.write(str(results))
    f.close()
    
    length = len(results[random.choice(results.keys())])
    
    plt.figure()
    plt.title(dataset)
    plt.xlabel('Average Number of Answers for Each Task')
    plt.ylabel(metric)
    
    plots = []
    labels = []
    for method in results:
        labels.append('_'.join(method.split('_')[1:]))       
        X = results[method]
        plots.append(plt.plot(range(1, length + 1 , 1), X, label='_'.join(method.split('_')[1:])))
    
    plt.axis([0, length + 1 , 0 , 1])
    plt.legend(loc ='lower right')
    
    plt.savefig('./output/exp-1-graph/' + metric + '_' + dataset + '.png')
    

def plot_curve(results, methods, dataset):
    
    plt.figure()
    plt.plot([0, 1], [0, 1], 'k--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.0])
    plt.xlabel('recall')
    plt.ylabel('precision')
    plt.title('Precision-Recall Curve')

    plots = []
    labels = []
    
    aucs = {}
    
    labels.append('precision=recall')
    
    for i in range(len(results)):
        
        precision, recall, _ = metrics.precision_recall_curve(results[i][0],results[i][1])
        roc_auc = metrics.auc(recall, precision)
        aucs[methods[i]] = "%.4f" %roc_auc
        my_label = methods[i] + '(' + aucs[methods[i]] + ')'
        plots.append(plt.plot(recall, precision, label=my_label))
        

        
        labels.append(methods[i] + '(' + aucs[methods[i]] + ')' )
        
        #print 'The AUC of ' + str(methods[i]) + ' is : ' + str(roc_auc)

    # write file
    f = open(r'./output/exp-1-graph/' + 'PRcurve_' + dataset + '.data', 'w')
    f.write(str(aucs) + '\n')
    f.close()

    plt.legend(loc ='lower left')
    plt.savefig('./output/exp-1-graph/' + 'PRcurve_' + dataset  + '.png')
    


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
    folder = r'./output/exp-1/decision_making'

    if not os.path.isdir(folder):
        os.mkdir(folder)

    datasets = os.listdir(folder)
    for dataset in datasets:
        if dataset[0] == '.':
            continue
        
        newfolder = folder + r'/' + dataset
        methods = os.listdir(newfolder)
        
        accuracy = {}
        fscore = {}
        prcurve = {}
        for method in methods:
            if method[0] == '.':
                continue
            
            datafile = newfolder + r'/' + method
            if method.startswith('accuracy'):
                accuracy[method] = get_datafile(datafile)
            if method.startswith('fscore'):
                fscore[method] = get_datafile(datafile)
            if method.startswith('prcurve'):
                prcurve[method] = eval(open(datafile).read())
            
        plot_data(dataset, accuracy, 'Accuracy')
        plot_data(dataset, fscore , 'Fscore')
        plot_curve([prcurve[key] for key in prcurve], ['_'.join(key.split('_')[1:]) for key in prcurve], dataset)



if __name__ == "__main__":
    plot()


