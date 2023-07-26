 
include { PARTTREE } from '../../modules/local/parttree'
include { MBEDTREE } from '../../modules/local/mbedtree'

 
 workflow COMPUTE_TREES {

    take:
    ch_fastas               //channel: meta, /path/to/file.fasta
    tree_tools              //channel: meta ( tools to be run: meta.tree, meta.args_tree )
     
    main:
    ch_versions = Channel.empty()

    // 
    // Render the required guide trees  
    //


   // Branch each guide tree rendering into a separate channel
   ch_fastas_fortrees = ch_fastas.combine(tree_tools)
                                 .map( it -> [it[0], it[2], it[1]] )
                                 .branch{
                                          parttree: it[1]["tree"] ==  "PARTTREE"
                                          mbed: it[1]["tree"] == "MBED"
                                        }


    PARTTREE(ch_fastas_fortrees.parttree)
    ch_trees = PARTTREE.out.tree

    MBEDTREE(ch_fastas_fortrees.mbed)
    ch_trees = ch_trees.mix(MBEDTREE.out.tree)


    emit:
    trees            = ch_trees                               
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

 }
 
 
 
