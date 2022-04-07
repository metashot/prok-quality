nextflow.enable.dsl=2

process trnascan_se {
    tag "${id}"

    publishDir "${params.outdir}/trnascan_se/${id}" , mode: 'copy'

    input:
    tuple val(id), path(genome)

    output:
    path '*.tRNA.{bac,arc}.out', emit: out
    path '*.tRNA.{bac,arc}.fa', emit: fa

    script:
    """
    mkdir temp

    TMPDIR=temp tRNAscan-SE \
        --nopseudo \
        -B \
        --thread ${task.cpus} \
        --fasta ${id}.tRNA.bac.fa \
        -o ${id}.tRNA.bac.out \
        ${genome}

    TMPDIR=temp tRNAscan-SE \
        --nopseudo \
        -A \
        --thread ${task.cpus} \
        --fasta ${id}.tRNA.arc.fa \
        -o ${id}.tRNA.arc.out \
        ${genome}

    rm -rf temp
    """
}