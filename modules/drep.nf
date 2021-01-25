nextflow.enable.dsl=2

process drep {
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'filtered_repr/*'

    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'drep/{data_tables,figures,log}/*'

    input:
    path 'genomeinfo.csv'
    path(genomes)

    output:
    path 'filtered_repr/*'
    path 'drep/{data_tables,figures,log}/*'
    path 'drep/data_tables/Cdb.csv', emit: cdb
    path 'drep/data_tables/Wdb.csv', emit: wdb

    script:   
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    dRep dereplicate \
        drep \
        --genomeInfo genomeinfo.csv \
        -p ${task.cpus} \
        -nc ${params.min_overlap} \
        -sa ${params.ani_thr} \
        -l 1 \
        -comp ${params.min_completeness} \
        -con ${params.max_contamination} \
        -strW 0 \
        -g genomes_dir/*

    mv drep/dereplicated_genomes filtered_repr
    """
}
