
#!/usr/bin/env python

import csv
import argparse



def tcoffee_sim_parse(meta, scores):

    # read in the meta csv file
    with open(meta, 'r') as meta_file:
        meta_reader = csv.reader(meta_file)
        meta_list = list(meta_reader)

    # in the scores file    

    return(meta)



def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="--"
    )
    parser.add_argument(
        "-meta",
    )

    parser.add_argument(
        "-scores",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    tcoffee_sim_parse(args.meta, args.scores)

if __name__ == "__main__":
    sys.exit(main())
