include { FOLDMASON_CREATEDB       } from '../../modules/nf-core/foldmason/createdb/main'
include { FOLDMASON_MSA2LDDTREPORT } from '../../modules/nf-core/foldmason/msa2lddtreport/main'

workflow VISUALIZATION {

    take:
    ch_msa           // channel: [ meta, /path/to/file.* ]
    ch_trees         // channel: [ meta, /path/to/file.* ]
    ch_optional_data // channel: [ meta, /path/to/file.* ]

    main:

    ch_versions = Channel.empty()
    ch_html     = Channel.empty()


    // Merge the msa and tree
    // split the msa meta to be able to merge with the tree meta
    ch_msa
        .map {
            meta, file -> [ meta.subMap([ "id", "tree", "args_tree", "args_tree_clean" ]), meta, file ]
        }
        .join(ch_trees, by: [0], remainder:true )
        .filter {
            it.size() == 4
        }
        .map {
            tree_meta, meta, msa, tree -> [ meta.subMap(["id"]), meta, msa, tree ]
        }
        .combine(ch_optional_data, by: [0])
        .set { ch_msa_tree_data }

    //
    // FOLDMASON VISUALISATION
    //

    FOLDMASON_CREATEDB(
        ch_optional_data
    )
    ch_versions = ch_versions.mix(FOLDMASON_CREATEDB.out.versions)

    ch_msa_tree_data
        .combine(FOLDMASON_CREATEDB.out.db.collect(), by:0)
        .multiMap{
            id, meta, msafile, treefile, pdb, dbfiles ->
            msa:  [ meta, msafile ]
            db:   [ id  , dbfiles ]
            pdbs: [ id  , pdb ]
            tree: [ meta, treefile == null ? [ ] : treefile ]
        }.set {
            ch_msa_db_tree
        }

    FOLDMASON_MSA2LDDTREPORT(
        ch_msa_db_tree.msa,
        ch_msa_db_tree.db,
        ch_msa_db_tree.pdbs,
        [ [:], [] ]
    )

    ch_versions = ch_versions.mix(FOLDMASON_MSA2LDDTREPORT.out.versions)
    ch_html     = FOLDMASON_MSA2LDDTREPORT.out.html

    emit:
    html     =  ch_html
    versions = ch_versions

}
