/*
 * Compute trees if needed and run alignment
 */

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
include {   MUSCLE5_SUPER5                    } from '../../modules/nf-core/muscle5/super5/main'
include {   TCOFFEE_ALIGN as REGRESSIVE_ALIGN } from '../../modules/nf-core/tcoffee/align/main'

workflow ALIGN {
    take:
    ch_fastas      //      channel: meta, /path/to/file.fasta
    ch_tools       //      string:
    ch_structures  //      channel: meta, [/path/to/file.pdb,/path/to/file.pdb,/path/to/file.pdb]

    main:

    ch_versions = Channel.empty()

    // Branch the toolsheet information into two channels
    // This way, it can direct the computation of guidetrees
    // and aligners separately
    ch_tools_split = ch_tools
                        .multiMap {
                            it ->
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
        .map {
            metafasta, fasta, metatree, metaalign ->
                [ metafasta+metatree , metaalign, fasta ]
        }
        .set { ch_fasta_tools }

    // ------------------------------------------------
    // Add back trees to the fasta channel
    // ------------------------------------------------
    ch_fasta_tools
        .join(trees, by: [0], remainder:true )
        .map {
            metafasta_tree, metaalign, fasta, tree ->
                [ metafasta_tree + metaalign, fasta, tree ]
        }
        .map {
            meta, fasta, tree ->
                tree ? [ meta,fasta, tree ] : [meta, fasta, [ ] ]
        }
        .branch {
            famsa:               it[0]["aligner"] == "FAMSA"
            tcoffee:             it[0]["aligner"] == "TCOFFEE"
            tcoffee3d:           it[0]["aligner"] == "3DCOFFEE"
            regressive:          it[0]["aligner"] == "REGRESSIVE"
            clustalo:            it[0]["aligner"] == "CLUSTALO"
            mafft:               it[0]["aligner"] == "MAFFT"
            kalign:              it[0]["aligner"] == "KALIGN"
            learnmsa:            it[0]["aligner"] == "LEARNMSA"
            muscle5:             it[0]["aligner"] == "MUSCLE5"
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
                                        tree:  [ meta, treefile ]
                                }
    CLUSTALO_ALIGN(ch_fasta_trees_clustalo.fasta, ch_fasta_trees_clustalo.tree)
    ch_versions = ch_versions.mix(CLUSTALO_ALIGN.out.versions.first())
    msa = CLUSTALO_ALIGN.out.alignment

    // -----------------   FAMSA ---------------------
    ch_fasta_trees_famsa = ch_fasta_trees.famsa
                                .multiMap{
                                    meta, fastafile, treefile ->
                                    fasta: [ meta, fastafile ]
                                    tree:  [ meta, treefile  ]
                                }

    FAMSA_ALIGN(ch_fasta_trees_famsa.fasta, ch_fasta_trees_famsa.tree)
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
    MAFFT(ch_fasta_mafft.fasta, [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ])
    ch_versions = ch_versions.mix(MAFFT.out.versions.first())

    // -----------------  TCOFFEE  ------------------
    ch_fasta_trees_tcoffee = ch_fasta_trees.tcoffee
                                .multiMap{
                                    meta, fastafile, treefile ->
                                        fasta: [ meta, fastafile ]
                                        tree: [ meta, treefile ]
                                }
    TCOFFEE_ALIGN(ch_fasta_trees_tcoffee.fasta, ch_fasta_trees_tcoffee.tree,  [ [:], [], [] ])
    ch_versions = ch_versions.mix(TCOFFEE_ALIGN.out.versions.first())
    msa = msa.mix(TCOFFEE_ALIGN.out.alignment)

    // -----------------  3DCOFFEE  ------------------
    ch_fasta_trees_3dcoffee = ch_fasta_trees.tcoffee3d.map{ meta, fasta, tree -> [meta["id"], meta, fasta, tree] }
                                .combine(ch_structures.map{ meta, template, structures -> [meta["id"], template, structures]}, by: 0)
                                .multiMap{
                                            merging_id, meta, fastafile, treefile, templatefile, structuresfiles ->
                                                fasta:      [ meta, fastafile       ]
                                                tree:       [ meta, treefile        ]
                                                structures: [ meta, templatefile, structuresfiles ]
                                }

    TCOFFEE3D_ALIGN(ch_fasta_trees_3dcoffee.fasta, ch_fasta_trees_3dcoffee.tree, ch_fasta_trees_3dcoffee.structures)
    ch_versions = ch_versions.mix(TCOFFEE3D_ALIGN.out.versions.first())
    msa = msa.mix(TCOFFEE3D_ALIGN.out.alignment)

    // -----------------  REGRESSIVE  ------------------
    ch_fasta_trees_regressive = ch_fasta_trees.regressive
                                .multiMap{
                                    meta, fastafile, treefile ->
                                        fasta: [ meta, fastafile ]
                                        tree:  [ meta, treefile ]
                                }
    REGRESSIVE_ALIGN(ch_fasta_trees_regressive.fasta, ch_fasta_trees_regressive.tree, [ [:],[], [] ])
    ch_versions = ch_versions.mix(REGRESSIVE_ALIGN.out.versions.first())
    msa = msa.mix(REGRESSIVE_ALIGN.out.alignment)


    // -----------------  MUSCLE5  ------------------
    ch_fasta_muscle5 = ch_fasta_trees.muscle5
                                .multiMap{
                                    meta, fastafile, treefile ->
                                        fasta: [ meta, fastafile ]
                                }
    MUSCLE5_SUPER5(ch_fasta_muscle5.fasta)
    ch_versions = ch_versions.mix(MUSCLE5_SUPER5.out.versions.first())
    msa = msa.mix(MUSCLE5_SUPER5.out.alignment.first())

    emit:
    msa
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}
