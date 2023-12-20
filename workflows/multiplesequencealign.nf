/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowMultiplesequencealign.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STATS                       } from '../subworkflows/local/stats'
include { ALIGN                       } from '../subworkflows/local/align'
include { EVALUATE                    } from '../subworkflows/local/evaluate'
include { CREATE_TCOFFEETEMPLATE      } from '../modules/local/create_tcoffee_template' 
include { MULTIQC         } from '../modules/local/multiqc'
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

include { FASTQC                                 } from '../modules/nf-core/fastqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS            } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { UNTAR                                  } from '../modules/nf-core/untar/main'
include { ZIP                                    } from '../modules/nf-core/zip/main'
include { CSVTK_JOIN    as MERGE_STATS_EVAL      } from '../modules/nf-core/csvtk/join/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow MULTIPLESEQUENCEALIGN {

    ch_versions = Channel.empty()

    //
    // Prepare input and metadata
    //
    ch_input = Channel.fromSamplesheet('input')
    ch_tools = Channel.fromSamplesheet('tools').map {
                        meta ->
                        def meta_clone = meta[0].clone()
                        def treeMap = [:]
                        def alignMap = [:]

                        treeMap["tree"] = meta_clone["tree"]
                        treeMap["args_tree"] = meta_clone["args_tree"]
                        treeMap["args_tree_clean"] = WorkflowMultiplesequencealign.cleanArgs(meta_clone.args_tree)

                        alignMap["aligner"] = meta_clone["aligner"]
                        alignMap["args_aligner"] = WorkflowMultiplesequencealign.check_required_args(meta_clone["aligner"], meta_clone["args_aligner"])
                        alignMap["args_aligner_clean"] = WorkflowMultiplesequencealign.cleanArgs(alignMap["args_aligner"])
                        
                        [ treeMap, alignMap ]
                    }

    ch_seqs       = ch_input.map{ meta,fasta,ref,str,template -> [ meta, file(fasta)    ]}
    ch_refs       = ch_input.filter{ it[2].size() > 0}.map{ meta,fasta,ref,str,template -> [ meta, file(ref)      ]}
    ch_templates  = ch_input.filter{ it[4].size() > 0}.map{ meta,fasta,ref,str,template -> [ meta, file(template) ]}
    ch_structures = ch_input.map{ meta,fasta,ref,str,template -> [ meta, str            ]}.filter{ it[1].size() > 0 }
    
    // ----------------
    // STRUCTURES 
    // ----------------
    // Structures are taken from a directory of PDB files.
    // If the directory is compressed, it is uncompressed first.
    ch_structures.branch {
        compressed:   it[1].endsWith('.tar.gz')
        uncompressed: true
    }.set { ch_structures }

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
    ch_structures_template.branch{
                                    template: it[2] != null
                                    no_template: true
                            }.set { ch_structures_branched }

    // Create the new templates and merge them with the existing templates
    CREATE_TCOFFEETEMPLATE(ch_structures_branched.no_template
                                                        .map{ 
                                                            meta,structures,template 
                                                                            -> [ meta, structures ] 
                                                            })
    new_templates = CREATE_TCOFFEETEMPLATE.out.template
    forced_templates = ch_structures_branched.template
                                                .map{ 
                                                    meta,structures,template 
                                                                        -> [ meta, template ] 
                                                }
    ch_templates_merged = forced_templates.mix( new_templates)

    // Merge the structures and templates channels, ready for the alignment
    ch_structures_template = ch_templates_merged.combine(ch_structures, by:0)

    // Compute summary statistics about the input sequences
    //
    if( !params.skip_stats ){
        STATS(ch_seqs)
        ch_versions = ch_versions.mix(STATS.out.versions)
    }
    

    //
    // Align
    //
    ALIGN(ch_seqs, ch_tools, ch_structures_template )
    ch_versions = ch_versions.mix(ALIGN.out.versions)


    //
    // Evaluate the quality of the alignment
    //
    if( !params.skip_eval ){
        EVALUATE(ALIGN.out.msa, ch_refs, ch_structures_template)
        ch_versions = ch_versions.mix(EVALUATE.out.versions)
    }


    stats_summary_csv = STATS.out.stats_summary.map{ meta, csv -> csv }
    eval_summary_csv  = EVALUATE.out.eval_summary.map{ meta, csv -> csv }
    stats_and_evaluation = eval_summary_csv.mix(stats_summary_csv).collect().map{ csvs -> [[id:"summary_stats_eval"], csvs] }
    MERGE_STATS_EVAL(stats_and_evaluation)
    ch_versions = ch_versions.mix(MERGE_STATS_EVAL.out.versions)


    // STATS for MultiQC
    MULTIQC_PREP_TABLE(MERGE_STATS_EVAL.out.csv)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: zip
    //
    if( !params.skip_compress ){
        ZIP(ALIGN.out.msa)
        ch_versions = ch_versions.mix(ZIP.out.versions)
    }

    //
    // MODULE: MultiQC
    //
    if (!params.skip_multiqc) {

    workflow_summary    = WorkflowMultiplesequencealign.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowMultiplesequencealign.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        PREPARE_MULTIQC.out.multiqc_table.collect{it[1]}.ifEmpty([]),
        STATS.out.seqstats.collect{it[1]}.ifEmpty([])
    )
    multiqc_report = MULTIQC.out.report.toList()

    }
    if( !params.skip_shiny){
        PREP_SHINY ( MERGE_STATS_EVAL.out.csv, file(params.shiny_app) )
    }
    
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
