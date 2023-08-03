#!/usr/bin/env python

import csv
import argparse
import sys
import pandas as pd

merging_cols = ["id", "tree", "args_tree", "align", "args_align"]
scores_files = sys.argv[2:]
outfile = sys.argv[1] 

summary_scores = pd.DataFrame()
for scores in scores_files: 
    scores_df = pd.read_csv(scores, sep = ",", header = 0 )
    if(len(summary_scores) == 0 ): 
        summary_scores = scores_df
    else: 
        summary_scores = summary_scores.merge(scores_df, on = merging_cols, how = "outer")

summary_scores.to_csv(outfile, sep = ",", index = False)