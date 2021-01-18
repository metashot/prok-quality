nextflow.enable.dsl=2

process genome_info {      
    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern: 'genome_info.tsv'

    input:
    path('checkm_qa.txt')
    path('gunc_out.tsv')
    path(barrnap_gffs)
    path(trnascan_se_outs)
   
    output:
    path 'genome_info.tsv', emit: table 

    script:
    """
    mkdir barrnap_gffs_dir
    mv $barrnap_gffs barrnap_gffs_dir

    mkdir trnascan_se_outs_dir
    mv $trnascan_se_outs trnascan_se_outs_dir

    genome_info.py \
        checkm_qa.txt \
        gunc_out.tsv \
        barrnap_gffs_dir \
        trnascan_se_outs_dir \
        genome_info.tsv
    """
}

process genome_filter {
    publishDir "${params.outdir}" , mode: 'copy'
    
    input:
    path 'genome_info.tsv'
    path(genomes)

    output:
    path 'genome_info_filtered.tsv', emit: table
    path 'genome_info_filtered_drep.csv', emit: table_drep
    path 'filtered/*', emit: genomes
    
    script:
    gunc_filter = params.gunc_filter ? "1" : "0"
    """
    mkdir genomes_dir
    mv $genomes genomes_dir
    genome_filter.py \
        genome_info.tsv \
        genomes_dir \
        ${params.ext} \
        genome_info_filtered.tsv \
        genome_info_filtered_drep.csv \
        filtered \
        ${params.min_completeness} \
        ${params.max_contamination} \
        $gunc_filter
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
