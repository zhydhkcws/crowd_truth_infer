import random
import csv
import sys
import math
import os
import ConfigParser
import exp1_decisionmaking

# def shuffle_data(dataset, kfold, kfolddir, iteration):
# 
#     folder = kfolddir + '/' + dataset + '/' + str(iteration)
#     if not os.path.isdir(folder):
#         os.mkdir(folder)
# 
# 
#     datafile = r'./datasets/' + dataset + '/answer.csv'
#     record = read_datafile(datafile)
# 
#     random.seed(iteration)
#     random.shuffle(record)
# 
#     par_n = int(math.floor(len(record)*1.0 / kfold))
# 
# 
# 
#     for i in range(kfold):
#         csvfile_w = file(folder+'/answer_'+str(i)+'.csv', 'wb+')
#         writer = csv.writer(csvfile_w)
#         temp=[['question', 'worker', 'answer']]
#         writer.writerows(temp)
#         if i != kfold-1:
#             writer.writerows(record[0:(i+1)*par_n])
#         else:
#             writer.writerows(record[0:])
#         csvfile_w.close()

def gete2wl(record):
    e2wl = {}
    for line in record:
        example, worker, label = line
        if example not in e2wl:
            e2wl[example] = []
        e2wl[example].append([worker,label])
    
    return e2wl

def generaterows(e2wl, redundancy):
    rows = []
    for example in e2wl:
        wl = e2wl[example][:redundancy]
        for worker, label in wl:
            rows.append([example, worker, label])
    
    return rows

def shuffle_data(dataset, kfold, kfolddir, iteration):

    folder = kfolddir + '/' + dataset + '/' + str(iteration)
    if not os.path.isdir(folder):
        os.mkdir(folder)


    datafile = r'./datasets/' + dataset + '/answer.csv'
    record = read_datafile(datafile)

    random.seed(iteration)
    random.shuffle(record)
    
    e2wl = gete2wl(record)


    for i in range(kfold):
        csvfile_w = file(folder+'/answer_'+str(i)+'.csv', 'wb+')
        writer = csv.writer(csvfile_w)
        temp=[['question', 'worker', 'answer']]
        writer.writerows(temp)
        if i != kfold-1:
            writer.writerows(generaterows(e2wl, i+1))
        else:
            writer.writerows(record[0:])
        csvfile_w.close()
        

def read_datafile(datafile):

    record = []
    f = open(datafile, 'r')
    reader = csv.reader(f)
    next(reader)

    for line in reader:
        record.append(line)

    return record


def generate_kfolderdata(kfolddir, iterations):
    
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

        kfold = exp1_decisionmaking.select_kfold(r'./datasets/' + dataset + '/answer.csv')
        print kfold

        for iteration in range(iterations):
            shuffle_data(dataset, kfold, kfolddir, iteration)


    


if __name__ == "__main__":

    cf = ConfigParser.ConfigParser()
    cf.read('./config.ini')

    iterations = eval(cf.get("exp-1", "iterations"))

    generate_kfolderdata(r'./data_kfolder', iterations)

    