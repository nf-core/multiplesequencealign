
include { ADD_PDBHEADER } from '../../modules/local/add_pdbheader.nf'

workflow PREPROCESS_OPTIONALDATA {
    take:
    ch_optional_data          //channel: [ meta, [file1, ] ]

    main:
    
    ch_versions = Channel.empty()
    ch_preprocessed_data = Channel.empty()

    if(params.templates_suffix == ".pdb"){
        // If the optional data is a pdb file, we can preprocess them to make
        // them compatible with all the alignment tools
        ADD_PDBHEADER(ch_optional_data.transpose())
        ADD_PDBHEADER.out.pdb
            .groupTuple()
            .set { ch_preprocessed_data }
    }

    emit: 
    preprocessed_optionaldata = ch_preprocessed_data 
    versions = ch_versions

}