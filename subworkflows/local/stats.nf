//
// Compute stats about the input sequences
//

include {   TCOFFEE_SEQREFORMAT_SIM       } from '../../modules/local/tcoffee_seqreformat_sim.nf'
include {   CALCULATE_SEQSTATS            } from '../../modules/local/calculate_seqstats.nf'
include {   MERGE_STATS                   } from '../../modules/local/merge_stats.nf'


workflow STATS {
    take:
    ch_seqs                //      channel: meta, /path/to/file.fasta
   

    main:

    ch_versions = Channel.empty()
    TCOFFEE_SEQREFORMAT_SIM(ch_seqs)
    tcoffee_seqreformat_sim = TCOFFEE_SEQREFORMAT_SIM.out.perc_sim
    tcoffee_seqreformat_simtot = TCOFFEE_SEQREFORMAT_SIM.out.perc_sim_tot
    ch_versions = ch_versions.mix(TCOFFEE_SEQREFORMAT_SIM.out.versions.first())                    

    CALCULATE_SEQSTATS(ch_seqs)
    seqstats = CALCULATE_SEQSTATS.out.seqstats
    seqstats_summary = CALCULATE_SEQSTATS.out.seqstats_summary
    ch_versions = ch_versions.mix(CALCULATE_SEQSTATS.out.versions.first())


    // 
    // Summarize stats into one summary file
    //  
    tcoffee_seqreformat_simtot.map{ it ->  "${it[1].text}" }.collectFile( name: 'tcoffee_seqreformat_simtot_summary.csv',
                                                                          keepHeader : true,
                                                                          skip:1,                                         
                                                                          newLine: false)
                                                            .set { tcoffee_seqreformat_simtot_summary }


    seqstats_summary.map{ it ->  "${it[1].text}" }.collectFile( name: 'seqstats.csv',
                                                                          keepHeader : true,
                                                                          skip:1,                                         
                                                                          newLine: false)
                                                  .set { seqstats_summary }

    MERGE_STATS( tcoffee_seqreformat_simtot_summary,
                 seqstats_summary )
    
    ch_versions = ch_versions.mix(MERGE_STATS.out.versions)                      


    emit:
    tcoffee_seqreformat_sim                           
    tcoffee_seqreformat_simtot 
    seqstats
    seqstats_summary                              
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}