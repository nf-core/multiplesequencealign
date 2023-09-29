// Incude the subworkflows
include {   COMPUTE_TREES                     } from '../../subworkflows/local/compute_trees.nf'

// Include the nf-core modules
include {   FAMSA_ALIGN                       } from '../../modules/nf-core/famsa/align/main'
include {   CLUSTALO_ALIGN                    } from '../../modules/nf-core/clustalo/align/main'
include {   MAFFT                             } from '../../modules/nf-core/mafft/main'
include {   KALIGN_ALIGN                      } from '../../modules/nf-core/kalign/align/main'
include {   LEARNMSA_ALIGN                    } from '../../modules/nf-core/learnmsa/align/main'
include {   TCOFFEE_ALIGN                     } from '../../modules/nf-core/tcoffee/align/main'
include {   TCOFFEE_ALIGN as TCOFFEE3D_ALIGN  } from '../../modules/nf-core/tcoffee/align/main'

// Include local modules
include {   CREATE_TCOFFEETEMPLATE            } from '../../modules/local/create_tcoffee_template' 
include {   MTMALIGN_ALIGN                    } from '../../modules/local/mtmalign_align'

workflow ALIGN {
    take:
    ch_fastas                //      channel: meta, /path/to/file.fasta
    ch_tools
    ch_structures            //      channel: meta, [/path/to/file.pdb,/path/to/file.pdb,/path/to/file.pdb]

    main:

    ch_versions = Channel.empty()

    // Branch the toolsheet information into two channels
    // This way, it can direct the computation of guidetrees
    // and aligners separately
    ch_tools_split = ch_tools
                        .multiMap{ it -> 
                          tree: it[0]
                          align: it[1]
                        }

    // ------------------------------------------------
    // Compute the required trees
    // ------------------------------------------------
    COMPUTE_TREES(ch_fastas, ch_tools_split.tree.unique())
    trees = COMPUTE_TREES.out.trees
    ch_versions = ch_versions.mix(COMPUTE_TREES.out.versions)

    ch_fastas.combine(ch_tools)
        .map{ it -> [it[0] + it[2] ,  it[3], it[1]] }
        .set { ch_fasta_tools }

    // ------------------------------------------------
    // Add back trees to the fasta channel
    // ------------------------------------------------
    ch_fasta_tools
        .join(trees, by: [0], remainder:true )
        .map { metafasta, metatree, fasta, tree -> [metafasta + metatree, fasta, tree]}
        .map { meta, fasta, tree ->  tree ? [meta,fasta, tree] : [meta, fasta, []] }
        .branch {
            famsa:               it[0]["aligner"] == "FAMSA"
            tcoffee:             it[0]["aligner"] == "TCOFFEE"
            tcoffee3d:           it[0]["aligner"] == "3DCOFFEE"
            clustalo:            it[0]["aligner"] == "CLUSTALO"
            mafft:               it[0]["aligner"] == "MAFFT"
            kalign:              it[0]["aligner"] == "KALIGN"
            learnmsa:            it[0]["aligner"] == "LEARNMSA"
            mtmalign:            it[0]["aligner"] == "MTMALIGN"
        }
        .set { ch_fasta_trees }

    // ------------------------------------------------   
    // Compute the alignments
    // ------------------------------------------------



    // -----------------  CLUSTALO ------------------
    ch_fasta_trees_clustalo = ch_fasta_trees.clustalo
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree: [ meta, treefile ]
                                }
    CLUSTALO_ALIGN(ch_fasta_trees_clustalo.fasta, ch_fasta_trees_clustalo.tree)
    ch_versions = ch_versions.mix(CLUSTALO_ALIGN.out.versions.first())
    msa = CLUSTALO_ALIGN.out.alignment

    // -----------------   FAMSA ---------------------
    ch_fasta_trees_famsa = ch_fasta_trees.famsa
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree: [ meta, treefile ]
                                }

    FAMSA_ALIGN(ch_fasta_trees_famsa.fasta, ch_fasta_trees_famsa.tree )
    ch_versions = ch_versions.mix(FAMSA_ALIGN.out.versions.first())
    msa = msa.mix(FAMSA_ALIGN.out.alignment)

    // ---------------- KALIGN  -----------------------
    ch_fasta_kalign = ch_fasta_trees.kalign
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                }
    KALIGN_ALIGN(ch_fasta_kalign.fasta)
    ch_versions = ch_versions.mix(KALIGN_ALIGN.out.versions.first())

    // ---------------- LEARNMSA  ----------------------
    ch_fasta_learnmsa = ch_fasta_trees.learnmsa
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                }
    LEARNMSA_ALIGN(ch_fasta_learnmsa.fasta)
    ch_versions = ch_versions.mix(LEARNMSA_ALIGN.out.versions.first())


    // ---------------- MAFFT -----------------------
    ch_fasta_mafft = ch_fasta_trees.mafft
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                }
    MAFFT(ch_fasta_mafft.fasta, [])
    ch_versions = ch_versions.mix(MAFFT.out.versions.first())


    // -----------------  TCOFFEE  ------------------
    ch_fasta_trees_tcoffee = ch_fasta_trees.tcoffee
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree: [ meta, treefile ]
                                }
    TCOFFEE_ALIGN(ch_fasta_trees_tcoffee.fasta, ch_fasta_trees_tcoffee.tree,  [[:],[], []])
    ch_versions = ch_versions.mix(TCOFFEE_ALIGN.out.versions.first())
    msa = msa.mix(TCOFFEE_ALIGN.out.msa)

    // -----------------  3DCOFFEE  ------------------ 
    ch_structures_and_template = CREATE_TCOFFEETEMPLATE(ch_structures).structure_and_template
    ch_fasta_trees_3dcoffee = ch_fasta_trees.tcoffee3d.map{ meta, fasta, tree -> [meta["id"], meta, fasta, tree] }
                                                   .combine(ch_structures_and_template.map{ meta, template, structures -> [meta["id"], template, structures]}, by: 0)
                                                   .multiMap{
                                                                merging_id, meta, fastafile, treefile, templatefile, structuresfiles ->
                                                                fasta:      [ meta, fastafile       ]
                                                                tree:       [ meta, treefile        ]
                                                                structures: [ meta, templatefile, structuresfiles ]
                                                            }
    TCOFFEE3D_ALIGN(ch_fasta_trees_3dcoffee.fasta, ch_fasta_trees_3dcoffee.tree, ch_fasta_trees_3dcoffee.structures)
    ch_versions = ch_versions.mix(TCOFFEE3D_ALIGN.out.versions.first())
    msa = msa.mix(TCOFFEE3D_ALIGN.out.msa)

    // -----------------  MTMALIGN  ------------------

    ch_fasta_mtmalign = ch_fasta_trees.mtmalign.map{ meta, fasta, tree -> [meta["id"], meta, fasta, tree] }
                                                    .combine(ch_structures.map{ meta, structures -> [meta["id"], structures]}, by: 0)   
                                                    .multiMap{merging_id, meta, fastafile, treefile, structuresfiles ->
                                                              fasta:      [ meta, fastafile       ]
                                                              structures: [ meta, structuresfiles ]
                                                             }
    MTMALIGN_ALIGN(ch_fasta_mtmalign.fasta, ch_fasta_mtmalign.structures)
    //ch_versions = ch_versions.mix(MTMALIGN_ALIGN.out.versions.first())
    msa = msa.mix(MTMALIGN_ALIGN.out.msa)

    emit:
    msa                             
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


