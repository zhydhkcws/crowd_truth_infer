import random
import csv
import sys
import math
import os
import ConfigParser


def getw2el(record):
    w2el = {}
    for line in record:
        example, worker, label = line
        if worker not in w2el:
            w2el[worker] = []
        w2el[worker].append([example,label])
    
    return w2el

def gete2truth(record):
    e2truth = {}
    for line in record:
        example, truth = line
        e2truth[example] = truth
    
    return e2truth
    

def generaterows(w2el, e2truth, samples = 20):
    rows = []
    for worker in w2el:
        for _ in range(samples):
            example, label = random.choice(w2el[worker])
            truth = e2truth[example]
            rows.append([worker, example, label, truth])
    
    return rows

def generate_data(dataset, kfolddir, iteration):
    
    datafile = r'./datasets/' + dataset + '/answer.csv'
    truthfile = r'./datasets/' + dataset + '/truth.csv'
    datarecord = read_datafile(datafile)
    truthrecord = read_datafile(truthfile)

    random.seed(iteration)
    
    w2el = getw2el(datarecord)
    e2truth = gete2truth(truthrecord)
    
    csvfile_w = file(kfolddir + '/' + dataset + '/' + str(iteration) + '.csv', 'wb+')
    writer = csv.writer(csvfile_w)
    temp=[['worker', 'question', 'answer', 'truth']]
    writer.writerows(temp)
    writer.writerows(generaterows(w2el, e2truth))
    csvfile_w.close()
        

def read_datafile(datafile):

    record = []
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        record.append(line)

    return record


def generate_qualification_kfolderdata(kfolddir, iterations):
    
    if os.path.isdir(kfolddir):
        import shutil
        shutil.rmtree(kfolddir)

    os.mkdir(kfolddir)
    
    datasets = os.listdir(r'./datasets')
    datasets = [dataset for dataset in datasets if dataset[0] != '.']

    for dataset in datasets:
        tempfolder = kfolddir + '/' + dataset
        if not os.path.isdir(tempfolder):
            os.mkdir(tempfolder)

        for iteration in range(iterations):
            generate_data(dataset, kfolddir, iteration)


    


if __name__ == "__main__":

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    iterations = eval(cf.get("exp-2", "iterations"))

    generate_qualification_kfolderdata(r'./qualification_data_kfolder', iterations)

    