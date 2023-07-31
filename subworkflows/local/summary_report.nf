
include { MERGE_EVALUATIONS_REPORT } from '../../modules/local/merge_evaluations_report.nf'

workflow SUMMARY_REPORT {
    take:
    tcoffee_alncompare_scores
    tcoffee_irmsd_scores                
   

    main:

    ch_versions = Channel.empty()

    tcoffee_alncompare_scores_summary = tcoffee_alncompare_scores.map{ it ->  "${it[1].text}" }
                                                            .collectFile( name : "scores.txt",
                                                                          keepHeader : true,
                                                                          skip:1,                                         
                                                                          newLine: false, 
                                                                          storeDir: "/home/luisasantus/Desktop/")  

    tcoffee_irmsd_scores_summary = tcoffee_irmsd_scores.map{ it ->  "${it[1].text}" }
                                                        .collectFile( name: "irmsd.txt",
                                                                      keepHeader : true,
                                                                      skip:1,                                         
                                                                      newLine: false, 
                                                                      storeDir: "/home/luisasantus/Desktop/")                                  

    MERGE_EVALUATIONS_REPORT( tcoffee_alncompare_scores_summary,
                              tcoffee_irmsd_scores_summary )


    emit:
    //csv              = SUMMARY_CSV.out.csv              
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


