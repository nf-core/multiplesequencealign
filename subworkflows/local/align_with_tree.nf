 
 include { FAMSA_PARTTREE } from '../../modules/local/trees'
 
 workflow ALIGN_WITH_TREE {

    take:
    ch_seqs_and_tools               //      channel: meta, /path/to/file.fasta
    

    main:
    ch_versions = Channel.empty()
    ch_seqs_and_tools = ch_seqs_and_tools.branch{
        parttree: it[0]["tree"] ==  "PARTTREE"
        mbed: it[0]["tree"] == "MBED"
    }
    
    FAMSA_PARTTREE(ch_seqs_and_tools.parttree)


    emit:
    msa            = ALIGN_WITH_TREE.out.msa                  // TODO
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]

 }
 
 
 
