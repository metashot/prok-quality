nextflow.enable.dsl=2

process genome_info {      
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'genome_info.tsv'

    input:
    path('checkm_qa.txt')
    path(barrnap_gffs)
    path(trnascan_se_outs)
   
    output:
    path 'genome_info.tsv', emit: table 
    path 'genome_info_drep.csv', emit: table_drep

    script:
    reduced_tree = params.reduced_tree ? "--reduced_tree" : ""
    """
    mkdir rtrna_dir
    mv $barrnap_gffs $trnascan_se_outs rtrna_dir
    genome_info.py \
        checkm_qa.txt \
        rtrna_dir \
        genome_info.tsv \
        genome_info_drep.csv
    """
}


process genome_filter {
    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path 'genome_info.tsv'
    path(genomes)

    output:
    path 'filtered_all/*'
    
    script:   
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    genome_filter.py \
        genome_info.tsv \
        genomes_dir \
        filtered_all \
        ${params.min_completeness} \
        ${params.max_contamination}
    """
}


process derep_info {
        publishDir "${params.outdir}" , mode: 'copy'

        input:
        path 'Cdb.csv'
        path 'Wdb.csv'

        output:
        path 'derep_info.tsv'

        script:   
        """
        derep_info.py Cdb.csv Wdb.csv derep_info.tsv
        """
    }
