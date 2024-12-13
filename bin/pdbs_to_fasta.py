#!/usr/bin/env python

# read in multiple pdb files, extract the sequence and write to a fasta file
import sys
from Bio import PDB
from Bio.SeqUtils import seq1


def pdb_to_fasta(pdb_file):
    """
    Extract the sequence from a PDB file and format it in FASTA.
    """
    parser = PDB.PDBParser(QUIET=True)
    structure = parser.get_structure(pdb_file, pdb_file)
    fasta_sequences = []
    file_id = pdb_file.rsplit(".", 1)[0]  # Use the file name without extension as ID

    for model in structure:
        for chain in model:
            sequence = []
            for residue in chain:
                if PDB.is_aa(residue, standard=True):
                    sequence.append(seq1(residue.resname))
            if sequence:
                fasta_sequences.append(f">{file_id}\n{''.join(sequence)}")
            return "\n".join(fasta_sequences)

def main():
    pdb_files = sys.argv[1:]
    for pdb_file in pdb_files:
        fasta = pdb_to_fasta(pdb_file)
        print(f"{fasta}")

if __name__ == "__main__":
    main()
