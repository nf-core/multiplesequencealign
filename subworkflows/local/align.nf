//
// Compute stats about the input sequences
//

include {   COMPUTE_TREES           } from '../../subworkflows/local/compute_trees.nf'
include {   FAMSA_ALIGN             } from '../../modules/nf-core/famsa/align/main'
include {   CLUSTALO_ALIGN          } from '../../modules/nf-core/clustalo/align/main'
include {   MAFFT                   } from '../../modules/nf-core/mafft/main'
include {   KALIGN_ALIGN            } from '../../modules/nf-core/kalign/align/main'
include {   TCOFFEE3D_TMALIGN_ALIGN } from '../../modules/local/tcoffee3D_tmalign_align.nf'
include {   TCOFFEEREGRESSIVE_ALIGN } from '../../modules/local/tcoffeeregressive_align.nf'



workflow ALIGN {
    take:
    ch_fastas                //      channel: meta, /path/to/file.fasta
    ch_tools
    ch_structures            //      channel: meta, [/path/to/file.pdb,/path/to/file.pdb,/path/to/file.pdb]

    main:

    ch_versions = Channel.empty()

    // Separae the tools into two channels
    ch_tools_split = ch_tools
                        .multiMap{ it -> 
                          tree: it[0]
                          align: it[1]
                        }

    // ------------------------------------------------
    // Compute the required trees
    // ------------------------------------------------
    COMPUTE_TREES(ch_fastas, ch_tools_split.tree)
    trees = COMPUTE_TREES.out.trees
    ch_versions = ch_versions.mix(COMPUTE_TREES.out.versions)


    // Separate the computation intothose which need a tree and those which don't
    ch_fastas.combine(ch_tools)
        .map{ it -> [it[0] + it[2] ,  it[3], it[1]] }
        .branch {
            with_tree: it[0]["tree"] != "none"
            without_tree: it[0]["tree"] == "none"
        }
        .set { ch_fasta_tools }


    // Here is all the combinations we need to compute
    ch_fasta_tools
        .with_tree
        .combine(trees, by: [0])
        .map { it -> [it[0] + it[1] , it[2], it[3]]} 
        .branch {
            famsa: it[0]["align"] == "FAMSA"
            tcoffee3D_tmalign: it[0]["align"] == "tcoffee3D_tmalign"
            tcoffee_regressive: it[0]["align"] == "regressive"
            clustalo: it[0]["align"] == "CLUSTALO"
        }
        .set { ch_fasta_trees }

    //    
    // Compute the alignments
    // 

    // -----------------   FAMSA ---------------------
    ch_fasta_trees_famsa = ch_fasta_trees.famsa
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree: [ meta, treefile ]
                                }
    FAMSA_ALIGN(ch_fasta_trees_famsa.fasta, ch_fasta_trees_famsa.tree)
    ch_versions = ch_versions.mix(FAMSA_ALIGN.out.versions.first())
    msa = FAMSA_ALIGN.out.alignment


    // -----------------  CLUSTALO ------------------
    ch_fasta_trees_clustalo = ch_fasta_trees.clustalo
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree: [ meta, treefile ]
                                }
    CLUSTALO_ALIGN(ch_fasta_trees_clustalo.fasta, ch_fasta_trees_clustalo.tree)
    ch_versions = ch_versions.mix(CLUSTALO_ALIGN.out.versions.first())
    msa = msa.mix(CLUSTALO_ALIGN.out.alignment)



 

    // // TCOFFEE REGRESSIVE
    // TCOFFEEREGRESSIVE_ALIGN(ch_fasta_trees.tcoffee_regressive)
    // ch_versions = ch_versions.mix(TCOFFEEREGRESSIVE_ALIGN.out.versions.first())
    // msa = msa.mix(TCOFFEEREGRESSIVE_ALIGN.out.msa)


    // // 3DCOFFE TMALIGN
    // // First collect the structures
    // input_tcoffee3dtmalign = ch_fasta_trees.tcoffee3D_tmalign
    //                                        .map{ it -> [it[0]["id"], it[0],it[1], it[2]] }
    //                                        .combine(ch_structures.map{ it -> [it[0]["id"], it[1]]}, by: 0 )
    //                                        .map{ it -> [it[1], it[2], it[3], it[4]] }


    // TCOFFEE3D_TMALIGN_ALIGN(input_tcoffee3dtmalign)
    // ch_versions = ch_versions.mix(TCOFFEE3D_TMALIGN_ALIGN.out.versions.first())
    // msa = msa.mix(TCOFFEE3D_TMALIGN_ALIGN.out.msa)

    ch_fasta_notrees = ch_fasta_tools.without_tree
                            .map{ it -> [it[0] + it[1] , it[2]]}
                            .branch{
                                mafft: it[0]["align"] == "MAFFT"
                                kalign: it[0]["align"] == "KALIGN"
                            }

    // ---------------- MAFFT -----------------------
    ch_fasta_mafft = ch_fasta_notrees.mafft
                                .multiMap{
                                    meta, fastafile ->
                                    fasta: [ meta, fastafile ]
                                }
    MAFFT(ch_fasta_mafft.fasta, [])
    ch_versions = ch_versions.mix(MAFFT.out.versions.first())


    // ---------------- KALIGN  -----------------------
    ch_fasta_kalign = ch_fasta_notrees.kalign
                                .multiMap{
                                    meta, fastafile ->
                                    fasta: [ meta, fastafile ]
                                }
    KALIGN_ALIGN(ch_fasta_kalign.fasta)
    ch_versions = ch_versions.mix(KALIGN_ALIGN.out.versions.first())




    emit:
    msa                             
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


