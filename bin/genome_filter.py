#!/usr/bin/env python3

import sys
import os
import re
import shutil

import pandas as pd


GENOME_INFO = sys.argv[1]
GENOMES_DIR = sys.argv[2]
GENOMES_EXT = sys.argv[3]
FILTERED_GENOME_INFO = sys.argv[4]
FILTERED_GENOME_INFO_DREP = sys.argv[5]
FILTERED_GENOMES_DIR = sys.argv[6]
MIN_COMPLETENESS = float(sys.argv[7])
MAX_CONTAMINATION = float(sys.argv[8])
GUNC_FILTER = bool(sys.argv[9])


def filter(row):
    genome_fn = os.path.join(GENOMES_DIR,
        row["Genome"]+".{}".format(GENOMES_EXT))
    shutil.copy(genome_fn, FILTERED_GENOMES_DIR)

try:
    os.mkdir(FILTERED_GENOMES_DIR)
except FileExistsError:
    pass

genome_info_df = pd.read_table(GENOME_INFO, 
    sep='\t', header=0, engine='python')

filtered_genome_info_df = genome_info_df[
    (genome_info_df["Completeness"] >= MIN_COMPLETENESS) & \
    (genome_info_df["Contamination"] <= MAX_CONTAMINATION) & \
    ~(GUNC_FILTER & ~genome_info_df["GUNC pass"])
    ]

filtered_genome_info_df.apply(filter, axis=1)
filtered_genome_info_df.to_csv(FILTERED_GENOME_INFO, sep='\t', index=False)

# Filtered genome info for dRep
filtered_genome_info_drep_df = filtered_genome_info_df[[
    "Genome",
    "Completeness",
    "Contamination",
    "Strain heterogeneity"]]

filtered_genome_info_drep_df.rename(columns={
    "Genome": "genome",
    "Completeness":"completeness",
    "Contamination": "contamination",
    "Strain heterogeneity": "strain_heterogeneity"
    }, inplace=True)

filtered_genome_info_drep_df.to_csv(FILTERED_GENOME_INFO_DREP, sep=',',
    index=False)
