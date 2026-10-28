#!/usr/bin/env python

import csv
import argparse
import sys
import pandas as pd


def tcoffee_irmsd_parse(input, output):
    df = pd.read_csv(input, skiprows=1, sep=":", header=None)
    df[0] = df[0].str.replace("\tTOTAL", "")
    df[1] = df[1].str.replace("Angs", "").str.strip()
    df[1] = df[1].str.replace("%", "").str.strip()
    df.set_index(0, inplace=True)
    df = df.transpose()
    # header = ",".join(list(df.columns.str.replace("\s","", regex = True)))
    # values = ",".join(list(df.iloc[0].tolist()))
    # remove all spaces from column names
    df.columns = df.columns.str.replace("\s", "", regex=True)
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

    if args.i.endswith(".total_irmsd"):
        print(args.i)
        print(args.o)
        tcoffee_irmsd_parse(args.i, args.o)


if __name__ == "__main__":
    sys.exit(main())
