//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK; TOOLSHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    toolsheet  // file: /path/to/toolsheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet)
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fasta_channel(it) }
        .set { fasta }

    TOOLSHEET_CHECK ( toolsheet )
    .csv
    .splitCsv ( header:true, sep:',' )
    .map { create_tools_channel(it) }
    .set { tools }


    emit:
    fasta
    tools                                     // channel: [ val(meta), [ fasta ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


// Function to get list of [ meta, [ fasta ] ]
def create_fasta_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.family         = row.family

    // add path(s) of the fastq file(s) to the meta map
    def fasta_meta = []

    if (!file(row.fasta).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> fasta file does not exist!\n${row.fasta}"
    }
    fasta_meta = [ meta, [ file(row.fasta) ] ]

    return fasta_meta
}


def create_tools_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.tree         = row.tree
    meta.args_tree    = row.args_tree
    meta.align        = row.align
    meta.args_align   = row.args_align

    // add path(s) of the fastq file(s) to the meta map
    def tools_meta = []

    tools_meta = [ meta ]

    return tools_meta
}
