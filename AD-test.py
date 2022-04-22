#!/usr/bin/env python
# coding: utf-8

# In[1]:


import scipy.stats
import csv
from collections import defaultdict


# In[2]:


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


# In[3]:


sB = score_extractor('BaccegaUnmasked-09-57-25-13016.csv')
print(sB)


# In[4]:


scipy.stats.anderson(sB, dist='norm')


# In[6]:


sA = score_extractor('AmparoreUnmasked-09-02-24-409.csv')
print(sA)


# In[8]:


scipy.stats.anderson(sA, dist='norm')


# In[9]:


sI = score_extractor('IdilioUnmasked-09-02-24-16518.csv')
scipy.stats.anderson(sI, dist='norm')


# In[ ]:




