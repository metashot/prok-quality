#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { checkm } from './modules/checkm'
include { barrnap } from './modules/barrnap'
include { trnascan_se } from './modules/trnascan_se'
include { drep } from './modules/drep'
include { genome_info, genome_filter, derep_info } from './modules/utils'

workflow {

    Channel
        .fromPath( params.genomes )
        .map { file -> tuple(file.baseName, file) }
        .into { genomes_ch } 

    /* collate genomes in chunks of params.batch_size, see 
     * https://github.com/Ecogenomics/CheckM/issues/118
     */
    genomes_ch
        .map { row -> row[1] }
        .collate( params.batch_size )
        .set { genomes_checkm_ch }

    checkm(genomes_checkm_ch)

    checkm.out.qa
        .collectFile(
            name:'qa.txt', 
            keepHeader: true,
            skip: 1,
            storeDir: "${params.outdir}/checkm",
            newLine: true)
        .set { checkm_qa_ch }

    barrnap(genomes_ch)
    trnascan_se(genomes_ch)

    genome_info(checkm_qa_ch, barrnap.out.gff.collect(),
        trnascan_se.out.collect())
    
    genome_filter(genome_info.out.table, genomes_checkm_ch)

    if (!params.skip_dereplication) {
        drep(genome_info.out.table_drep, genomes_checkm_ch)
        derep_info(drep.out.cdb, drep.out.wdb)  
    }
