nextflow.enable.dsl=2

process checkm {      
    input:
    path(genomes)

    output:
    path 'qa.txt', emit: qa
    
    script:
    reduced_tree = params.reduced_tree ? "--reduced_tree" : ""
    """
    mkdir -p tmp
    mkdir -p genomes_dir
    mv $genomes genomes_dir

    checkm lineage_wf \
        --tmpdir tmp \
        -t ${task.cpus} \
        -x ${params.ext} \
        ${reduced_tree} \
        genomes_dir \
        checkm

    # repeat qa for the extended summary of bin quality
    checkm qa \
        --tmpdir tmp \
        -t ${task.cpus} \
        --tab_table \
        -o 2 \
        -f qa.txt \
        checkm/lineage.ms \
        checkm 
    
    rm -rf tmp/
    """
}