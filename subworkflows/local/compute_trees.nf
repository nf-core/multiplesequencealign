 
include { FAMSA_GUIDETREE } from '../../modules/nf-core/famsa/guidetree/main'
include { CLUSTALO_GUIDETREE } from '../../modules/nf-core/clustalo/guidetree/main'

 
 workflow COMPUTE_TREES {

    take:
    ch_fastas               //channel: [ meta, /path/to/file.fasta ]
    tree_tools              //channel: [ meta ] ( tools to be run: meta.tree, meta.args_tree )
     
    main:
    ch_versions = Channel.empty()

    // 
    // Render the required guide trees  
    //

   // Branch each guide tree rendering into a separate channel
   ch_fastas_fortrees = ch_fastas.combine(tree_tools)
                                 .map( it -> [it[0] + it[2], it[1]] )
                                 .branch{
                                          famsa_guidetree: it[0]["tree"] ==  "FAMSA_GUIDETREE"
                                          mbed: it[0]["tree"] == "MBED"
                                        }

      
    FAMSA_GUIDETREE(ch_fastas_fortrees.famsa_guidetree)
    ch_trees = FAMSA_GUIDETREE.out.tree
    ch_versions = ch_versions.mix(FAMSA_GUIDETREE.out.versions.first())


    CLUSTALO_GUIDETREE(ch_fastas_fortrees.mbed)
    ch_trees = ch_trees.mix(CLUSTALO_GUIDETREE.out.tree)
    ch_versions = ch_versions.mix(CLUSTALO_GUIDETREE.out.versions.first())


    emit:
    trees            = ch_trees                  // channel: [ val(meta), path(tree) ]             
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

 }
 
 
 
