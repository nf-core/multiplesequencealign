#!/usr/bin/env python3
from Bio import SeqIO
import pandas as pd
import sys

fam_name = sys.argv[1]
fasta_file = sys.argv[2]
outfile = sys.argv[3]
outfile_summary = sys.argv[4]


def get_seq_lengths(fasta_file):
    fasta_sequences = SeqIO.parse(open(fasta_file), "fasta")
    summary = pd.DataFrame()
    for fasta in fasta_sequences:
        name, sequence = fasta.id, str(fasta.seq)
        l = len(sequence)
        name = name.replace("/", "_")
        # entry = pd.DataFrame([{"id": fam_name, "sequence": name, "sequence length": l}])
        entry = pd.DataFrame([{"id": fam_name,"seq_id":name, "sequence length": l}])
        # count number of sequences per sequence length
        # entry = entry.groupby(by=["id", "sequence length"]).size().reset_index(name="count")
        summary = pd.concat([summary, entry], ignore_index=True)
    return summary


summary_lengths = get_seq_lengths(fasta_file)
summary_lengths.to_csv(outfile, sep=",", index=False)
# drop column seq_id
summary_lengths = summary_lengths.drop(columns=["seq_id"])
stats_df = (
    summary_lengths.groupby(by=["id"])
    .agg({"sequence length": ["mean", "median", "max"]})["sequence length"]
    .reset_index()
)
stats_df["n_sequences"] = len(summary_lengths)
stats_df.rename(columns={"mean": "seqlength_mean", "max": "seqlength_max", "median": "seqlength_median"}, inplace=True)
stats_df.to_csv(outfile_summary, sep=",", index=False)

