#!/usr/bin/env python3

import sys

import numpy as np
import pandas as pd


DREP_CDB = sys.argv[1]
DREP_WDB = sys.argv[2]
DEREP_INFO = sys.argv[3]


drep_cdb_df = pd.read_table(DREP_CDB, sep=',', header=0, engine='python') \
    .set_index('genome')
drep_wdb_df = pd.read_table(DREP_WDB, sep=',', header=0, engine='python') \
    .set_index("genome")

derep_info_df = drep_cdb_df.join(drep_wdb_df, on="genome")

derep_info_df["Representative"] = \
    np.where(pd.isnull(derep_info_df["cluster"]), "No", "Yes") 

derep_info_df = derep_info_df[["secondary_cluster", "Representative"]]. \
    reset_index(). \
    rename(columns={"genome": "ID", "secondary_cluster": "Cluster"})

derep_info_df.to_csv(DEREP_INFO, sep='\t', index=False)
