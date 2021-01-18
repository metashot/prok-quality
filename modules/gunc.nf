nextflow.enable.dsl=2


process gunc_db_download {

    publishDir "${params.outdir}/gunc_db" , mode: 'copy'

    output:
    path 'gunc_db_*.dmnd', emit: gunc_db

    script:
    """
    gunc download_db .
    """
}


process gunc {
    input:
    path(genomes)
    path(gunc_db)

    output:
    path 'GUNC.maxCSS_level.tsv', emit: maxcss_level

    script:
    """
    mkdir -p genomes_dir
    for genome in $genomes
    do
        id="\${genome%.*}"
        mv \$genome genomes_dir/\${id}.fa
    done

    gunc run \
        --input_dir genomes_dir \
        --db_file ${gunc_db} \
        --threads ${task.cpus}
    """
}
