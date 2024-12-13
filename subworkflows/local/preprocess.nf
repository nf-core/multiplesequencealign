
include { TCOFFEE_EXTRACTFROMPDB } from '../../modules/nf-core/tcoffee/extractfrompdb/main'

workflow PREPROCESS {
    take:
    ch_optional_data          //channel: [ meta, [file1, ] ]

    main:
    
    ch_versions = Channel.empty()
    ch_preprocessed_data = Channel.empty()

    if(params.templates_suffix == ".pdb"){
        // If the optional data is a pdb file, we can preprocess them to make
        // them compatible with all the alignment tools
        TCOFFEE_EXTRACTFROMPDB(ch_optional_data.transpose())
        TCOFFEE_EXTRACTFROMPDB.out.formatted_pdb
            .groupTuple()
            .set { ch_preprocessed_data }
        ch_versions = ch_versions.mix(TCOFFEE_EXTRACTFROMPDB.out.versions)
    }

    emit: 
    preprocessed_optionaldata = ch_preprocessed_data 
    versions = ch_versions

}