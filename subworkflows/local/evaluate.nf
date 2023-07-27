
include { TCOFFEE_ALNCOMPARE_EVAL } from '../../modules/local/tcoffee_alncompare_eval.nf'
include { TCOFFEE_IRMSD_EVAL      } from '../../modules/local/tcoffee_irmsd_eval.nf'

workflow EVALUATE {

    take: 
    ch_msa
    ch_references
    ch_structures

    main:

    ch_versions = Channel.empty()

    alignment_and_ref = ch_references
                            .cross (ch_msa)
                            .map { it -> [ it[0][0]+it[1][1], it[1][2], it[0][1] ] }

    TCOFFEE_ALNCOMPARE_EVAL(alignment_and_ref)

    // TODO make this cleaner - there is an issue open 
    alignment_and_ref_and_structures = alignment_and_ref
                                        .map { it -> [ it[0]["family"], it[0], it[1], it[2] ] }
                                        .combine(ch_structures.map { it -> [ it[0]["family"], it[1] ] }, by: 0)
                                        .map { it -> [ it[1], it[2], it[3], it[4] ] }

    alignment_and_ref_and_structures.view()
    TCOFFEE_IRMSD_EVAL(alignment_and_ref_and_structures)

    emit:
    eval_tcoffee_standard   = TCOFFEE_ALNCOMPARE_EVAL.out.scores
    versions                = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

}