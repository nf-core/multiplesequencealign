#!/usr/bin/env python

import csv
import argparse
import sys
import pandas as pd


def prep_table(input, output):
    df = pd.read_csv(input, sep=",")
    # make nan values "null"
    df = df.rename(columns={"id": "fasta"})
    # run id as first column
    # replace in all rows the word null with default

    # add column with index as integer
    df["id"] = df.index + 1
    # make it int
    df["id"] = df["id"].astype(int)
    # make it the first column
    cols = df.columns.tolist()
    cols = cols[-1:] + cols[:-1]
    df = df[cols]
    df.to_csv(output, index=False)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(description="--")
    parser.add_argument(
        "-i",
    )

    parser.add_argument(
        "-o",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    prep_table(args.i, args.o)


if __name__ == "__main__":
    sys.exit(main())
