nextflow.enable.dsl=2

process barrnap {
    tag "${id}"

    publishDir "${params.outdir}/barrnap/${id}" , mode: 'copy'

    input:
    tuple val(id), path(genome)

    output:
    path '*.rRNA.{bac,arc}.gff', emit: gff
    path '*.rRNA.{bac,arc}.fa', emit: fa

    script:
    """
    barrnap \
        --kingdom bac \
        --outseq ${id}.rRNA.bac.fa \
        --threads ${task.cpus} \
        ${genome} > ${id}.rRNA.bac.gff

    barrnap \
        --kingdom arc \
        --outseq ${id}.rRNA.arc.fa \
        --threads ${task.cpus} \
        ${genome} > ${id}.rRNA.arc.gff
    """
}