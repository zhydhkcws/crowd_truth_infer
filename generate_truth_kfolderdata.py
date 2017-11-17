import random
import csv
import sys
import math
import os
import ConfigParser

def shuffle_data(dataset, truth_kfolddir, iteration, splits):

    folder = truth_kfolddir + '/' + dataset + '/' + str(iteration)
    if not os.path.isdir(folder):
        os.mkdir(folder)


    datafile = r'./datasets/' + dataset + '/truth.csv'
    record = read_datafile(datafile)

    random.seed(iteration)
    random.shuffle(record)

    par_n = len(record)*1.0 / 100

    for i in splits:
        csvfile_w = file(folder+'/truth_'+str(i)+'.csv', 'wb+')
        writer = csv.writer(csvfile_w)
        temp=[['question', 'worker', 'answer']]
        writer.writerows(temp)
        writer.writerows(record[0:int(i*par_n)])
        csvfile_w.close()


def read_datafile(datafile):

    record = []
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        record.append(line)

    return record


def generate_truth_kfolderdata(truth_kfolddir, iterations, splits):
    
    if os.path.isdir(truth_kfolddir):
        import shutil
        shutil.rmtree(truth_kfolddir)

    os.mkdir(truth_kfolddir)
    
    datasets = os.listdir(r'./datasets')
    datasets = [dataset for dataset in datasets if dataset[0] != '.']

    for dataset in datasets:
        print dataset
        tempfolder = truth_kfolddir + '/' + dataset
        if not os.path.isdir(tempfolder):
            os.mkdir(tempfolder)

        for iteration in range(iterations):
            shuffle_data(dataset, truth_kfolddir, iteration, splits)


    


if __name__ == "__main__":

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    iterations = eval(cf.get("exp-3", "iterations"))
    splits = eval(cf.get("exp-3", "splits"))
    
    generate_truth_kfolderdata(r'./truth_data_kfolder', iterations, splits)


    