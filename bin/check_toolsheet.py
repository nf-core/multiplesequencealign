#!/usr/bin/env python


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import csv
import logging
import sys
from collections import Counter
from pathlib import Path

logger = logging.getLogger()


def cleanargs(argstring):
    cleanargs = argstring.strip().replace("-", "").replace(" ", "_").replace("==", "_").replace("\s+", "")

    return cleanargs


class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
            validated and transformed row. The order of rows is maintained.

    """

    def __init__(
        self,
        tree_col="tree",
        argstree_col="args_tree",
        argstree_clean_col="argstree_clean",
        align_col="align",
        argsalign_col="args_align",
        argsalign_clean_col="argsalign_clean",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.

        Args:
            family_col (str): The name of the column that contains the family name
                (default "family").
            fasta_col (str): The name of the column that contains the fasta file
                 path (default "fasta").

        """
        super().__init__(**kwargs)
        self._tree_col = tree_col
        self._argstree_col = argstree_col
        self._argstree_clean_col = argstree_clean_col
        self._align_col = align_col
        self._argsalign_col = argsalign_col
        self._argsalign_clean_col = argsalign_clean_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_align(row)
        self._validate_tree(row)
        self._validate_argstree(row)
        self._validate_argsalign(row)
        self._seen.add(
            (
                row[self._tree_col],
                row[self._argstree_col],
                row[self._align_col],
                row[self._argsalign_col],
                row[self._argstree_clean_col],
            )
        )
        print(row)
        self.modified.append(row)

    def _validate_tree(self, row):
        """Assert that the family name exists and convert spaces to underscores."""
        if len(row[self._tree_col]) <= 0:
            row[self._tree_col] = "none"
        # Sanitize samples slightly.
        row[self._tree_col] = row[self._tree_col]

    def _validate_argstree(self, row):
        if len(row[self._argstree_col]) <= 0:
            row[self._argstree_col] = "none"
            row[self._argstree_clean_col] = "none"
        # Sanitize samples slightly.
        row[self._argstree_col] = row[self._argstree_col]
        row[self._argstree_clean_col] = cleanargs(row[self._argstree_col])

    def _validate_align(self, row):
        if len(row[self._align_col]) <= 0:
            raise AssertionError("alignment tool is required.")
        # Sanitize samples slightly.
        row[self._align_col] = row[self._align_col]
        row[self._argsalign_clean_col] = cleanargs(row[self._argsalign_col])

    def _validate_argsalign(self, row):
        if len(row[self._argsalign_col]) <= 0:
            row[self._argsalign_col] = "none"
            row[self._argsalign_clean_col] = "none"
        # Sanitize samples slightly.
        row[self._argsalign_col] = row[self._argsalign_col]

    def validate_unique_samples(self):
        """
        Assert that the combination of family name and fasta filename is unique.

        """
        if len(self._seen) != len(self.modified):
            raise AssertionError("The pair of sample name and fasta must be unique.")
        seen = Counter()
        for row in self.modified:
            entry = row[self._tree_col] + row[self._argstree_col] + row[self._align_col] + row[self._argsalign_col]
            seen[entry] += 1


def read_head(handle, num_lines=10):
    """Read the specified number of lines from the current position in the file."""
    lines = []
    for idx, line in enumerate(handle):
        if idx == num_lines:
            break
        lines.append(line)
    return "".join(lines)


def sniff_format(handle):
    """
    Detect the tabular format.

    Args:
        handle (text file): A handle to a `text file`_ object. The read position is
        expected to be at the beginning (index 0).

    Returns:
        csv.Dialect: The detected tabular format.

    .. _text file:
        https://docs.python.org/3/glossary.html#term-text-file

    """
    peek = read_head(handle)
    handle.seek(0)
    sniffer = csv.Sniffer()
    dialect = sniffer.sniff(peek)
    return dialect


def check_samplesheet(file_in, file_out):
    """
    Check that the tabular samplesheet has the structure expected by nf-core pipelines.

    Validate the general shape of the table, expected columns, and each row. Also add
    an additional column which records whether one or two FASTQ reads were found.

    Args:
        file_in (pathlib.Path): The given tabular samplesheet. The format can be either
            CSV, TSV, or any other format automatically recognized by ``csv.Sniffer``.
        file_out (pathlib.Path): Where the validated and transformed samplesheet should
            be created; always in CSV format.

    Example:



    """
    required_columns = {"align"}
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        # Validate the existence of the expected header columns.
        if not required_columns.issubset(reader.fieldnames):
            req_cols = ", ".join(required_columns)
            logger.critical(f"The sample sheet **must** contain these column headers: {req_cols}.")
            sys.exit(1)
        # Validate each row.
        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)
        checker.validate_unique_samples()
    header = list(reader.fieldnames)
    header.append("argstree_clean")
    header.append("argsalign_clean")

    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py samplesheet.csv samplesheet.valid.csv",
    )
    parser.add_argument(
        "file_in",
        metavar="FILE_IN",
        type=Path,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "file_out",
        metavar="FILE_OUT",
        type=Path,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.file_in.is_file():
        logger.error(f"The given input file {args.file_in} was not found!")
        sys.exit(2)
    args.file_out.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.file_in, args.file_out)


if __name__ == "__main__":
    sys.exit(main())
