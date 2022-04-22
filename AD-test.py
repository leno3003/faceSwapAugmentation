#!/usr/bin/env python
import scipy.stats
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
        scores.append(float(i))

    return scores
sB = score_extractor('BaccegaUnmasked-09-57-25-13016.csv')
print(sB)
src_filename = glob.glob('material/results/')
v = []
for f in src_filename:
    s = score_extractor(f+f+'.csv')
    p = scipy.stats.anderson(s, dist='norm')
    v.append(list(f, p))

