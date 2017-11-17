#The task is to identify the sentiment on whether it is neutral(0), happy(1), sad(2) or angry(3) for a given face image.
import csv
csvfile_data = file('face4crd.csv', 'rb')
reader_data = csv.reader(csvfile_data)

csvfile_data = file('face4crd.csv', 'rb')
reader_data = csv.reader(csvfile_data)

csvfile_gt = file('face4details.csv', 'rb')
reader_gt = csv.reader(csvfile_gt)

X=[]
for line in reader_data:
    for i in range(9):
        j=1+i*5
        a=-1
        for k in range(4):
            if str(line[j+k+1]) == '1' and a >= 0:
                print "Duplication Error!!!!!"
            if str(line[j+k+1]) == '1' and a < 0:
                a = k
        if a < 0:
            print line
            print j
            print "No Answer Error!!!!!"
        else:
            X.append([line[0],line[j],a])


flag=0
Y=[]
for line in reader_gt:
    if flag!=0:
        a=-1
        if line[5]==' neutral':
            a=0
        if line[5]==' happy':
            a=1
        if line[5]==' sad':
            a=2
        if line[5]==' angry':
            a=3
        if a < 0:
            print "Truth Error!!!!!"
        else:
            Y.append([line[0],a])

    else:
        flag=1

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


csvfile_data.close()
csvfile_gt.close()