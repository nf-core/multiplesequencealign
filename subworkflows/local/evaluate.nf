
include { TCOFFEE_ALNCOMPARE_EVAL } from '../../modules/local/evaluation.nf'

workflow EVALUATE_MSA {

    take: 
    ch_msa
    ch_references

    main:

    ch_versions = Channel.empty()

    alignment_and_ref = ch_references
                            .cross (ch_msa)
                            .map { it -> [ it[0][0]+it[1][1], it[1][2], it[0][1] ] }

    alignment_and_ref.view()
    TCOFFEE_ALNCOMPARE_EVAL(alignment_and_ref)

    emit:
    eval_tcoffee_standard   = TCOFFEE_ALNCOMPARE_EVAL.out.scores
    versions                = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

}