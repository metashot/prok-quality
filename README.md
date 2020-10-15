# metashot/prok-quality Nextflow

metashot/prok-quality is a [Nextflow](https://www.nextflow.io/) pipeline for
assessing the quality of prokaryotic genomes, performing genome filtering and
dereplication. Moreover, the workflow reports the prediction of rRNA and tRNA
genes in accorfing to the MISAG and the MIMAG standards
https://doi.org/10.1038/nbt.3893.

Main features:

- Input: prokaryotic genomes in FASTA format;
- Completeness, contamination and strain heterogeneity estimates with
  [CheckM](https://ecogenomics.github.io/CheckM/);
- 5S, 23S and 16S prediction with [Barrnap](https://github.com/tseemann/barrnap);
- Transfer RNA (tRNA) prediction with [tRNAscan-SE](http://lowelab.ucsc.edu/tRNAscan-SE/);
- Filter genomes by their completeness and contamination values;
- An extended summary of genome quality (including the rRNA and tRNA genes
  found) is reported;
- Optionally perform the dereplication using [drep](https://github.com/MrOlm/drep).



## Quick start

1. Install [Nextflow](https://www.nextflow.io/) and [Docker](https://www.docker.com/);
1. Start running the analysis:
   
  ```bash
  nextflow run metashot/prok-quality
    --genomes '*.fa' \
    --outdir results
  ```

See the file [`nextflow.config`](nextflow.config) for the complete list of parameters.

## Output
Several directories will be created in the `results` folder:

### Main outputs
- `genome_info.tsv`: summary of genomes quality (including completeness,
  contamination, N50, rRNA genes found, number of tRNA and tRNA types, see
  below);
- `filtered_all`: genomes filtered by the `--min_completeness` and
  `--max_contamination` options; 
- `derep_info.tsv`: dereplication summary (when `--skip_dereplication=false`),
  see below; 
- `filtered_derep`: representative genomes (by dereplication, when
  `--skip_dereplication=false`).

### Secondary outputs
- `checkm`: contains the original checkm's qc file;
- `barrnap`: GFF and FASTA files containing the predicted rRNA sequences for
  bacteria (`.bac`) and archea (`.arc`) models;
- `trnascan_se`: TSV and FASTA files containing the predicted tRNA sequences for
  bacteria (`.bac`) and archea (`.arc`) models;
- `drep`: original data tables, figures and log of drep.

#### The `genome_info.tsv` file
- Genome: genome filename
- Completeness, Contamination, ..., # predicted genes: summary of genome quality
  (see https://github.com/Ecogenomics/CheckM/wiki/Genome-Quality-Commands#qa);
- 5S rRNA, 23S rRNA, 16S rRNA: Yes if the rRNA gene was found. High-quality
  drafts should encode the 23S, 16S, and 5S rRNA genes
- \# tRNA, \# tRNA types: the number of tRNA and the number of the tRNA types
  found, respectively.

#### The `derep_info.tsv` file
- Genome: genome filename
- Cluster: the cluster ID (from 0 to N-1)
- Representative: is this genome the cluster representative?

## MIMAG/MISAG standards
Following MIMAG/MISAG standards for SAG and MAG, you can classify a prokaryotic
genome as **high-quality draft** when:
- Completeness: >90%;
- Contamination <5%;
- presence of 23S, 16S, and 5S rRNA genes;
- presence of at least 18 tRNA types;

and **Medium-quality draft** when:
- Completeness: >=50%;
- Contamination <10%;

**Note**: this workflow is not intended for classify "finished" Single Amplified
Genome (SAGs) or Metagenome-Assembled Genomes (MAGs). The "finished" category is
reserved for genomes that can be assembled with extensive manual review and
editing.

## System requirements
Each step in the pipeline has a default set of requirements for number of CPUs,
memory and time. For some of the steps in the pipeline, if the job exits with an
error it will automatically resubmit with higher requests (see
[`process.config`](process.config)).

You can customize the compute resources that the pipeline requests by either:
- setting the global parameters `--max_cpus`, `--max_memory` and
  `--max_time`, or
- creating a [custom config
  file](https://www.nextflow.io/docs/latest/config.html#configuration-file)
  (`-c` or `-C` parameters), or
- modifying the [`process.config`](process.config) file.

### CheckM
CheckM requires approximately 40 GB of memory. However, if you have only 16 GB
RAM, a reduced genome tree (`--reduced_tree` option) can also be used (see
https://github.com/Ecogenomics/CheckM/wiki/Installation#system-requirements).

## Reproducibility
We recommend to specify a pipeline version when running the pipeline on your
data with the `-r` parameter:

```bash
  nextflow run metashot/kraken2 -r 1.0.0
    ...
```

Moreover, this workflow uses the docker images available at
https://hub.docker.com/u/metashot/ for reproducibility. You can check the
version of the software used in the workflow by opening the file
[`process.config`](process.config). For example `container =
metashot/kraken2:2.0.9-beta-6` means that the version of kraken2 is the
`2.0.9-beta` (the last number, 6, is the metashot release of this container).

## Singularity
If you want to use [Singularity](https://singularity.lbl.gov/) instead of Docker,
comment the Docker lines in [`nextflow.config`](nextflow.config) and add the following:

```nextflow
singularity.enabled = true
singularity.autoMounts = true
```

## Credits
This workflow is maintained Davide Albanese and Claudio Donati at the [FEM's
Unit of Computational
Biology](https://www.fmach.it/eng/CRI/general-info/organisation/Chief-scientific-office/Computational-biology).



# prok-quality

TODO 

Automatic classification of single amplified genomes (SAG) and
Metagenome-assembled genomes (MAG) following the guidelines published in ..

* CheckM
* barrnap
* tRNAscan-se
* drep

