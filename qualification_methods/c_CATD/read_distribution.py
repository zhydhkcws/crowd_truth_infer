import re
import os
import sys
def isfloat(value):
  try:
    float(value)
    return True
  except ValueError:
    return False

def read_chi_square_distribution():
    dir = os.path.split(sys.argv[0])[0]
    file = open(dir+'/chi-square distribution.txt','r')
    flag = 0
    chi_square_conf = []
    chi_square_dis = dict()
    for line in file.readlines():
        line=re.split('\t|\n',line)
        if (flag == 0):
            for i in range(13):
                chi_square_conf.append(float(line[i+1]))
            flag = 1
        else:
            free_degree=int(line[0])
            temp=dict()
            for i in range(13):
                if (isfloat(line[i+1])):
                    temp[chi_square_conf[i]]=float(line[i+1])
                else:
                    temp[chi_square_conf[i]]=0.000001
            chi_square_dis[free_degree]=temp
    file.close()
    return chi_square_conf, chi_square_dis

def read_normal_distribution():
    dir = os.path.split(sys.argv[0])[0]
    file = open(dir + '/normal distribution.txt','r')
    flag = 0
    normal_conf = []
    normal_dis  = dict()
    for line in file.readlines():
        line=re.split('\t|\n',line)
        if (flag == 0):
            for i in range(13):
                normal_conf.append(float(line[i]))
            flag = 1
        else:
            for i in range(13):
                normal_dis[normal_conf[i]]=float(line[i])


    file.close()
    return normal_conf, normal_dis

def read_t_distribution():
    dir = os.path.split(sys.argv[0])[0]
    file = open(dir+'/t distribution.txt','r')
    flag = 0
    t_conf = []
    t_dis = dict()
    for line in file.readlines():
        line=re.split('\t|\n',line)
        if (flag == 0):
            for i in range(11):
                t_conf.append(float(line[i+1]))
            flag = 1
        else:
            free_degree=int(line[0])
            temp=dict()
            for i in range(11):
                if (isfloat(line[i+1])):
                    temp[t_conf[i]]=float(line[i+1])
                else:
                    print "t dis error"
            t_dis[free_degree]=temp
    file.close()
    return t_conf, t_dis