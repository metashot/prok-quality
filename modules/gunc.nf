nextflow.enable.dsl=2

process gunc {
    input:
    path(genomes)
    path(gunc_db)

    output:
    path 'GUNC.maxCSS_level.tsv', emit: maxcss

    script:
    """
    mkdir -p genomes_dir
    mkdir -p tmp
    for genome in $genomes
    do
        mv \$genome genomes_dir/\${genome}.fa
    done

    gunc run \
        --input_dir genomes_dir \
        -d ${gunc_db} \
        -t ${task.cpus}
    """
}