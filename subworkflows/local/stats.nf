//
// Compute stats about the input sequences
//
include {   CALCULATE_SEQSTATS                             } from '../../modules/local/calculate_seqstats.nf'
include {   PARSE_SIM                                      } from '../../modules/local/parse_sim.nf'
include {   TCOFFEE_SEQREFORMAT as TCOFFEE_SEQREFORMAT_SIM } from '../../modules/nf-core/tcoffee/seqreformat/main.nf'
include {   CSVTK_CONCAT  as CONCAT_SEQSTATS               } from '../../modules/nf-core/csvtk/concat/main.nf'
include {   CSVTK_CONCAT  as CONCAT_SIMSTATS               } from '../../modules/nf-core/csvtk/concat/main.nf'
include {   CSVTK_CONCAT  as CONCAT_PLDDTS                 } from '../../modules/nf-core/csvtk/concat/main.nf'
include {   CSVTK_JOIN    as MERGE_STATS                   } from '../../modules/nf-core/csvtk/join/main.nf'
include {   EXTRACT_PLDDT                                  } from '../../modules/local/extract_plddt.nf'

workflow STATS {
    take:
    ch_seqs       // channel: [ val(meta), path(/path/to/file.fasta) ]
    ch_dependencies // channel: [ val(meta), path(/path/to/dependencies_dir) ]

    main:

    ch_versions      = Channel.empty()
    sim_csv          = Channel.empty()
    seqstats_csv     = Channel.empty()
    plddts_csv       = Channel.empty()
    ch_stats_summary = Channel.empty()

    // -------------------------------------------
    //      SEQUENCE SIMILARITY
    // -------------------------------------------
    if( params.calc_sim){
        TCOFFEE_SEQREFORMAT_SIM (ch_seqs)
        tcoffee_seqreformat_sim = TCOFFEE_SEQREFORMAT_SIM.out.formatted_file
        ch_versions = ch_versions.mix(TCOFFEE_SEQREFORMAT_SIM.out.versions.first())
        PARSE_SIM (tcoffee_seqreformat_sim)
        tcoffee_seqreformat_simtot = PARSE_SIM.out.sim_tot
        ch_versions = ch_versions.mix(PARSE_SIM.out.versions)

        tcoffee_seqreformat_simtot
            .map {
                meta, csv ->
                    csv
            }
            .collect()
            .map {
                csv ->
                    [ [id:"summary_simstats"], csv ]
            }
            .set { ch_sim_summary }

        CONCAT_SIMSTATS (
            ch_sim_summary,
            "csv",
            "csv"
        )
        sim_csv = sim_csv.mix(CONCAT_SIMSTATS.out.csv)
        ch_versions = ch_versions.mix(CONCAT_SIMSTATS.out.versions)
    }

    // -------------------------------------------
    //      SEQUENCE GENERAL STATS
    //      Sequence length, # of sequences, etc
    // -------------------------------------------
    if (params.calc_seq_stats) {
        CALCULATE_SEQSTATS(ch_seqs)
        seqstats = CALCULATE_SEQSTATS.out.seqstats
        seqstats_summary = CALCULATE_SEQSTATS.out.seqstats_summary
        ch_versions = ch_versions.mix(CALCULATE_SEQSTATS.out.versions.first())

        seqstats_summary
            .map {
                meta, csv ->
                    csv
            }
            .collect()
            .map {
                csv ->
                    [ [id:"summary_seqstats"], csv ]
            }
            .set { ch_seqstats_summary }

        CONCAT_SEQSTATS (
            ch_seqstats_summary,
            "csv",
            "csv"
        )
        seqstats_csv = seqstats_csv.mix(CONCAT_SEQSTATS.out.csv)
        ch_versions = ch_versions.mix(CONCAT_SEQSTATS.out.versions)
    }

    // -------------------------------------------
    //      EXTRACT PLDDT
    // -------------------------------------------
    if (params.extract_plddt) {
        EXTRACT_PLDDT (ch_dependencies)
        ch_versions = ch_versions.mix(EXTRACT_PLDDT.out.versions)
        plddt_summary = EXTRACT_PLDDT.out.plddt_summary

        plddt_summary
            .map {
                meta, csv -> csv
            }
            .collect()
            .map {
                csv ->
                    [ [id:"summary_plddts"], csv ]
            }
            .set { ch_plddts_summary }

        CONCAT_PLDDTS (
            ch_plddts_summary,
            "csv",
            "csv"
        )
        plddts_csv = plddts_csv.mix(CONCAT_PLDDTS.out.csv)
        ch_versions = ch_versions.mix(CONCAT_PLDDTS.out.versions)
    }

    // -------------------------------------------
    //      MERGE ALL STATS
    // -------------------------------------------

    sim      = sim_csv.map      { meta, csv -> csv }
    seqstats = seqstats_csv.map { meta, csv -> csv }
    plddts   = plddts_csv.map   { meta, csv -> csv }

    sim
        .mix(seqstats)
        .mix(plddts)
        .collect()
        .map {
            csvs ->
                [ [id:"summary_stats"], csvs ]
        }
        .set { csvs_stats }

    def number_of_stats = [
        params.calc_sim,
        params.calc_seq_stats,
        params.extract_plddt
    ].count{ it == true }

    if (number_of_stats >= 2) {
        MERGE_STATS (csvs_stats)
        ch_versions = ch_versions.mix(MERGE_STATS.out.versions)
        ch_stats_summary = MERGE_STATS.out.csv
    } else if (number_of_stats == 1) {
        ch_stats_summary = csvs_stats
    }

    emit:
    stats_summary = ch_stats_summary // channel: [ path(summary.csv) ]
    versions      = ch_versions      // channel: [ versions.yml ]
}
