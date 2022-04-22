#!/usr/bin/env python
import scipy.stats
import glob
import matplotlib.pyplot as plt
import csv
from collections import defaultdict

def score_extractor(path):
    columns = defaultdict(list) # each value in each column is appended to a list

    with open(path) as f:
        reader = csv.DictReader(f) # read rows into a dictionary format
        for row in reader: # read a row as {column1: value1, column2: value2,...}
            for (k,v) in row.items(): # go over each column name and value 
                columns[k].append(v) # append the value into the appropriate list
                                     # based on column name k
    scores = []
    for i in columns['landmark_distance_sum']:
        if float(i) > 0:
            scores.append(float(i))

    return scores


def float_score(s):
    return (float(s.split(" ")[0].split('=')[1][0:-1]))


src_filename = glob.glob('material/results/**/*.full.csv')
v = []
for f in src_filename:
    s = score_extractor(f)
    p = scipy.stats.lognorm.fit(s)
    #v.append([f, float_score(str(p))])
    plt.hist(s, bins=200)
    plt.show()
    v.append([f, str(p)])
for f in v:
    print(f)
    print("\n")

