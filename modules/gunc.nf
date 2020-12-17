nextflow.enable.dsl=2

process gunc {
    tag "${id}"

    publishDir "${params.outdir}/gunc" , mode: 'copy'

    input:
    tuple val(id), path(genome)
    path(gunc_db)

    output:
    path '${id}/*'

    script:
    """
    gunc run \
        -i ${genome} \
        -d ${gunc_db} \
        -t ${task.cpus} \
        -o ${id}
    """
}