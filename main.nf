#!/usr/bin/env nextflow

Channel
    .fromPath( params.genomes )
    .filter { it.extension == params.genomes_ext }
    .map { file -> tuple(file.baseName, file) }
    .into { genomes_checkm_tmp_ch; genomes_barrnap_ch; genomes_trnascan_se_ch } 

genomes_checkm_tmp_ch
    .map { row -> row[1] }
    .into { genomes_checkm_ch; genomes_drep_ch; genomes_genome_filter_ch }

/*
 * Step 0. CheckM
 */
process checkm {      
    tag "all"

    publishDir "${params.outdir}/data/checkm" , mode: 'copy'

    input:
    path(genomes) from genomes_checkm_ch.collect()

    output:
    path 'qa.txt' into checkm_qa_extract_info_ch
    
    script:
    reduced_tree = params.reduced_tree ? "--reduced_tree" : ""
    """   
    mkdir -p tmp
   
    checkm lineage_wf \
        --tmpdir tmp \
        -t ${task.cpus} \
        -x ${params.genomes_ext} \
        ${reduced_tree} \
        . \
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

/*
 * Step 1.a barrnap
 */
process barrnap {
    tag "${id}"

    publishDir "${params.outdir}/data/barrnap/${id}" , mode: 'copy'

    input:
    tuple val(id), path(genome) from genomes_barrnap_ch

    output:
    path '*.rRNA.{bac,arc}.gff' into rrna_gff_extract_info_ch
    path '*.rRNA.{bac,arc}.fa'

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

/*
 * Step 1.b tRNAscan
 */
process trnascan_se {
    tag "${id}"

    publishDir "${params.outdir}/data/trnascan_se/${id}" , mode: 'copy'

    input:
    tuple val(id), path(genome) from genomes_trnascan_se_ch

    output:
    path '*.tRNA.{bac,arc}.out' into trna_out_extract_info_ch
    path '*.tRNA.{bac,arc}.fa'

    script:
    """
    tRNAscan-SE \
        --nopseudo \
        -B \
        --thread ${task.cpus} \
        --fasta ${id}.tRNA.bac.fa \
        -o ${id}.tRNA.bac.out \
        ${genome}

    tRNAscan-SE \
        --nopseudo \
        -A \
        --thread ${task.cpus} \
        --fasta ${id}.tRNA.arc.fa \
        -o ${id}.tRNA.arc.out \
        ${genome}
    """
}

/*
 * Step 2. Genome info
 */
process genome_info {      
    tag "all"

    publishDir "${params.outdir}" , mode: 'copy' ,
        pattern :'genome_info.tsv'

    input:
    path('checkm_qa.txt') from checkm_qa_extract_info_ch
    path(rrna_gffs) from rrna_gff_extract_info_ch.collect()
    path(trna_outs) from trna_out_extract_info_ch.collect()
   
    output:
    path 'genome_info.tsv' into genome_info_genome_filter_ch 
    path 'genome_info_drep.csv' into genome_info_drep_ch 

    script:
    reduced_tree = params.reduced_tree ? "--reduced_tree" : ""
    """
    mkdir rtrna
    mv $rrna_gffs $trna_outs rtrna
    genome_info.py \
        checkm_qa.txt \
        rtrna \
        genome_info.tsv \
        genome_info_drep.csv \
        ${params.genomes_ext}
    """
}

/*
 * Step 3. Genome filter
 */
process genome_filter {
    tag "all"

    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path 'genome_info.tsv' from genome_info_genome_filter_ch
    path(genomes) from genomes_genome_filter_ch.collect()

    output:
    path 'filtered_all/*'
    
    script:   
    """
    mkdir genomes
    mv $genomes genomes
    genome_filter.py \
        genomes \
        filtered_all \
        ${params.genomes_ext} \
        genome_info.tsv \
        ${params.min_completeness} \
        ${params.max_contamination}
    """
}

/*
 * Step 4. Dereplication
 */
if (!params.skip_dereplication) {
    process drep {
        tag "all"
    
        publishDir "${params.outdir}" , mode: 'copy' ,
            pattern: 'filtered_derep/*'
    
        publishDir "${params.outdir}/data" , mode: 'copy' ,
            pattern: 'drep/{data_tables,figures,log}/*'
    
        input:
        path 'genome_info_drep.csv' from genome_info_drep_ch
        path(genomes) from genomes_drep_ch.collect()
    
        output:
        path 'filtered_derep/*'
        path 'drep/{data_tables,figures,log}/*'
        path 'drep/data_tables/Cdb.csv' into drep_cdb_derep_info_ch
        path 'drep/data_tables/Wdb.csv' into drep_wdb_derep_info_ch
    
        script:   
        """
        mkdir genomes
        mv $genomes genomes
        dRep dereplicate \
            drep \
            --genomeInfo genome_info_drep.csv \
            -p ${task.cpus} \
            -nc ${params.min_overlap} \
            -sa ${params.ani_thr} \
            -comp ${params.min_completeness} \
            -con ${params.max_contamination} \
            -strW 0 \
            -g genomes/*
    
        mv drep/dereplicated_genomes filtered_derep 
        """
    }
}

/*
 * Step 5. Derep info
 */
process derep_info {
    tag "all"

    publishDir "${params.outdir}" , mode: 'copy'

    input:
    path 'Cdb.csv' from drep_cdb_derep_info_ch
    path 'Wdb.csv' from drep_wdb_derep_info_ch
    
    output:
    path 'derep_info.tsv'
    
    script:   
    """
    derep_info.py Cdb.csv Wdb.csv derep_info.tsv ${params.genomes_ext}
    """
}
