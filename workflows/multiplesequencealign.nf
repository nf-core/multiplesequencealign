/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_multiplesequencealign_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Local subworkflows
//
include { STATS                  } from '../subworkflows/local/STATS'
include { ALIGN                  } from '../subworkflows/local/ALIGN'
include { EVALUATE               } from '../subworkflows/local/EVALUATE'
include { TEMPLATES              } from '../subworkflows/local/TEMPLATES'
include { PREPROCESS             } from '../subworkflows/local/PREPROCESS'
include { VISUALIZATION          } from '../subworkflows/local/VISUALIZATION'


//
// MODULE: local modules
//
include { PREPARE_MULTIQC    } from '../modules/local/custom/prepare_multiqc'
include { PREPARE_SHINY      } from '../modules/local/custom/prepare_shiny'
include { CUSTOM_PDBSTOFASTA } from '../modules/local/custom/pdbtofasta'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { UNTAR                          } from '../modules/nf-core/untar/main'
include { CSVTK_JOIN as MERGE_STATS_EVAL } from '../modules/nf-core/csvtk/join/main.nf'
include { PIGZ_COMPRESS                  } from '../modules/nf-core/pigz/compress/main'
include { FASTAVALIDATOR                 } from '../modules/nf-core/fastavalidator/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow MULTIPLESEQUENCEALIGN {

    take:
    ch_input    // channel: [ meta, path(sequence.fasta), path(reference.fasta), path(dependency_files.tar.gz), path(templates.txt) ]
    ch_tools    // channel: [ val(guide_tree_tool), val(args_guide_tree_tool), val(alignment_tool), val(args_alignment_tool) ]

    main:
    ch_multiqc_files                = Channel.empty()
    ch_multiqc_report               = Channel.empty()
    evaluation_summary              = Channel.empty()
    stats_summary                   = Channel.empty()
    stats_and_evaluation_summary    = Channel.empty()
    ch_refs                         = Channel.empty()
    ch_templates                    = Channel.empty()
    ch_optional_data                = Channel.empty()
    ch_versions                     = Channel.empty()


    ch_input
        .filter { it[1].size() > 0}
        .map {
            meta, fasta, ref, str, template ->
                [ meta, file(fasta) ]
        }
        .set { ch_seqs }

    ch_input
        .filter { it[2].size() > 0}
        .map {
            meta, fasta, ref, str, template ->
                [ meta, file(ref) ]
        }
        .set { ch_refs }

    ch_input
        .filter { it[4].size() > 0}
        .map {
            meta, fasta, ref, str, template ->
                [ meta, file(template) ]
        }
        .set { ch_templates }

    // ----------------
    // DEPENDENCY FILES
    // ----------------

    /*
    * We currently support 2 ways of reading in the optional_data:
    * 1. Provide a folder containing the optional_data via the `pdbs_dir` parameter
    * 2. Provide the dependency files directly in the input samplesheet
    */




    // If the optional_data folder is provided, use it to identify the optional_data based on sequence IDs
    if(params.pdbs_dir){

        // *****************************************
        // Get the structures into a channel.
        // If the folder is compressed, decompress 
        // *****************************************
        if(params.pdbs_dir.endsWith('.tar.gz')){

            pdbs_dir = Channel.fromPath(params.pdbs_dir)
                                        .map { it -> [[id: it.baseName],it] }

            UNTAR (pdbs_dir)
                .untar
                .map { meta, dir -> [ file(dir).listFiles() ] }
                .flatten()
                .set{ optional_data_to_be_mapped }
            ch_versions = ch_versions.mix(UNTAR.out.versions)

        }
        // otherwise, directly use the optional_data within the folder
        else {
            optional_data_to_be_mapped = Channel.fromPath(params.pdbs_dir+"/**")
        }



        // ******************************************************************
        // If the sequences are not provided, extract the fasta from the pdb
        // otherwise, map the optional_data to the sequence IDs provided by the 
        // various fasta files
        // *****************************************************************
        if(!params.seqs){
            optional_data_to_be_mapped
                .map { it -> [ [ id: params.pdbs_dir.split("/")[-1].split("\\.")[0] ], it ] }
                .groupTuple(by: 0)
                .set { ch_optional_data }
            if(!params.skip_pdbconversion){
                CUSTOM_PDBSTOFASTA(ch_optional_data)
                ch_versions = ch_versions.mix(CUSTOM_PDBSTOFASTA.out.versions)
                ch_seqs = CUSTOM_PDBSTOFASTA.out.fasta
            }


        }else{
            
            // Identify the sequence IDs from the input fasta file(s)
            ch_seqs.splitFasta(record: [ id: true ] )
                .map { id, seq_id -> [ seq_id, id ] }
                .set { ch_seqs_split }

            // Map the optional_data to the sequence IDs
            optional_data_to_be_mapped
                .map { it -> [ [ id: it.baseName ], it ] }
                .combine(ch_seqs_split, by: 0)
                .map { dep_id, dep, fasta_id -> [ fasta_id, dep ] }
                .groupTuple(by: 0)
                .set { ch_optional_data }
        }

    } else {

        // otherwise, use the dependency files provided in the input samplesheet
        ch_input
            .map {
                meta, fasta, ref, str, template ->
                    [ meta, str ]
            }
            .filter { it[1].size() > 0 }
            .set { ch_optional_data }

        // Dependency files are taken from a directory.
        // If the directory is compressed, it is uncompressed first.
        ch_optional_data
            .branch {
                compressed:   it[1].endsWith('.tar.gz')
                uncompressed: true
            }
            .set { ch_optional_data }

        UNTAR (ch_optional_data.compressed)
            .untar
            .mix(ch_optional_data.uncompressed)
            .map {
                meta,dir ->
                    [ meta,file(dir).listFiles().collect() ]
            }
            .set { ch_optional_data }
        ch_versions   = ch_versions.mix(UNTAR.out.versions)
    }

    //
    // VALIDATE AND PREPROCESS INPUT FILES
    //
    if (!params.skip_validation) {
        FASTAVALIDATOR(ch_seqs)
        ch_versions = ch_versions.mix(FASTAVALIDATOR.out.versions)
    }

    if (!params.skip_preprocessing) {
        PREPROCESS(ch_optional_data)
        ch_optional_data = PREPROCESS.out.preprocessed_optionaldata
        ch_versions      = ch_versions.mix(PREPROCESS.out.versions)
    }


    //
    // TEMPLATES
    //


    // Templates are currenlty needed only if 3DCOFFEE is used 
    // This may change in the future
    ch_optional_data
        .combine(ch_tools)
        .filter { it[3]["aligner"] == "3DCOFFEE" }
        .map { it -> [ it[0], it[1] ]}
        .first()
        .set { ch_optional_data_3dcoffee }

    // For the one needing the template, create the template or use the provided one
    ch_optional_data_template = Channel.empty()
    TEMPLATES (
        ch_optional_data_3dcoffee,
        ch_templates,
        "${params.templates_suffix}"
    )
    ch_optional_data_template = TEMPLATES.out.optional_data_template  

    // If the TEMPLATE is not needed, detect that TEMPLATE was not run and use the old optional_data to
    // proceed with the pipeline 
    // If 3DCOFFEE was called, the last element is a templata (the filte on -1) and therefore we understand
    // that the template was run and the channel remains empty ( ch_optional_data_notemplate )
    ch_optional_data
        .join(ch_optional_data_template, by: 0, remainder:true)
        .filter {
            it[-1] == null
        }
        .map {
            it -> [ it[0], [], it[1] ]
        }
        .set{ ch_optional_data_no_template }

    ch_optional_data_template = ch_optional_data_template.mix(ch_optional_data_no_template)

    //
    // Compute summary statistics about the input sequences
    //
    if (!params.skip_stats) {
        STATS (
            ch_seqs,
            ch_optional_data
        )
        ch_versions   = ch_versions.mix(STATS.out.versions)
        stats_summary = stats_summary.mix(STATS.out.stats_summary)
    }

    //
    // Align
    //
    compress_during_align = !(params.skip_compression || (!params.skip_eval || params.build_consensus))
    ALIGN (
        ch_seqs,
        ch_tools,
        ch_optional_data_template,
        compress_during_align
    )
    ch_versions = ch_versions.mix(ALIGN.out.versions)

    if (!params.skip_compression && !compress_during_align) {
        PIGZ_COMPRESS (ALIGN.out.msa)
        ch_versions = ch_versions.mix(PIGZ_COMPRESS.out.versions)
    }

    //
    // Evaluate the quality of the alignment
    //
    if (!params.skip_eval) {
        EVALUATE (ALIGN.out.msa, ch_refs, ch_optional_data_template)
        ch_versions        = ch_versions.mix(EVALUATE.out.versions)
        evaluation_summary = evaluation_summary.mix(EVALUATE.out.eval_summary)
    }

    //
    // Combine stats and evaluation reports into a single CSV
    //
    if (!params.skip_stats || !params.skip_eval) {
        stats_summary_csv = stats_summary.map{ meta, csv -> csv }
        eval_summary_csv  = evaluation_summary.map{ meta, csv -> csv }
        stats_summary_csv.mix(eval_summary_csv)
                        .collect()
                        .map {
                            csvs ->
                                [ [ id:"summary_stats_eval" ], csvs ]
                        }
                        .set { stats_and_evaluation }
        MERGE_STATS_EVAL (stats_and_evaluation)
        stats_and_evaluation_summary = MERGE_STATS_EVAL.out.csv
        ch_versions                  = ch_versions.mix(MERGE_STATS_EVAL.out.versions)
    }

    //
    // MODULE: Shiny
    //
    if (!params.skip_shiny) {
        shiny_app = Channel.fromPath(params.shiny_app)
        PREPARE_SHINY (stats_and_evaluation_summary, shiny_app)
        ch_versions = ch_versions.mix(PREPARE_SHINY.out.versions)
    }


    if (!params.skip_visualisation) {
        VISUALIZATION (
            ALIGN.out.msa,
            ALIGN.out.trees,
            ch_optional_data
        )
    }

    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'multiplesequencealign_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }
    
    
    if (!params.skip_multiqc){
        //
        // MODULE: MultiQC
        //
        ch_multiqc_config        = Channel.fromPath(
            "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config = params.multiqc_config ?
            Channel.fromPath(params.multiqc_config, checkIfExists: true) :
            Channel.empty()
        ch_multiqc_logo          = params.multiqc_logo ?
            Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
            Channel.empty()

        summary_params                        = paramsSummaryMap(
            workflow, parameters_schema: "nextflow_schema.json")
        ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
        ch_multiqc_files                      = ch_multiqc_files.mix(
            ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
            file(params.multiqc_methods_description, checkIfExists: true) :
            file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
        ch_methods_description                = Channel.value(
            methodsDescriptionText(ch_multiqc_custom_methods_description))

        ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
        ch_multiqc_files = ch_multiqc_files.mix(
            ch_methods_description.collectFile(
                name: 'methods_description_mqc.yaml',
                sort: true
            )
        )

        PREPARE_MULTIQC (stats_and_evaluation_summary)
        ch_multiqc_files                      = ch_multiqc_files.mix(PREPARE_MULTIQC.out.multiqc_table.collect{it[1]}.ifEmpty([]))

        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            [],
            []
        )
        ch_multiqc_report = MULTIQC.out.report.toList()
    }


    emit:
    multiqc_report = ch_multiqc_report                   // channel: /path/to/multiqc_report.html
    summary        = stats_and_evaluation_summary
    versions       = ch_collated_versions               // channel: [ path(versions.yml) ]

}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


