#!/usr/bin/env python3

import sys
import os
import re

import pandas as pd


CHECKM_QA = sys.argv[1]
GUNC_OUT = sys.argv[2]
BARRNAP_DIR = sys.argv[3]
TRNASCAN_DIR = sys.argv[4]
GENOME_INFO = sys.argv[5]


usecols_checkm = [
    "Bin Id",
    "Completeness",
    "Contamination",
    "Strain heterogeneity",
    "Genome size (bp)",
    "# ambiguous bases",
    "# scaffolds",
    "# contigs",
    "N50 (scaffolds)",
    "N50 (contigs)",
    "Mean scaffold length (bp)",
    "Mean contig length (bp)",
    "Longest scaffold (bp)",
    "Longest contig (bp)",
    "GC",
    "GC std (scaffolds > 1kbp)",
    "Coding density",
    "# predicted genes"
]

usecols_gunc = [
    "genome",
    "pass.GUNC"
]


def get_rrna(row):

    def get_name(s):
        m = re.search(r'Name=([^;]+)', s)
        if s is not None:
            return m.group(1)

    rrna = pd.Series(
        index=["5S rRNA", "23S rRNA", "16S rRNA"],
        data=["No", "No", "No"]
    )

    genome_id = os.path.splitext(row["Genome"])[0]
    for k in ["bac", "arc"]:

        gff_fn = os.path.join(BARRNAP_DIR, "{}.rRNA.{}.gff".format(genome_id, k))
        
        try:
            gff_df = pd.read_table(gff_fn, sep='\t', header=None,
                engine='python', skiprows=1, index_col=False)
        except pd.errors.EmptyDataError:
            continue

        names = gff_df[8].apply(lambda x: get_name(x)).tolist()
        for name in names:
            if name == "5S_rRNA": rrna["5S rRNA"] = "Yes"
            elif name == "23S_rRNA": rrna["23S rRNA"] = "Yes"
            elif name == "16S_rRNA": rrna["16S rRNA"] = "Yes"
            else: pass

    return rrna


def get_trna(row):

    trna = pd.Series(
        index=["# tRNA", "# tRNA types"],
        data=[0, 0]
    )

    genome_id = os.path.splitext(row["Genome"])[0]
    for k in ["bac", "arc"]:
        out_fn = os.path.join(TRNASCAN_DIR, "{}.tRNA.{}.out".format(genome_id, k))

        try:
            out_df = pd.read_table(out_fn, sep='\t', header=None,
                engine='python', skiprows=3, index_col=False)
        except pd.errors.EmptyDataError:
            continue

        n_trna = len(out_df[4])
        trna_types = set(out_df[4])
        n_trna_types = len(trna_types)
        if "Undet" in trna_types:
            n_trna_types -= 1

        trna["# tRNA"] = max(trna["# tRNA"], n_trna)
        trna["# tRNA types"] = max(trna["# tRNA types"], n_trna_types)

    return trna


checkm_df = pd.read_table(CHECKM_QA, sep='\t', header=0, engine='python',
    usecols=usecols_checkm)
checkm_df = checkm_df.set_index("Bin Id")

gunc_df = pd.read_table(GUNC_OUT, sep='\t', header=0, engine='python',
    usecols=usecols_gunc)
gunc_df = gunc_df.set_index("genome")

genome_info_df = pd.concat([checkm_df, gunc_df], axis=1, sort=False)
genome_info_df['Genome'] = genome_info.index
genome_info_df = genome_info_df.rename(columns={"pass.GUNC": "GUNC pass"})

genome_info_df[["5S rRNA", "23S rRNA", "16S rRNA"]] = \
    genome_info_df.apply(get_rrna, axis=1)

genome_info_df[["# tRNA", "# tRNA types"]] = \
    genome_info_df.apply(get_trna, axis=1)

cols_to_order = [
    "Genome",
    "Completeness",
    "Contamination",
    "Strain heterogeneity",
    "GUNC pass"
    ]
new_cols = cols_to_order + \
    genome_info_df.columns.drop(cols_to_order).tolist()
genome_info_df = genome_info_df[new_cols]

genome_info_df.to_csv(GENOME_INFO, sep='\t', index=False)
