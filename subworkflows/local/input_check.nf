//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { TOOLSHEET_CHECK } from '../../modules/local/toolsheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv
    toolsheet  // file: /path/to/toolsheet.csv

    main:

    ch_versions = Channel.empty()

    samplesheet_ch = SAMPLESHEET_CHECK ( samplesheet)
                    .csv
                    .splitCsv ( header:true, sep:',' )

    fasta = samplesheet_ch.map { create_fasta_channel(it) }
    references = samplesheet_ch.map { create_references_channel(it) }
    structures = samplesheet_ch.map { create_structures_channel(it) }.unique() 
    ch_versions = ch_versions.mix(SAMPLESHEET_CHECK.out.versions)


    TOOLSHEET_CHECK ( toolsheet )
            .csv
            .splitCsv ( header:true, sep:',' )
            .map { create_tools_channel(it) }
            .set { tools }
    ch_versions = ch_versions.mix(TOOLSHEET_CHECK.out.versions)

    emit:
    fasta
    references
    structures
    tools                                     // channel: [ val(meta), [ fasta ] ]
    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}


// Function to get list of [ meta, [ fasta ] ]
def create_fasta_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.id

    // add path(s) of the fastq file(s) to the meta map
    def fasta_meta = []

    if (!file(row.fasta).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> fasta file does not exist!\n${row.fasta}"
    }
    fasta_meta = [ meta, [ file(row.fasta) ] ]

    return fasta_meta
}


// Function to get list of [ meta, [ fasta ] ]
def create_references_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.id

    // add path(s) of the fastq file(s) to the meta map
    def ref_meta = []
    ref_meta = [ meta, [ file(row.reference) ] ]

    return ref_meta
}

import groovy.io.FileType

// Function to get list of [ meta, [ fasta ] ]
def create_structures_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.id


    // add path(s) of the fastq file(s) to the meta map
    if (row.structures != "none") {
        def list = []
        def dir = new File(row.structures)
        dir.eachFileRecurse (FileType.FILES) { it ->
            list << file(it)
        }
        structures = [ meta, list ]
    }
    return structures
}

def create_tools_channel(LinkedHashMap row) {
    // create meta map
    def meta_tree = [:]
    def meta_align = [:]

    meta_tree.tree         = row.tree
    meta_tree.args_tree    = row.args_tree
    meta_tree.argstree_clean = row.argstree_clean
    meta_align.align        = row.align
    meta_align.args_align   = row.args_align
    meta_align.argsalign_clean = row.argsalign_clean

    // add path(s) of the fastq file(s) to the meta map
    def tools_meta = []
    tools_meta = [ meta_tree, meta_align ]

    return tools_meta
}
