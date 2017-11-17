import yaml
import csv
file_data=open('labels.yaml')
file_data=yaml.load(file_data)
X=[]
for worker in file_data:
    answers=file_data[worker]
    for question in answers:
        ans=answers[question]
        a=-1
        if ans==False:
            a=0
        if ans==True:
            a=1
        if a<0:
            print "Answer Errorr!!!!"
        else:
            X.append([question,worker,a])

file_gt=open('gt.yaml')
file_gt=yaml.load(file_gt)
Y=[]
for question in file_gt:
    ans=file_gt[question]
    a=-1
    if ans==False:
        a=0
    if ans==True:
        a=1
    if a<0:
        print "Truth Errorr!!!!"
    else:
        Y.append([question,a])


csvfile_w = file('answer.csv', 'wb+')
writer = csv.writer(csvfile_w)
temp=[['question', 'worker', 'answer']]
writer.writerows(temp)
writer.writerows(X)
csvfile_w.close()

csvfile_w = file('truth.csv', 'wb+')
writer = csv.writer(csvfile_w)
temp=[['question', 'truth']]
writer.writerows(temp)
writer.writerows(Y)
csvfile_w.close()