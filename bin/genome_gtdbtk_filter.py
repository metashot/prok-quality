#!/usr/bin/env python3

import sys
import os
import re
import shutil

import pandas as pd

INPUT_GENOMES_DIR =  sys.argv[1]
OUTPUT_GENOMES_DIR = sys.argv[2]
GTDB_BAC_SUMMARY = sys.argv[3]
GTDB_AR_SUMMARY = sys.argv[4]


# Bacteria
BAC_GENOMES_DIR = os.path.join(OUTPUT_GENOMES_DIR, "bacteria_genomes")

try:
    os.mkdir(BAC_GENOMES_DIR)
except FileExistsError:
    pass

try:
    gtdb_bac_summary_df = \
        pd.read_table(GTDB_BAC_SUMMARY, sep='\t', header=0, engine='python')
except pd.errors.EmptyDataError:
    pass
else:
    for index, row in gtdb_bac_summary_df.iterrows():
        genome_fn = os.path.join(INPUT_GENOMES_DIR, row["user_genome"])
        shutil.copy(genome_fn, BAC_GENOMES_DIR)

# Archaea
AR_GENOMES_DIR = os.path.join(OUTPUT_GENOMES_DIR, "archaea_genomes")

try:
    os.mkdir(AR_GENOMES_DIR)
except FileExistsError:
    pass

try:
    gtdb_ar_summary_df = \
        pd.read_table(GTDB_AR_SUMMARY, sep='\t', header=0, engine='python')
except pd.errors.EmptyDataError:
    pass
else:
    for index, row in gtdb_ar_summary_df.iterrows():
        genome_fn = os.path.join(INPUT_GENOMES_DIR, row["user_genome"])
        shutil.copy(genome_fn, AR_GENOMES_DIR)
