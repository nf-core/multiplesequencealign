//
// Compute stats about the input sequences
//

include {   COMPUTE_TREES       } from '../../subworkflows/local/compute_tree.nf'


workflow ALIGN {
    take:
    ch_fastas                //      channel: meta, /path/to/file.fasta
    ch_tools

    main:

    ch_versions = Channel.empty()

    // Separae the tools into two channels
    ch_tools_split = ch_tools.multiMap{ it -> 
                          tree: it[0]
                          align: it[1]
                      }

    // Compute the required trees
    COMPUTE_TREES(ch_fastas, ch_tools_split.tree)
    trees = COMPUTE_TREES.out.trees
    ch_versions = ch_versions.mix(COMPUTE_TREES.out.versions.first())

    
    // Align the sequences
    ch_tools.view()
    ch_tools_split.align.view()


    //msa = ALIGN_WITH_TREE.out.msa.mix(ALIGN_WITHOUT_TREE.out.msas)



    emit:
    //msa                             // TODO
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


