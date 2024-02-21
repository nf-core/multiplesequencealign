

include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_SP } from '../../modules/nf-core/tcoffee/alncompare'
include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_TC } from '../../modules/nf-core/tcoffee/alncompare'
include { TCOFFEE_IRMSD                               } from '../../modules/nf-core/tcoffee/irmsd'
include { CSVTK_CONCAT  as CONCAT_SP                  } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_TC                  } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_IRMSD               } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_JOIN    as MERGE_EVAL                 } from '../../modules/nf-core/csvtk/join/main.nf'
include { PARSE_IRMSD                                 } from '../../modules/local/parse_irmsd.nf'

workflow EVALUATE {

    take:
    ch_msa
    ch_references
    ch_structures

    main:

    ch_versions = Channel.empty()
    sp_csv = Channel.empty()
    tc_csv = Channel.empty()
    irmsd_csv = Channel.empty()
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
        tcoffee_irmsd_scores_tot = PARSE_IRMSD(tcoffee_irmsd_scores)

        ch_irmsd_summary = tcoffee_irmsd_scores_tot.map{
                                                    meta, csv -> csv
                                                }.collect().map{
                                                    csv -> [ [id:"summary_irmsd"], csv]
                                                }
        CONCAT_IRMSD(ch_irmsd_summary, "csv", "csv")
        irmsd_csv = CONCAT_IRMSD.out.csv
    }


    // -------------------------------------------
    //      MERGE ALL STATS
    // -------------------------------------------

    sp      = sp_csv.map{ meta, csv -> csv }
    tc      = tc_csv.map{ meta, csv -> csv }
    irmsd   = irmsd_csv.map{ meta, csv -> csv }

    def number_of_evals = [params.calc_sp, params.calc_tc, params.calc_irmsd].count{ it == true }
    csvs_stats = sp.mix(tc).mix(irmsd).collect().map{ csvs -> [[id:"summary_eval"], csvs] }
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
