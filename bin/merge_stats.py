#!/usr/bin/env python

import csv
import argparse
import sys
import pandas as pd

merging_cols = ["id"]
outfile = sys.argv[1] 
stats_files = sys.argv[2:]

summary = pd.DataFrame()
for stats in stats_files: 
    summary_df = pd.read_csv(stats, sep = ",", header = 0 )
    if(len(summary) == 0 ): 
        summary = summary_df
    else: 
        summary = summary.merge(summary_df, on = merging_cols, how = "outer")

summary.to_csv(outfile, sep = ",", index = False)