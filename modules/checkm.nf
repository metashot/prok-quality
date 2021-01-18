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
    for genome in $genomes
    do
        id="\${genome%.*}"
        mv \$genome genomes_dir/\${id}.fa
    done

    checkm lineage_wf \
        --tmpdir tmp \
        -t ${task.cpus} \
        -x fa \
        ${reduced_tree} \
        genomes_dir \
        checkm
    
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