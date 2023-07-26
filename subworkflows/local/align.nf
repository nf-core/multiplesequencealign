//
// Compute stats about the input sequences
//

include {   COMPUTE_TREES       } from '../../subworkflows/local/compute_tree.nf'
include {   FAMSA_ALIGN            } from '../../modules/local/alignment.nf'

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

    
    // Here is all the combinations we need to compute
    ch_fasta_trees = ch_fastas.combine(ch_tools)
                              .map{ it -> [it[0] , it[2], it[3], it[1]] }
                              .combine(trees, by: [0,1])
                              .branch{
                                  famsa: it[2]["align"] == "FAMSA"
                              }


    // Compute the alignments
    ch_fasta_trees.famsa.view()
    FAMSA_ALIGN(ch_fasta_trees.famsa)
    //ch_versions = ch_versions.mix(FAMSA.out.versions.first())
    //msa = FAMSA.out.msa



    emit:
    //msa                             
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


