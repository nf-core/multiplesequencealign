
include { TCOFFEE_ALNCOMPARE_EVAL } from '../../modules/local/tcoffee_alncompare_eval.nf'
include { TCOFFEE_IRMSD_EVAL      } from '../../modules/local/tcoffee_irmsd_eval.nf'
include { MERGE_EVALUATIONS_REPORT } from '../../modules/local/merge_evaluations_report.nf'


workflow EVALUATE {

    take: 
    ch_msa
    ch_references
    ch_structures

    main:

    ch_versions = Channel.empty()



    // 
    // Reference based evaluation
    //  
    alignment_and_ref = ch_references
                            .cross (ch_msa)
                            .map { it -> [ it[0][0]+it[1][1], it[1][2], it[0][1] ] }

    TCOFFEE_ALNCOMPARE_EVAL(alignment_and_ref)
    tcoffee_alncompare_scores = TCOFFEE_ALNCOMPARE_EVAL.out.scores
    ch_versions = ch_versions.mix(TCOFFEE_ALNCOMPARE_EVAL.out.versions.first())

    // 
    // Structure based evaluation
    //  
    alignment_and_ref_and_structures = alignment_and_ref
                                        .map { it -> [ it[0]["family"], it[0], it[1], it[2] ] }
                                        .combine(ch_structures.map { it -> [ it[0]["family"], it[1] ] }, by: 0)
                                        .map { it -> [ it[1], it[2], it[3], it[4] ] }

    TCOFFEE_IRMSD_EVAL(alignment_and_ref_and_structures)
    tcoffee_irmsd_scores = TCOFFEE_IRMSD_EVAL.out.scores
    ch_versions = ch_versions.mix(TCOFFEE_IRMSD_EVAL.out.versions.first())
    
    // 
    // Summarize evaluation summaries into one summary file
    //  
    tcoffee_alncompare_scores_summary = tcoffee_alncompare_scores.map{ it ->  "${it[1].text}" }
                                                            .collectFile( name: 'tcoffee_alncompare_scores_summary.csv',
                                                                          keepHeader : true,
                                                                          skip:1,                                         
                                                                          newLine: false)  

    tcoffee_irmsd_scores_summary = tcoffee_irmsd_scores.map{ it ->  "${it[1].text}" }
                                                        .collectFile( name: 'tcoffee_irmsd_scores_summary.csv',
                                                                      keepHeader : true,
                                                                      skip:1,                                         
                                                                      newLine: false)                                  

    MERGE_EVALUATIONS_REPORT( tcoffee_alncompare_scores_summary,
                              tcoffee_irmsd_scores_summary )
    ch_versions = ch_versions.mix(MERGE_EVALUATIONS_REPORT.out.versions.first())



    emit:
    tcoffee_alncompare_scores  
    tcoffee_irmsd_scores       
    versions                    = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

}