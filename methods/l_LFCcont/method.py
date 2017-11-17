__author__ = 'JasonLee'

import sys

sep = ","

def read_data(filename, workers, items):
    with open(filename) as f:
        f.readline()
        for line in f:
            parts = line.strip().split(sep)
            value = float(parts[2])
            item_name = parts[0]
            worker_name = parts[1]
            workers.setdefault(worker_name, {'u': 0, 'data': [], 'weight': 0}).get('data').append((item_name, value))
            items.setdefault(item_name, {'data': [], 'truth': -1, 'old_truth': 0}).get('data').append((worker_name, value))

def initialise_truths(items):
    for item in items.values():
        tempdata = []
        for pair in item['data']:
            tempdata.append(pair[1])
        item['truth'] = sum(tempdata) / len(tempdata)

def compute_weights(workers, items):
    total_weight = 0.0
    for worker in workers.values():
        diffsum = 0.0
        for pair in worker['data']:
            item_name = pair[0]
            diffsum += (pair[1] - (items.get(item_name)['truth'])) ** 2
        diffsum /= len(worker['data'])
        if not diffsum:
            pass
        worker['weight'] = 1 / (diffsum + 1e-9)

def calculate_truths(workers, items):
    for item in items.values():
        total_weight = 0
        temp_truth = 0
        for pair in item['data']:
            temp_weight = workers[pair[0]]['weight']
            total_weight += temp_weight
            temp_truth += temp_weight * pair[1]
        item['truth'] = temp_truth / total_weight

def cal_variance(items):
    temp = 0.0
    for item in items.values():
        temp += (item['truth'] - item['old_truth']) ** 2
        item['old_truth'] = item['truth']
    return temp


if __name__ == "__main__":
    # if len(sys.argv) != 2:
    #     print "exit"
    #     exit(1)
    workers = {}
    items = {}
    filename = sys.argv[1]
    read_data(filename, workers, items)
    initialise_truths(items)
    iter = 50
    variance = float("inf")
    eps = 1e-6
    while iter > 0 and variance > eps:
        iter -= 1
        compute_weights(workers, items)
        calculate_truths(workers, items)
        variance = cal_variance(items)
    e2tr = {}
    for name, item in items.items():
        e2tr[name] = item['truth']

    w2q = {}
    for name, worker in workers.items():
        w2q[name] = worker['weight']

    print w2q
    print e2tr