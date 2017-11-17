import csv

file_data=open('dogs-1.merged.label.tsv')
X=[]
for line in file_data:
    line=line.split()
    X.append([line[0],line[1],line[2]])


file_gt=open('dogs-1.merged.truth.tsv')
Y_dict=dict()
for line in file_gt:
    line=line.split()
    if not Y_dict.has_key(line[0]):
        Y_dict[line[0]]=line[1]


csvfile_w = file('answer.csv', 'wb+')
writer = csv.writer(csvfile_w)
temp=[['question', 'worker', 'answer']]
writer.writerows(temp)
writer.writerows(X)
csvfile_w.close()

Y=Y_dict.items();
csvfile_w = file('truth.csv', 'wb+')
writer = csv.writer(csvfile_w)
temp=[['question', 'truth']]
writer.writerows(temp)
writer.writerows(Y)
csvfile_w.close()