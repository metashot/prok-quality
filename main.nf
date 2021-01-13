#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { checkm } from './modules/checkm'
include { barrnap } from './modules/barrnap'
include { trnascan_se } from './modules/trnascan_se'
include { drep } from './modules/drep'
include { gunc } from './modules/gunc'
include { genome_info; genome_filter; derep_info } from './modules/utils'

workflow {

    genomes_ch = Channel
        .fromPath( params.genomes )
        .map { file -> tuple(file.baseName, file) }

    /* collate genomes in chunks of params.batch_size, see 
     * https://github.com/Ecogenomics/CheckM/issues/118
     */
    genomes_batch_ch = genomes_ch
        .map { row -> row[1] }
        .collate( params.batch_size )

    checkm(genomes_batch_ch)

    checkm_qa_ch = checkm.out.qa
        .collectFile(
            name:'qa.txt', 
            keepHeader: true,
            skip: 1,
            storeDir: "${params.outdir}/checkm",
            newLine: true)

    barrnap(genomes_ch)
    trnascan_se(genomes_ch)

    if (params.use_gunc) {
        gunc_db = file(params.gunc_db, type: 'dir', checkIfExists: true)
        gunc(genomes_batch_ch, gunc_db)
        gunc_maxcss_ch = gunc.out.maxcss
        .collectFile(
            name:'gunc.tsv', 
            keepHeader: true,
            skip: 1,
            storeDir: "${params.outdir}",
            newLine: true)
    }

    genome_info(checkm_qa_ch, barrnap.out.gff.collect(),
        trnascan_se.out.out.collect())
    
    genome_filter(genome_info.out.table, genomes_batch_ch.flatten().collect())

    if (!params.skip_dereplication) {
        drep(genome_info.out.table_drep, genomes_batch_ch.flatten().collect())
        derep_info(drep.out.cdb, drep.out.wdb)  
    }
}
