# prok-quality

metashot/prok-quality is a comprehensive and easy-to-use pipeline for assessing
the quality of prokaryotic genomes. metashot/prok-quality reports the quality
measures recommended by the MIMAG standard (https://doi.org/10.1038/nbt.3893),
including basic assembly statistics, completeness, contamination, rRNA and tRNA
genes. Moreover, it relies on GUNC (https://doi.org/10.1101/2020.12.16.422776)
to detect chimerism (i.e. non-redundandt contamination). Reproducibility is
guaranteed by Nextflow and versioned Docker images.

*Note*: This workflow is not intended for classify "finished" SAGs or MAGs.
The "finished" category is reserved for genomes that can be assembled with
extensive manual review and editing.

- [MetaShot Home](https://metashot.github.io/)

## Main features

- Input: genomes/bins in FASTA format;
- Completeness, contamination and strain heterogeneity estimates using
  [CheckM](https://ecogenomics.github.io/CheckM/);
- Chimerism, non-redundand contamination detection using
  [GUNC](https://github.com/grp-bork/gunc);
- 5S, 23S and 16S prediction with
  [Barrnap](https://github.com/tseemann/barrnap);
- Transfer RNA (tRNA) prediction with
  [tRNAscan-SE](http://lowelab.ucsc.edu/tRNAscan-SE/);
- Filter genomes by their completeness, contamination and GUNC prediction;
- An extended summary of genome quality (including the rRNA and tRNA genes
  found) is reported;
- Dereplication (optional) using [drep](https://github.com/MrOlm/drep).

.. image:: docs/images/prok-quality.png

## Quick start

1. Install Docker (or Singulariry) and Nextflow (see
   [Dependencies](https://metashot.github.io/#dependencies));
1. Start running the analysis:
   
  ```bash
  nextflow run metashot/prok-quality \
    --genomes '*.fa' \
    --outdir results
  ```

  The GUNC database will be downloaded automatically from the Internet. If you
  want to download the GUNC database before running the analysis, run the
  following lines:

  ```
  GUNC_DB=/path/to/gunc_db
  docker run --rm -v${GUNC_DB}:/guncdb -w /guncdb metashot/gunc:1.0.1-1 gunc download_db .
  ```

  Later, run the workflow adding the parameter `--gunc_db $GUNC_DB/gunc_db_name.dmnd`

## Parameters
Options and default values are decladed in [`nextflow.config`](nextflow.config).

### Input and output
- `--genomes`: input genomes/bins in FASTA format (default `"data/*.fa"`)
- `--ext`: FASTA files extension, files with different extensions will be
  ignored (default `"fa"`)
- `--outdir`: output directory (default `results`)
- `--gunc_db`: GUNC database. If 'none' the database will be automatically
  downloaded and will be placed the output folder (`gunc_db` directory) (default
  `none`)
 
### CheckM:
- `--reduced_tree` : reduce the memory requirements to
  approximately 14 GB, set `--max_memory` to `16.GB` (default `false`)
- `--checkm_batch_size`: run CheckM on "checkm_batch_size" genomes at once see
  https://github.com/Ecogenomics/CheckM/issues/118 (default `1000`)

### GUNC:
- `--gunc_batch_size`: run GUNC on "gunc_batch_size" genomes at once (default
`100`)

### Genome filtering
- `--min_completeness`: discard sequences with less than `min_completeness`%
  completeness (default `50`)
- `--max_contamination`: discard sequences with more than
  `max_contamination`% contamination (default `10`)
- `--gunc_filter`: if true, discard genomes that do not pass the GUNC filter
  (default `false`)

### Dereplication
- `--skip_dereplication`: skip the dereplication step (default
  `false`)
- `--ani_thr`: ANI threshold for dereplication (> 0.90) (default `0.95`)
- `--min_overlap`: minimum required overlap in the alignment between genomes
  to compute ANI (default `0.30`)

### Resource limits
- `--max_cpus`: maximum number of CPUs for each process (default `8`)
- `--max_memory`: maximum memory for each process (default `70.GB`)
- `--max_time`: maximum time for each process (default `96.h`)

See also [System
requirements](https://metashot.github.io/#system-requirements).

## Output
The files and directories listed below will be created in the `results`
directory after the pipeline has finished.

### Main
- `genome_info.tsv`: summary of genomes quality (including completeness,
  contamination, GUNC filter, N50, rRNA genes found, number of tRNA and tRNA
  types). This file contains:
  - Genome: the genome filename
  - Completeness, Contamination, Strain heterogeneity: CheckM estimates
  - GUNC pass: if a genome doesn't pass GUNC analysis it means it is likely to
    be chimeric 
  - Genome size (bp), ... # predicted genes: basic genome statistics (see
    https://github.com/Ecogenomics/CheckM/wiki/Genome-Quality-Commands#qa);
  - 5S rRNA, 23S rRNA, 16S rRNA: Yes if the rRNA gene was found;
  - \# tRNA, \# tRNA types: the number of tRNA and tRNA types found,
    respectively
- `filtered`: this folder contains the genomes filtered according to
  `--min_completeness`, `--max_contamination` and `--gunc_filter` options;
- `genome_info_filtered.tsv`: same as `genome_info.tsv`, but only for the
  filtered genomes
- `derep_info.tsv`: dereplication summary (if `--skip_dereplication=false`)
  This file contains:
  - Genome: genome filename
  - Cluster: the cluster ID (from 0 to N-1)
  - Representative: is this genome the cluster representative?
- `filtered_repr`: this folder contains the genomes representative genomes (if
  `--skip_dereplication=false`)

### Secondary
- `checkm`: contains the original checkm's qc file
- `gunc`: contains the original GUNC output file
- `barrnap`: GFF and FASTA files containing the predicted rRNA sequences for
  bacteria (`.bac`) and archea (`.arc`) models
- `trnascan_se`: TSV and FASTA files containing the predicted tRNA sequences for
  bacteria (`.bac`) and archea (`.arc`) models
- `drep`: original data tables, figures and log of drep.

## Documentation

### A note on MIMAG/MISAG standards
Following MIMAG/MISAG standards, you can classify a prokaryotic genome as
**high-quality draft** when:
- its completeness is >90% and the contamination is <5%;
- 23S, 16S, and 5S rRNA genes can be predicted;
- at least 18 tRNA types can be predicted.

A genome can be classified as **medium-quality draft** when its completeness is
\>=50% and the contamination is <10%.

SCG-based tools like CheckM can have very low sensitivity towards contamination
by fragments from unrelated organisms (non-redundant contamination). In order to
circumvent this problem, we suggest to consider the GUNC analysis in addition to
the SCG-based estimation of contamination (default bahaviour, see
`--gunc_filter` option)

### A note on dereplication
When `--skip_dereplication=false`, filtered genomes will be dereplicated. After
dereplication, for each cluster the genome with the higher score is selected as
representative. The score is computed using the following formula:

  ```
  score = completeness - 5 x contamination + 0.5 x log(N50)
  ```
Common ANI thresholds are 95% for species-level dereplication or 99% as
upper-bound limit. By default the dereplication is performed with the
species-level ANI threshold (0.95, parameter `--ani_thr`).

## System requirements
Please refer to [System
requirements](https://metashot.github.io/#system-requirements) for the complete
list of system requirements options.

### Memory
CheckM requires approximately 70 GB of memory. However, if you have only 16 GB
RAM, a reduced genome tree (`--reduced_tree` option) can also be used (see
https://github.com/Ecogenomics/CheckM/wiki/Installation#system-requirements).

### Disk
For each GB of input data the workflow requires approximately 0.5/1 GB for the
final output and 2 GB for the working directory.