/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                } from '../modules/local/multiqc'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_multiplesequencealign_pipeline'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo                       = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

ch_multiqc_table             = Channel.empty()
evaluation_summary           = Channel.empty()
stats_summary                = Channel.empty()
stats_and_evaluation_summary = Channel.empty()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Local subworkflows
//
include { STATS                  } from '../subworkflows/local/stats'
include { ALIGN                  } from '../subworkflows/local/align'
include { EVALUATE               } from '../subworkflows/local/evaluate'
include { CREATE_TCOFFEETEMPLATE } from '../modules/local/create_tcoffee_template'

//
// MODULE: local modules
//
include { PREPARE_MULTIQC } from '../modules/local/prepare_multiqc'
include { PREPARE_SHINY   } from '../modules/local/prepare_shiny'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

include { UNTAR                          } from '../modules/nf-core/untar/main'
include { ZIP                            } from '../modules/nf-core/zip/main'
include { CSVTK_JOIN as MERGE_STATS_EVAL } from '../modules/nf-core/csvtk/join/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow MULTIPLESEQUENCEALIGN {

    take:
    ch_input
    ch_tools

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    ch_input
        .map {
            meta, fasta, ref, str, template ->
                [ meta, file(fasta) ]
        }
        .set { ch_seqs }

    ch_input
        .filter { it[2].size() > 0}
        .map {
            meta,fasta,ref,str,template ->
                [ meta, file(ref) ]
        }
        .set { ch_refs }

    ch_input
        .filter { it[4].size() > 0}
        .map {
            meta,fasta,ref,str,template ->
                [ meta, file(template) ]
        }
        .set { ch_templates }

    ch_input
        .map {
            meta,fasta,ref,str,template ->
                [ meta, str ]
        }
        .filter { it[1].size() > 0 }
        .set { ch_structures }

    // ----------------
    // STRUCTURES
    // ----------------
    // Structures are taken from a directory of PDB files.
    // If the directory is compressed, it is uncompressed first.
    ch_structures
        .branch {
            compressed:   it[1].endsWith('.tar.gz')
            uncompressed: true
        }
        .set { ch_structures }

    UNTAR ( ch_structures.compressed )
        .untar
        .mix( ch_structures.uncompressed )
        .map {
            meta,dir ->
                [ meta,file(dir).listFiles().collect() ]
        }
        .set { ch_structures }


    // ----------------
    // TEMPLATES
    // ----------------
    // If a family does not present a template but structures are provided, create one.
    ch_structures_template = ch_structures.join(ch_templates, by:0, remainder:true)
    ch_structures_template
        .branch{
            template: it[2] != null
            no_template: true
        }
        .set { ch_structures_branched }

    // Create the new templates and merge them with the existing templates
    CREATE_TCOFFEETEMPLATE (
        ch_structures_branched.no_template
            .map {
                meta,structures,template
                    -> [ meta, structures ]
            }
    )
    new_templates = CREATE_TCOFFEETEMPLATE.out.template
    ch_structures_branched.template
        .map{
            meta,structures,template
                -> [ meta, template ]
        }
        .set { forced_templates }

    ch_templates_merged = forced_templates.mix(new_templates)

    // Merge the structures and templates channels, ready for the alignment
    ch_structures_template = ch_templates_merged.combine(ch_structures, by:0)

    //
    // Compute summary statistics about the input sequences
    //
    if( !params.skip_stats ){
        STATS(ch_seqs, ch_structures)
        ch_versions   = ch_versions.mix(STATS.out.versions)
        stats_summary = stats_summary.mix(STATS.out.stats_summary)
    }

    //
    // Align
    //
    ALIGN(ch_seqs, ch_tools, ch_structures_template)
    ch_versions = ch_versions.mix(ALIGN.out.versions)

    //
    // Evaluate the quality of the alignment
    //
    if( !params.skip_eval ){
        EVALUATE(ALIGN.out.msa, ch_refs, ch_structures_template)
        ch_versions        = ch_versions.mix(EVALUATE.out.versions)
        evaluation_summary = evaluation_summary.mix(EVALUATE.out.eval_summary)
    }

    //
    // Combine stats and evaluation reports into a single CSV
    //
    stats_summary_csv = stats_summary.map{ meta, csv -> csv }
    eval_summary_csv  = evaluation_summary.map{ meta, csv -> csv }
    eval_summary_csv
        .mix(stats_summary_csv)
        .collect()
        .map {
            csvs ->
                [ [ id:"summary_stats_eval" ], csvs ]
        }
        .set { stats_and_evaluation }

    if( !params.skip_stats && !params.skip_eval ){
        def number_of_stats = [params.calc_sim, params.calc_seq_stats].count(true)
        def number_of_evals = [params.calc_sp, params.calc_tc, params.calc_irmsd].count(true)
        if (number_of_evals > 0 && number_of_stats > 0 ){
            MERGE_STATS_EVAL(stats_and_evaluation)
            stats_and_evaluation_summary = MERGE_STATS_EVAL.out.csv
            ch_versions                  = ch_versions.mix(MERGE_STATS_EVAL.out.versions)
        }
    }else{
        stats_and_evaluation_summary = stats_and_evaluation
    }


    //
    // MODULE: zip
    //
    if( !params.skip_compress ){
        ZIP(ALIGN.out.msa)
        ch_versions = ch_versions.mix(ZIP.out.versions)
    }

    //
    // MODULE: Shiny
    //
    ch_shiny_stats = Channel.empty()
    if( !params.skip_shiny){
        PREPARE_SHINY ( stats_and_evaluation_summary, file(params.shiny_app) )
        ch_versions = ch_versions.mix(PREPARE_SHINY.out.versions)
        ch_shiny_stats = PREPARE_SHINY.out.data.toList()
    }

    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    multiqc_out = Channel.empty()
    if (!params.skip_multiqc){
        ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
        ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
        summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
        ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
        ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
        ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
        ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
        ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

        PREPARE_MULTIQC(stats_and_evaluation_summary)
        ch_multiqc_table = ch_multiqc_table.mix(PREPARE_MULTIQC.out.multiqc_table.collect{it[1]}.ifEmpty([]))

        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            ch_multiqc_table
        )
        multiqc_out = MULTIQC.out.report.toList()
    }

    emit:
    versions         = ch_versions // channel: [ path(versions.yml) ]
    multiqc          = multiqc_out
}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


