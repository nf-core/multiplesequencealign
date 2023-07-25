//
// Compute stats about the input sequences
//

include {   ALIGN_WITH_TREE       } from '../../subworkflows/local/align_with_tree.nf'


workflow ALIGN {
    take:
    ch_seqs                //      channel: meta, /path/to/file.fasta
    ch_tools

    main:

    ch_versions = Channel.empty()

    // Merge all the files and tools to compute all combinations
    ch_seqs_tools = ch_seqs.combine(ch_tools)
                           .map( it -> [it[0]+it[2], it[1]] )
                           .branch{
                                    with_tree: it[0]["tree"] !=  "none"
                                    without_tree: it[0]["tree"] == "none"
                                  }

    ch_seqs_tools.without_tree.view()
    // Here i need to branch in 
    //msa = ALIGN_WITH_TREE(ch_seqs_tools.with_tree)
    //ch_versions = ch_versions.mix(ALIGN_WITH_TREE.out.versions.first())
    //ALIGN_WITHOUT_TREE(ch_seqs_tools.without_tree)
    //msa = ALIGN_WITH_TREE.out.msa.mix(ALIGN_WITHOUT_TREE.out.msas)



    emit:
    //msa                             // TODO
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


