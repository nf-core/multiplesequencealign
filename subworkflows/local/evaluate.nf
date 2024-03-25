

include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_SP } from '../../modules/nf-core/tcoffee/alncompare'
include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_TC } from '../../modules/nf-core/tcoffee/alncompare'
include { TCOFFEE_IRMSD                               } from '../../modules/nf-core/tcoffee/irmsd'
include { CALC_GAPS                                   } from '../../modules/local/calculate_gaps'
include { CSVTK_CONCAT  as CONCAT_SP                  } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_TC                  } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_IRMSD               } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_GAPS                } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_TCS                 } from '../../modules/nf-core/csvtk/concat/main.nf'
include { TCOFFEE_TCS                                 } from '../../modules/nf-core/tcoffee/tcs'
include { CSVTK_JOIN    as MERGE_EVAL                 } from '../../modules/nf-core/csvtk/join/main.nf'
include { PARSE_IRMSD                                 } from '../../modules/local/parse_irmsd.nf'

workflow EVALUATE {

    take:
    ch_msa
    ch_references
    ch_structures

    main:

    ch_versions   = Channel.empty()
    sp_csv       = Channel.empty()
    tc_csv       = Channel.empty()
    irmsd_csv    = Channel.empty()
    tcs_csv      = Channel.empty()
    eval_summary = Channel.empty()


    // -------------------------------------------
    // Reference based evaluation
    // -------------------------------------------
    alignment_and_ref = ch_references.map { meta,ref -> [ meta.id, ref ] }
                            .cross (ch_msa.map { meta, aln -> [ meta.id, meta, aln ] })
                            .map { chref, chaln -> [ chaln[1], chaln[2], chref[1]  ] }


    // Sum of pairs
    if( params.calc_sp == true){
        TCOFFEE_ALNCOMPARE_SP(alignment_and_ref)
        sp_scores = TCOFFEE_ALNCOMPARE_SP.out.scores
        ch_versions = ch_versions.mix(TCOFFEE_ALNCOMPARE_SP.out.versions.first())

        ch_sp_summary = sp_scores.map{
                                                meta, csv -> csv
                                            }.collect().map{
                                                csv -> [ [id:"summary_sp"], csv]
                                            }
        CONCAT_SP(ch_sp_summary, "csv", "csv")
        sp_csv = CONCAT_SP.out.csv
        ch_versions = ch_versions.mix(CONCAT_SP.out.versions)
    }

    // Total column score
    if( params.calc_tc == true){
        TCOFFEE_ALNCOMPARE_TC(alignment_and_ref)
        tc_scores = TCOFFEE_ALNCOMPARE_TC.out.scores
        ch_versions = ch_versions.mix(TCOFFEE_ALNCOMPARE_TC.out.versions.first())

        ch_tc_summary = tc_scores.map{
                                                meta, csv -> csv
                                            }.collect().map{
                                                csv -> [ [id:"summary_tc"], csv]
                                            }
        CONCAT_TC(ch_tc_summary, "csv", "csv")
        tc_csv = CONCAT_TC.out.csv
        ch_versions = ch_versions.mix(CONCAT_TC.out.versions)
    }

    // number of gaps
    if (params.calc_gaps == true){
        CALC_GAPS(ch_msa)
        gaps_scores = CALC_GAPS.out.gaps
        ch_versions = ch_versions.mix(CALC_GAPS.out.versions)

        ch_gaps_summary = gaps_scores.map{
                                                meta, csv -> csv
                                            }.collect().map{
                                                csv -> [ [id:"summary_gaps"], csv]
                                            }
        CONCAT_GAPS(ch_gaps_summary, "csv", "csv")
        gaps_csv = CONCAT_GAPS.out.csv
        ch_versions = ch_versions.mix(CONCAT_GAPS.out.versions)
    }




    // -------------------------------------------
    // Structure based evaluation
    // -------------------------------------------

    // iRMSD
    if (params.calc_irmsd == true){
        msa_str = ch_structures.map { meta, template, str -> [ meta.id, template, str ] }
                            .cross (ch_msa.map { meta, aln -> [ meta.id, meta, aln ] })
                            .multiMap { chstr, chaln ->
                                        msa: [ chaln[1], chaln[2] ]
                                        structures: [ chstr[0], chstr[1], chstr[2]  ]
                                        }


        TCOFFEE_IRMSD(msa_str.msa, msa_str.structures)
        tcoffee_irmsd_scores = TCOFFEE_IRMSD.out.irmsd
        ch_versions = ch_versions.mix(TCOFFEE_IRMSD.out.versions.first())
        PARSE_IRMSD(tcoffee_irmsd_scores)
        tcoffee_irmsd_scores_tot = PARSE_IRMSD.out.irmsd_tot
        ch_versions = ch_versions.mix(PARSE_IRMSD.out.versions)

        ch_irmsd_summary = tcoffee_irmsd_scores_tot.map{
                                                    meta, csv -> csv
                                                }.collect().map{
                                                    csv -> [ [id:"summary_irmsd"], csv]
                                                }
        CONCAT_IRMSD(ch_irmsd_summary, "csv", "csv")
        irmsd_csv = CONCAT_IRMSD.out.csv
        versions = ch_versions.mix(CONCAT_IRMSD.out.versions)
    }


    // -------------------------------------------
    // intrinsic evaluation metrics
    // -------------------------------------------

    // TCS
    if( params.calc_tcs == true){
        // the second argument is empty but a lib file can be fed to it
        TCOFFEE_TCS(ch_msa, [[:], []])
        tcs_scores = TCOFFEE_TCS.out.scores
        ch_versions = ch_versions.mix(TCOFFEE_TCS.out.versions.first())

        ch_tcs_summary = tcs_scores.map{
                                                meta, csv -> csv
                                            }.collect().map{
                                                csv -> [ [id:"summary_tcs"], csv]
                                            }
        CONCAT_TCS(ch_tcs_summary, "csv", "csv")
        tcs_csv = CONCAT_TCS.out.csv
        ch_versions = ch_versions.mix(CONCAT_TCS.out.versions)

    }


    // -------------------------------------------
    //      MERGE ALL STATS
    // -------------------------------------------

    sp      = sp_csv.map{ meta, csv -> csv }
    tc      = tc_csv.map{ meta, csv -> csv }
    irmsd   = irmsd_csv.map{ meta, csv -> csv }
    gaps    = gaps_csv.map{ meta, csv -> csv }
    tcs     = tcs_csv.map{ meta, csv -> csv }

    def number_of_evals = [params.calc_sp, params.calc_tc, params.calc_irmsd, params.calc_gaps, params.calc_tcs].count(true)
    csvs_stats = sp.mix(tc).mix(irmsd).mix(gaps).mix(tcs).collect().map{ csvs -> [[id:"summary_eval"], csvs] }
    if(number_of_evals >= 2){
        MERGE_EVAL(csvs_stats)
        ch_versions = ch_versions.mix(MERGE_EVAL.out.versions)
        eval_summary = MERGE_EVAL.out.csv
    }else if(number_of_evals == 1){
        eval_summary = csvs_stats
    }




    emit:
    eval_summary
    versions                    = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

}
