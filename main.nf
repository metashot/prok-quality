#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { checkm } from './modules/checkm'
include { barrnap } from './modules/barrnap'
include { trnascan_se } from './modules/trnascan_se'
include { drep } from './modules/drep'
include { gunc_db_download; gunc } from './modules/gunc'
include { genome_info; genome_filter; derep_info } from './modules/utils'

workflow {

    genomes_ch = Channel
        .fromPath( params.genomes, type:'file')
        .filter { it.getExtension() == params.ext }
        .map { file -> tuple(file.baseName, file) }

    genomes_noid_ch = genomes_ch
        .map { row -> row[1] }

    /* CheckM */
    /* collate genomes in chunks of params.batch_size, see 
     * https://github.com/Ecogenomics/CheckM/issues/118 */
    checkm_genomes_batch_ch = genomes_noid_ch
        .collate( params.checkm_batch_size )
    checkm(checkm_genomes_batch_ch)
    checkm_qa_ch = checkm.out.qa
        .collectFile(
            name:'qa.txt', 
            keepHeader: true,
            skip: 1,
            storeDir: "${params.outdir}/checkm",
            newLine: true)

    /* GUNC */
    gunc_genomes_batch_ch = genomes_noid_ch
        .collate( params.gunc_batch_size )

    if (params.gunc_db == 'none') {
        gunc_db_download()
        gunc_db = gunc_db_download.out.gunc_db
    }
    else {
        gunc_db = file(params.gunc_db, checkIfExists: true)
    }

    gunc(gunc_genomes_batch_ch, gunc_db)
    gunc_maxcss_ch = gunc.out.maxcss_level
        .collectFile(
            name:'GUNC.maxCSS_level.tsv', 
            keepHeader: true,
            skip: 1,
            storeDir: "${params.outdir}/gunc",
            newLine: false)
   
    /* rRNAs and tRNAs */
    barrnap(genomes_ch)
    trnascan_se(genomes_ch)

    /* Build the genome_info.tsv table */
    genome_info(
        checkm_qa_ch,
        gunc_maxcss_ch,
        barrnap.out.gff.collect(),
        trnascan_se.out.out.collect())
    
    /* Filter genomes*/
    genome_filter(genome_info.out.table, genomes_noid_ch.collect())

    /* Dereplication */
    if (!params.skip_dereplication) {
        drep(genome_filter.out.table_drep, genome_filter.out.genomes.collect())
        derep_info(drep.out.cdb, drep.out.wdb)
    }
}
