/*
 * Compute trees if needed and run alignment
 */

//
// Include the subworkflows
//
include { COMPUTE_TREES                     } from '../../subworkflows/local/compute_trees.nf'

// Include the nf-core modules
include { CLUSTALO_ALIGN                    } from '../../modules/nf-core/clustalo/align/main'
include { FAMSA_ALIGN                       } from '../../modules/nf-core/famsa/align/main'
include { FOLDMASON_EASYMSA                 } from '../../modules/nf-core/foldmason/easymsa/main'
include { KALIGN_ALIGN                      } from '../../modules/nf-core/kalign/align/main'
include { LEARNMSA_ALIGN                    } from '../../modules/nf-core/learnmsa/align/main'
include { MAFFT                             } from '../../modules/nf-core/mafft/main'
include { MAGUS_ALIGN                       } from '../../modules/nf-core/magus/align/main'
include { MTMALIGN_ALIGN                    } from '../../modules/nf-core/mtmalign/align/main'
include { MUSCLE5_SUPER5                    } from '../../modules/nf-core/muscle5/super5/main'
include { TCOFFEE_ALIGN                     } from '../../modules/nf-core/tcoffee/align/main'
include { TCOFFEE_ALIGN as TCOFFEE3D_ALIGN  } from '../../modules/nf-core/tcoffee/align/main'
include { TCOFFEE_REGRESSIVE                } from '../../modules/nf-core/tcoffee/regressive/main'
include { TCOFFEE_CONSENSUS as CONSENSUS    } from '../../modules/nf-core/tcoffee/consensus/main'
include { UPP_ALIGN                         } from '../../modules/nf-core/upp/align/main'

workflow ALIGN {
    take:
    ch_fastas     // channel: [ val(meta), [ path(fastas) ] ]
    ch_tools      // channel: [ val(meta_tree), val(meta_aligner) ]
                    // [[tree:<tree>, args_tree:<args_tree>, args_tree_clean: <args_tree_clean>], [aligner:<aligner>, args_aligner:<args_aligner>, args_aligner_clean:<args_aligner_clean>]]
                    // e.g.[[tree:FAMSA, args_tree:-gt upgma -parttree, args_tree_clean:-gt_upgma_-parttree], [aligner:FAMSA, args_aligner:null, args_aligner_clean:null]]
                    // e.g.[[tree:null, args_tree:null, args_tree_clean:null], [aligner:TCOFFEE, args_aligner:-output fasta_aln, args_aligner_clean:-output_fasta_aln]]
    ch_dependencies // channel: meta, [e.g. /path/to/file.pdb,/path/to/file.pdb,/path/to/file.pdb]
    compress      // boolean: true or false

    main:

    ch_msa      = Channel.empty()
    ch_versions = Channel.empty()

    // Branch the toolsheet information into two channels
    // This way, it can direct the computation of guidetrees
    // and aligners separately
    ch_tools
        .multiMap {
            it ->
                tree: it[0]
                align: it[1]
        }
        .set { ch_tools_split }

    // ------------------------------------------------
    // Compute the required trees
    // ------------------------------------------------
    COMPUTE_TREES (
        ch_fastas,
        ch_tools_split.tree.unique()
    )
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
            clustalo:   it[0]["aligner"] == "CLUSTALO"
            famsa:      it[0]["aligner"] == "FAMSA"
            kalign:     it[0]["aligner"] == "KALIGN"
            learnmsa:   it[0]["aligner"] == "LEARNMSA"
            mafft:      it[0]["aligner"] == "MAFFT"
            magus:      it[0]["aligner"] == "MAGUS"
            muscle5:    it[0]["aligner"] == "MUSCLE5"
            mtmalign:   it[0]["aligner"] == "MTMALIGN"
            regressive: it[0]["aligner"] == "REGRESSIVE"
            tcoffee:    it[0]["aligner"] == "TCOFFEE"
            tcoffee3d:  it[0]["aligner"] == "3DCOFFEE"
            upp:        it[0]["aligner"] == "UPP"
        }
        .set { ch_fasta_trees }

    ch_dependencies.combine(ch_tools)
        .map {
            metadependency, template, dependency, metatree, metaalign ->
                [ metadependency+metatree+metaalign, template, dependency ]
        }
        .branch {
            mtmalign: it[0]["aligner"] == "MTMALIGN"
            foldmason: it[0]["aligner"] == "FOLDMASON"
        }
        .set { ch_dependencies_tools }

    // ------------------------------------------------
    // Compute the alignments
    // ------------------------------------------------

    // 1. SEQUENCE BASED
    // -----------------  CLUSTALO ------------------
    ch_fasta_trees.clustalo
        .multiMap {
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
                tree:  [ meta, treefile  ]
        }
        .set { ch_fasta_trees_clustalo }

    CLUSTALO_ALIGN (
        ch_fasta_trees_clustalo.fasta,
        ch_fasta_trees_clustalo.tree,
        compress
    )
    ch_msa = ch_msa.mix(CLUSTALO_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(CLUSTALO_ALIGN.out.versions.first())

    // -----------------   FAMSA ---------------------
    ch_fasta_trees.famsa
        .multiMap {
            meta, fastafile, treefile ->
            fasta: [ meta, fastafile ]
            tree:  [ meta, treefile  ]
        }
        .set { ch_fasta_trees_famsa}

    FAMSA_ALIGN (ch_fasta_trees_famsa.fasta,
        ch_fasta_trees_famsa.tree,
        compress
    )
    ch_msa = ch_msa.mix(FAMSA_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(FAMSA_ALIGN.out.versions.first())

    // ---------------- KALIGN  -----------------------
    ch_fasta_trees.kalign
        .multiMap {
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
        }
        .set { ch_fasta_kalign }

    KALIGN_ALIGN (
        ch_fasta_kalign.fasta,
        compress
    )
    ch_msa = ch_msa.mix(KALIGN_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(KALIGN_ALIGN.out.versions.first())

    // ---------------- LEARNMSA  ----------------------
    ch_fasta_trees.learnmsa
        .multiMap {
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
        }
        .set { ch_fasta_learnmsa }

    LEARNMSA_ALIGN (
        ch_fasta_learnmsa.fasta,
        compress
    )
    ch_msa = ch_msa.mix(LEARNMSA_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(LEARNMSA_ALIGN.out.versions.first())

    // ---------------- MAFFT -----------------------
    ch_fasta_trees.mafft
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
        }
        .set { ch_fasta_mafft }

    MAFFT (
        ch_fasta_mafft.fasta,
        [ [:], [] ],
        [ [:], [] ],
        [ [:], [] ],
        [ [:], [] ],
        [ [:], [] ],
        compress
    )
    ch_msa = ch_msa.mix(MAFFT.out.fas) // the MAFFT module calls its output fas instead of alignment
    ch_versions = ch_versions.mix(MAFFT.out.versions.first())

    // ----------------- MAGUS ------------------
    ch_fasta_trees.magus
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
                tree:  [ meta, treefile ]
        }
        .set { ch_fasta_trees_magus }

    MAGUS_ALIGN (
        ch_fasta_trees_magus.fasta,
        ch_fasta_trees_magus.tree,
        compress
    )
    ch_msa = ch_msa.mix(MAGUS_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(MAGUS_ALIGN.out.versions.first())

    // -----------------  MUSCLE5  ------------------
    ch_fasta_trees.muscle5
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
        }
        .set { ch_fasta_muscle5 }

    MUSCLE5_SUPER5 (
        ch_fasta_muscle5.fasta,
        compress
    )
    ch_msa = ch_msa.mix(MUSCLE5_SUPER5.out.alignment.first())
    ch_versions = ch_versions.mix(MUSCLE5_SUPER5.out.versions.first())

    // -----------------  TCOFFEE  ------------------
    ch_fasta_trees.tcoffee
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
                tree:  [ meta, treefile  ]
        }
        .set { ch_fasta_trees_tcoffee }

    TCOFFEE_ALIGN (
        ch_fasta_trees_tcoffee.fasta,
        ch_fasta_trees_tcoffee.tree,
        [ [:], [], [] ],
        compress
    )
    ch_msa = ch_msa.mix(TCOFFEE_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(TCOFFEE_ALIGN.out.versions.first())

    // -----------------  REGRESSIVE  ------------------
    ch_fasta_trees.regressive
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
                tree:  [ meta, treefile  ]
        }
        .set { ch_fasta_trees_regressive }

    TCOFFEE_REGRESSIVE (
        ch_fasta_trees_regressive.fasta,
        ch_fasta_trees_regressive.tree,
        [ [:], [], [] ],
        compress
    )
    ch_msa = ch_msa.mix(TCOFFEE_REGRESSIVE.out.alignment)
    ch_versions = ch_versions.mix(TCOFFEE_REGRESSIVE.out.versions.first())

    // -----------------  UPP  -------------------
    ch_fasta_trees.upp
        .multiMap{
            meta, fastafile, treefile ->
                fasta: [ meta, fastafile ]
                tree:  [ meta, treefile  ]
        }
        .set { ch_fasta_trees_upp }

    UPP_ALIGN (
        ch_fasta_trees_upp.fasta,
        ch_fasta_trees_upp.tree,
        compress
    )
    ch_msa = ch_msa.mix(UPP_ALIGN.out.alignment)
    ch_versions = ch_versions.mix(UPP_ALIGN.out.versions.first())

    // 2. SEQUENCE + STRUCTURE BASED

    if(params.templates_suffix == ".pdb"){
        // -----------------  3DCOFFEE  ------------------
        ch_fasta_trees.tcoffee3d
            .map{ meta, fasta, tree -> [ meta["id"], meta, fasta, tree ] }
            .combine(ch_dependencies.map{ meta, template, dependencies -> [ meta["id"], template, dependencies ] }, by: 0)
            .multiMap{
                merging_id, meta, fastafile, treefile, templatefile, depencencyfiles ->
                fasta:      [ meta, fastafile ]
                tree:       [ meta, treefile  ]
                dependencies: [ meta, templatefile, depencencyfiles ]
            }
            .set { ch_fasta_trees_3dcoffee }

        TCOFFEE3D_ALIGN (
            ch_fasta_trees_3dcoffee.fasta,
            ch_fasta_trees_3dcoffee.tree,
            ch_fasta_trees_3dcoffee.dependencies,
            compress
        )
        ch_msa = ch_msa.mix(TCOFFEE3D_ALIGN.out.alignment)
        ch_versions = ch_versions.mix(TCOFFEE3D_ALIGN.out.versions.first())

        // 3. STRUCTURE BASED

        // -----------------  MTMALIGN  ------------------
        ch_dependencies_tools.mtmalign
            .multiMap {
                meta, template, dependency ->
                    pdbs: [ meta, dependency ]
            }
            .set { ch_pdb_mtmalign }

        MTMALIGN_ALIGN (
            ch_pdb_mtmalign.pdbs,
            compress
        )
        ch_msa = ch_msa.mix(MTMALIGN_ALIGN.out.alignment)
        ch_versions = ch_versions.mix(MTMALIGN_ALIGN.out.versions.first())

        ch_dependencies_tools.foldmason
            .multiMap {
                meta, template, dependency ->
                    pdbs: [ meta, dependency ]
            }
            .set { ch_pdb_foldmason }

        FOLDMASON_EASYMSA (
            ch_pdb_foldmason.pdbs,
            compress
        )
        ch_msa = ch_msa.mix(FOLDMASON_EASYMSA.out.msa_aa)
        ch_versions = ch_versions.mix(FOLDMASON_EASYMSA.out.versions.first())
    }

    // -----------------  CONSENSUS  ------------------
    if(params.build_consensus){
        ch_msa.map{ meta, msa -> [ meta["id"], msa]}
            .groupTuple()
            .map{ id_meta, msas -> [ ["id": id_meta, "tree":"", "args_tree":"", "args_tree_clean":null, "aligner":"CONSENSUS", "args_aligner":"", "args_aligner_clean":null ], msas ]}
            .set{ ch_msa_consensus }

        CONSENSUS(ch_msa_consensus, [[:],[]], compress)
        ch_msa = ch_msa.mix(CONSENSUS.out.alignment)
        ch_versions = ch_versions.mix(CONSENSUS.out.versions.first())
    }


    emit:
    msa      = ch_msa      // channel: [ val(meta), path(msa) ]
    versions = ch_versions // channel: [ versions.yml ]
}
