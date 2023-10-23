//
// Compute stats about the input sequences
//
include {   CALCULATE_SEQSTATS                             } from '../../modules/local/calculate_seqstats.nf'
include {   TCOFFEE_SEQREFORMAT as TCOFFEE_SEQREFORMAT_SIM } from '../../modules/nf-core/tcoffee/seqreformat/main.nf'
include {   CSVTK_CONCAT  as CONCAT_SEQSTATS               } from '../../modules/nf-core/csvtk/concat/main.nf'
include {   CSVTK_CONCAT  as CONCAT_SIMSTATS               } from '../../modules/nf-core/csvtk/concat/main.nf'
include {   CSVTK_JOIN    as MERGE_STATS                   } from '../../modules/nf-core/csvtk/join/main.nf'


workflow STATS {
    take:
    ch_seqs                //      channel: meta, /path/to/file.fasta
   

    main:

    ch_versions = Channel.empty()

    // -------------------------------------------
    //      SEQUENCE SIMILARITY 
    // -------------------------------------------
    TCOFFEE_SEQREFORMAT_SIM(ch_seqs)
    tcoffee_seqreformat_sim = TCOFFEE_SEQREFORMAT_SIM.out.perc_sim
    tcoffee_seqreformat_simtot = TCOFFEE_SEQREFORMAT_SIM.out.perc_sim_tot
    ch_versions = ch_versions.mix(TCOFFEE_SEQREFORMAT_SIM.out.versions.first()) 
    
    ch_sim_summary = tcoffee_seqreformat_simtot.map{ 
                                                meta, csv -> csv
                                            }.collect().unique().map{
                                                csv -> [ [id_simstats:"summary_simstats"], csv]
                                            }
    CONCAT_SIMSTATS(ch_sim_summary, "csv", "csv")

    // -------------------------------------------
    //      SEQUENCE GENERAL STATS
    //      Sequence length, # of sequences, etc 
    // -------------------------------------------
    CALCULATE_SEQSTATS(ch_seqs)
    seqstats = CALCULATE_SEQSTATS.out.seqstats
    seqstats_summary = CALCULATE_SEQSTATS.out.seqstats_summary
    ch_versions = ch_versions.mix(CALCULATE_SEQSTATS.out.versions.first())

    ch_seqstats_summary = seqstats_summary.map{ 
                                                meta, csv -> csv
                                            }.collect().unique().map{
                                                csv -> [ [id_seqstats:"summary_seqstats"], csv]
                                            }
    CONCAT_SEQSTATS(ch_seqstats_summary, "csv", "csv")


    // -------------------------------------------
    //      MERGE ALL STATS
    // -------------------------------------------

    csv_sim      = CONCAT_SIMSTATS.out.csv.map{ meta, csv -> csv }
    csv_seqstats = CONCAT_SEQSTATS.out.csv.map{ meta, csv -> csv }

    csvs_stats = csv_sim.mix(csv_seqstats).collect().map{ csvs -> [[id:"summary_stats"], csvs] }
    csvs_stats.view()
    MERGE_STATS(csvs_stats)
    stats_summary = MERGE_STATS.out.csv
    ch_versions = ch_versions.mix(MERGE_STATS.out.versions)                      

    emit:
    stats_summary                             
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}