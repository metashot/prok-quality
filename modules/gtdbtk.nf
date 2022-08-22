nextflow.enable.dsl=2

process gtdbtk_classify_wf {
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'gtdbtk/gtdbtk.*'

    publishDir "${params.outdir}" , mode: 'copy' ,
        saveAs: { filename ->
            if (filename == "gtdbtk/gtdbtk.bac120.summary.tsv") "bacteria_taxonomy.tsv"
            else if (filename == "gtdbtk/gtdbtk.ar53.summary.tsv") "archaea_taxonomy.tsv"
        }

    input:
    path(genomes)
    path(gtdbtk_db)

    output:
    path "gtdbtk/*"
    path "gtdbtk/gtdbtk.bac120.summary.tsv", emit: gtdb_bac_summary
    path "gtdbtk/gtdbtk.ar53.summary.tsv", emit: gtdb_ar_summary
       
    script:
    """
    mkdir -p genomes_dir
    mkdir -p ./tmp

    for genome in $genomes
    do
        mv \$genome genomes_dir/\${genome}.fa
    done
   
    GTDBTK_DATA_PATH=${gtdbtk_db} gtdbtk classify_wf \
        --genome_dir genomes_dir \
        --out_dir gtdbtk \
        -x fa \
        --prefix gtdbtk \
        --cpus ${task.cpus} \
        --pplacer_cpus 1 \
        --tmpdir ./tmp

    if [ ! -f gtdbtk/gtdbtk.bac120.summary.tsv ]; then
        touch gtdbtk/gtdbtk.bac120.summary.tsv
    fi

    if [ ! -f gtdbtk/gtdbtk.ar53.summary.tsv ]; then
        touch gtdbtk/gtdbtk.ar53.summary.tsv
    fi

    rm -rf ./tmp
    """
}
