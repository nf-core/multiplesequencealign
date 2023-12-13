

include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_SP    } from '../../modules/nf-core/tcoffee/alncompare' 
include { TCOFFEE_ALNCOMPARE as TCOFFEE_ALNCOMPARE_TC    } from '../../modules/nf-core/tcoffee/alncompare'                                                                                                                                 
include { TCOFFEE_IRMSD                                  } from '../../modules/nf-core/tcoffee/irmsd'
include { CSVTK_CONCAT  as CONCAT_SP                     } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_TC                     } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_CONCAT  as CONCAT_IRMSD                  } from '../../modules/nf-core/csvtk/concat/main.nf'
include { CSVTK_JOIN    as MERGE_EVAL                    } from '../../modules/nf-core/csvtk/join/main.nf'
include { PARSE_IRMSD                                    } from '../../modules/local/parse_irmsd.nf'         

workflow EVALUATE {

    take: 
    ch_msa
    ch_references
    ch_structures

    main:

    ch_versions = Channel.empty()


    // -------------------------------------------
    // Reference based evaluation
    // -------------------------------------------
    alignment_and_ref = ch_references.map { meta,ref -> [ meta.id, ref ] }
                            .cross (ch_msa.map { meta, aln -> [ meta.id, meta, aln ] })
                            .map { chref, chaln -> [ chaln[1], chaln[2], chref[1]  ] }

    TCOFFEE_ALNCOMPARE_SP(alignment_and_ref)
    sp_scores = TCOFFEE_ALNCOMPARE_SP.out.scores
    ch_versions = ch_versions.mix(TCOFFEE_ALNCOMPARE_SP.out.versions.first())

    ch_sp_summary = sp_scores.map{ 
                                            meta, csv -> csv
                                        }.collect().map{
                                            csv -> [ [id_simstats:"summary_sp"], csv]
                                        }
    CONCAT_SP(ch_sp_summary, "csv", "csv")


    TCOFFEE_ALNCOMPARE_TC(alignment_and_ref)
    tc_scores = TCOFFEE_ALNCOMPARE_TC.out.scores
    ch_versions = ch_versions.mix(TCOFFEE_ALNCOMPARE_TC.out.versions.first())

    ch_tc_summary = tc_scores.map{ 
                                            meta, csv -> csv
                                        }.collect().map{
                                            csv -> [ [id_simstats:"summary_tc"], csv]
                                        }
    CONCAT_TC(ch_tc_summary, "csv", "csv")



    // -------------------------------------------
    // Structure based evaluation
    // -------------------------------------------
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
                                                csv -> [ [id_simstats:"summary_irmsd"], csv]
                                            }
    CONCAT_IRMSD(ch_irmsd_summary, "csv", "csv")
    

    // -------------------------------------------
    //      MERGE ALL STATS
    // -------------------------------------------

    csv_sp      = CONCAT_SP.out.csv.map{ meta, csv -> csv }
    csv_tc      = CONCAT_TC.out.csv.map{ meta, csv -> csv }
    csv_irmsd   = CONCAT_IRMSD.out.csv.map{ meta, csv -> csv }

    csvs_stats = csv_sp.mix(csv_tc).mix(csv_irmsd).collect().map{ csvs -> [[id:"summary_eval"], csvs] }
    MERGE_EVAL(csvs_stats)
    stats_summary = MERGE_EVAL.out.csv
    ch_versions = ch_versions.mix(MERGE_EVAL.out.versions)    


    emit:
    stats_summary      
    versions                    = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

}