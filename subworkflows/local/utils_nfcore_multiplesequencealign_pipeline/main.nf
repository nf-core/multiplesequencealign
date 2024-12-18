//
// Subworkflow with functionality specific to the nf-core/multiplesequencealign pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification            } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //  array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    tools             //  string: Path to input tools samplesheet

    main:

    ch_versions = Channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    //
    // Create channel from input file provided through params.input
    //
    ch_input = Channel.fromList(samplesheetToList(params.input, "${projectDir}/assets/schema_input.json"))
    ch_tools = Channel.fromList(samplesheetToList(params.tools, "${projectDir}/assets/schema_tools.json"))
                .map {
                    meta ->
                        def meta_clone = meta[0].clone()
                        def tree_map = [:]
                        def align_map = [:]

                        tree_map["tree"] = Utils.clean_tree(meta_clone["tree"])
                        tree_map["args_tree"] = meta_clone["args_tree"]
                        tree_map["args_tree_clean"] = Utils.cleanArgs(meta_clone.args_tree)

                        align_map["aligner"] = meta_clone["aligner"]
                        align_map["args_aligner"] = Utils.check_required_args(meta_clone["aligner"], meta_clone["args_aligner"])
                        align_map["args_aligner_clean"] = Utils.cleanArgs(meta_clone.args_aligner)

                        [ tree_map, align_map ]
                }.unique()

    emit:
    samplesheet = ch_input
    tools       = ch_tools
    versions    = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {

    take:
    email            //  string: email address
    email_on_fail    //  string: email address sent on pipeline failure
    plaintext_email  // boolean: Send plain-text email instead of HTML
    outdir           //    path: Path to output directory where results will be published
    monochrome_logs  // boolean: Disable ANSI colour codes in log output
    hook_url         //  string: hook URL for notifications
    multiqc_report   //  string: Path to MultiQC report
    shiny_dir_path   //  string: Path to shiny stats file
    trace_dir_path   //  string: Path to trace file
    shiny_trace_mode // string: Mode to use for shiny trace file (default: "latest", options: "latest", "all")

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                multiqc_report.toList()
            )
        }

        completionSummary(monochrome_logs)
        if (hook_url) {
            imNotification(summary_params, hook_url)
        }

        def summary_file = "${outdir}/summary/complete_summary_stats_eval.csv"
        def summary_file_with_traces = "${outdir}/summary/complete_summary_stats_eval_times.csv"
        def trace_dir_path = "${outdir}/pipeline_info/"

        if (shiny_trace_mode) {
            merge_summary_and_traces(summary_file, trace_dir_path, summary_file_with_traces, "${shiny_dir_path}/complete_summary_stats_eval_times.csv")
        }else{
            merge_summary_and_traces(summary_file, trace_dir_path, summary_file_with_traces, "")
        }
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting"
    }
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Exit pipeline if incorrect --genome key provided
//
def genomeExistsError() {
    if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
        def error_string = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
            "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
            "  Currently, the available genome keys are:\n" +
            "  ${params.genomes.keySet().join(", ")}\n" +
            "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        error(error_string)
    }
}
//
// Generate methods description for MultiQC
//
def toolCitationText() {

    def citation_text = [
            "Tools used in the workflow included:",
            "3DCoffee (O'Sullivan et al., 2004)",
            "Biopython (Cock et al., 2009)",
            "Clustal Omega (Sievers et al., 2011)",
            "FAMSA (Deorowicz et al., 2016)",
            "FastQC (Andrews 2010),",
            "Foldmason (Gilchrist et al., 2024)",
            "Kalign 3 (Lassmann, 2019)",
            "learnMSA (Becker & Stanke, 2022)",
            "MAFFT (Katoh et al., 2002)",
            "MAGUS (Smirnov et al.,2021)",
            "mTM-align (Dong et al., 2018)",
            "MultiQC (Ewels et al., 2016)",
            "Muscle5 (Edgar, 2022)",
            "T-Coffee (Notredame et al., 2000)",
            "UPP (Park et al., 2023)"
        ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {

    def reference_text = [
        "<li>Andrews S, (2010) FastQC, URL: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).</li>",
        "<li>Becker F, Stanke M. learnMSA: learning and aligning large protein families. Gigascience. 2022 Nov 18;11:giac104. doi: 10.1093/gigascience/giac104. PMID: 36399060; PMCID: PMC9673500.</li>",
        "<li>Cock PJ, Antao T, Chang JT, Chapman BA, Cox CJ, Dalke A, Friedberg I, Hamelryck T, Kauff F, Wilczynski B, de Hoon MJ. Biopython: freely available Python tools for computational molecular biology and bioinformatics. Bioinformatics. 2009 Jun 1;25(11):1422-3. doi: 10.1093/bioinformatics/btp163. Epub 2009 Mar 20. PMID: 19304878; PMCID: PMC2682512.</li>",
        "<li>Deorowicz S, Debudaj-Grabysz A, Gudyś A. FAMSA: Fast and accurate multiple sequence alignment of huge protein families. Sci Rep. 2016 Sep 27;6:33964. doi: 10.1038/srep33964. PMID: 27670777; PMCID: PMC5037421.</li>",
        "<li>Dong R, Peng Z, Zhang Y, Yang J. mTM-align: an algorithm for fast and accurate multiple protein structure alignment. Bioinformatics. 2018 May 15;34(10):1719-1725. doi: 10.1093/bioinformatics/btx828. PMID: 29281009; PMCID: PMC5946935.</li>",
        "<li>Edgar RC. Muscle5: High-accuracy alignment ensembles enable unbiased assessments of sequence homology and phylogeny. Nat Commun. 2022 Nov 15;13(1):6968. doi: 10.1038/s41467-022-34630-w. PMID: 36379955; PMCID: PMC9664440.</li>",
        "<li>Ewels P, Magnusson M, Lundin S, Käller M. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics. 2016 Oct 1;32(19):3047-8. doi: 10.1093/bioinformatics/btw354. Epub 2016 Jun 16. PubMed PMID: 27312411; PubMed Central PMCID: PMC5039924.</li>",
        "<li>Cameron L.M. Gilchrist, Milot Mirdita, Martin Steinegger. bioRxiv 2024.08.01.606130; doi: https://doi.org/10.1101/2024.08.01.606130.</li>",
        "<li>Katoh K, Misawa K, Kuma K, Miyata T. MAFFT: a novel method for rapid multiple sequence alignment based on fast Fourier transform. Nucleic Acids Res. 2002 Jul 15;30(14):3059-66. doi: 10.1093/nar/gkf436. PMID: 12136088; PMCID: PMC135756.</li>",
        "<li>Smirnov V, Warnow T. MAGUS: Multiple sequence Alignment using Graph clUStering. Bioinformatics. 2021 Jul 19;37(12):1666-1672. doi: 10.1093/bioinformatics/btaa992. PMID: 33252662; PMCID: PMC8289385.</li>",
        "<li>Lassmann T. Kalign 3: multiple sequence alignment of large data sets. Bioinformatics. 2019 Oct 26;36(6):1928–9. doi: 10.1093/bioinformatics/btz795. Epub ahead of print. PMID: 31665271; PMCID: PMC7703769.</li>",
        "<li>Notredame C, Higgins DG, Heringa J. T-Coffee: A novel method for fast and accurate multiple sequence alignment. J Mol Biol. 2000 Sep 8;302(1):205-17. doi: 10.1006/jmbi.2000.4042. PMID: 10964570.</li>",
        "<li>O'Sullivan O, Suhre K, Abergel C, Higgins DG, Notredame C. 3DCoffee: combining protein sequences and structures within multiple sequence alignments. J Mol Biol. 2004 Jul 2;340(2):385-95. doi: 10.1016/j.jmb.2004.04.058. PMID: 15201059.</li>",
        "<li>Park M, Ivanovic S, Chu G, Shen C, Warnow T. UPP2: fast and accurate alignment of datasets with fragmentary sequences. Bioinformatics. 2023 Jan 1;39(1):btad007. doi: 10.1093/bioinformatics/btad007. PMID: 36625535; PMCID: PMC9846425.</li>",
        "<li>Sievers F, Wilm A, Dineen D, Gibson TJ, Karplus K, Li W, Lopez R, McWilliam H, Remmert M, Söding J, Thompson JD, Higgins DG. Fast, scalable generation of high-quality protein multiple sequence alignments using Clustal Omega. Mol Syst Biol. 2011 Oct 11;7:539. doi: 10.1038/msb.2011.75. PMID: 21988835; PMCID: PMC3261699.</li>"
    ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    } else meta["doi_text"] = ""
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = ""
    meta["tool_bibliography"] = ""

    meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine =  new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}



import groovy.transform.Field

/**
 * Parses a CSV file and returns a list of maps representing the rows.
 *
 * @param csvContent The content of the CSV file as a string.
 * @return A list of maps where each map represents a row in the CSV.
 */
def parseCsv(csvContent) {
    def lines = csvContent.split('\n')
    def headers = lines[0].split(',')
    def data = []

    lines.drop(1).each { line ->
        def values = line.split(',')
        def row = [:]
        headers.eachWithIndex { header, index ->
            row[header] = values[index]
        }
        data << row
    }

    return data
}
/**
 * Saves a list of maps to a CSV file.
 *
 * @param data The list of maps to be saved. Each map represents a row in the CSV.
 * @param fileName The name of the file to save the CSV data to.
 */
def saveMapToCsv(List<Map> data, String fileName) {
    if (data.isEmpty()) {
        println "No data to write"
        return
    }

    // Extract headers from the keys of the first map
    def headers = data[0].keySet().join(',')

    // Generate CSV content by joining the values of each map with commas
    def csvContent = data.collect { row ->
        row.values().join(',')
    }.join('\n')

    // Write headers and CSV content to the specified file
    new File(fileName).withWriter { writer ->
        writer.write(headers + '\n' + csvContent + '\n')
    }
}

/**
 * Filters each row in the given ArrayList to retain only the specified keys.
 *
 * @param iterator The ArrayList containing rows of data.
 * @param keysToKeep A list of keys to retain in each row.
 * @return A new ArrayList with rows containing only the specified keys.
 */

def keepKeysFromArrayList(arrayList, keysToKeep) {
    def modifiedData = arrayList.collect { row ->
        def map = row as Map
        def mutableRow = map.findAll { key, value ->
            keysToKeep.contains(key)
        }
        return mutableRow
    }
    return modifiedData
}

/**
 * Utility function to convert time strings to minutes.
 *
 * This function takes a time string in the format of hours, minutes, seconds, and milliseconds,
 * and converts it to a total number of minutes.
 *
 * Example input formats:
 * - "1h 30m"
 * - "45m 30s"
 * - "2h 15m 10s 500ms"
 *
 * @param timeStr The time string to be converted.
 * @return The total time in minutes as a double.
 * @throws IllegalArgumentException if the time string is not in the correct format.
 */
 def convertTime(String timeStr) {
    def pattern = /((?<hours>\d+(\.\d+)?)h)?\s*((?<minutes>\d+(\.\d+)?)m)?\s*((?<seconds>\d+(\.\d+)?)s)?\s*((?<milliseconds>\d+(\.\d+)?)ms)?/
    def matcher = timeStr.trim() =~ pattern

    if (!matcher.matches()) {
        throw new IllegalArgumentException("Time string is not in the correct format: $timeStr")
    }

    def hours = matcher.group('hours')?.toDouble() ?: 0.0
    def minutes = matcher.group('minutes')?.toDouble() ?: 0.0
    def seconds = matcher.group('seconds')?.toDouble() ?: 0.0
    def milliseconds = matcher.group('milliseconds')?.toDouble() ?: 0.0

    return (hours * 60) + minutes + (seconds / 60) + (milliseconds / 60000)
}


/**
 * Utility function to convert memory to GB.
 *
 * This function takes a memory string with units (GB, MB, KB) and converts it to gigabytes (GB).
 *
 * Example input formats:
 * - "16GB"
 * - "2048MB"
 * - "1048576KB"
 *
 * @param memory The memory string to be converted.
 * @return The memory in gigabytes as a double, or null if the input is invalid.
 */
 def convertMemory(String memory) {
    if (!memory){
        return null
    }

    if (memory.contains("GB")) {
        return memory.replace("GB", "").toDouble()
    } else if (memory.contains("MB")) {
        return memory.replace("MB", "").toDouble() / 1000
    } else if (memory.contains("KB")) {
        return memory.replace("KB", "").toDouble() / 1000000
    }
    return null
}


/**
 * Processes the latest trace file in the specified directory.
 * The trace file is identified based on the given filePattern.
 *
 * This function identifies and parses the latest trace file, filters lines related to evaluation,
 * and converts the trace data into CSV format.
 *
 * @param traceDirPath The path to the directory containing trace files.
 * @param filePattern The pattern to identify the trace files.
 * @return The parsed CSV data from the trace file.
 */
def latesTraceFileToCSV(String traceDirPath, String filePattern) {
    // Identify and parse the latest trace file based on the given pattern
    def traceFile = new File(traceDirPath).listFiles().findAll { it.name.startsWith(filePattern) }.sort { -it.lastModified() }.take(1)[0]

    // Keep only the lines that report running times related to evaluation
    def header = traceFile.readLines()[0].replaceAll("\t", ",")
    def traceFileAlign = traceFile.readLines().findAll { it.contains("COMPLETED") && it.contains("MULTIPLESEQUENCEALIGN:ALIGN") }.collect { it.replaceAll("\t", ",") }.join("\n")
    def trace = header + "\n" + traceFileAlign

    // Parse the trace data into CSV format
    def traceCsv = parseCsv(trace)

    return traceCsv
}

/**
 * Merges two lists of maps based on a common ID key.
 *
 * @param list1 The first list of maps.
 * @param list2 The second list of maps.
 * @param idKey The key used to identify and merge maps from both lists.
 * @return A new list of merged maps.
 */
def mergeListsById(list1, list2, idKey) {
    // Create a map from list1 with the idKey as the key and the map as the value
    def map1 = list1.collectEntries { [(it[idKey]): it] }

    // Iterate over list2 and merge with corresponding entries from map1
    def mergedList = list2.collect { row ->
        def id = row[idKey]
        def mergedRow = map1.containsKey(id) ? map1[id] + row : row
        return mergedRow
    }

    // Return the merged list
    return mergedList
}


/**
 * Cleans the trace data by converting each row into a mutable map
 * and performing necessary transformations.
 *
 * The following transformations are performed:
 * - Extract the tag from the 'name' column using a regex pattern
 * - Extract 'id' and 'args' from the tag
 * - Process the 'full_name' to extract workflow and process details
 *
 * @param trace The trace data to be cleaned.
 * @return The cleaned trace data.
 */
def cleanTrace(ArrayList trace) {

    // Convert each row into a mutable map for dynamic property addition
    def cleanedTrace = trace.collect { row ->

        def mutableRow = new LinkedHashMap(row)

        // Extract the tag from the 'name' column using a regex pattern
        def tagMatch = (mutableRow.name =~ /\((.*)\)/)
        mutableRow.tag = tagMatch ? tagMatch[0][1] : null

        // Extract 'id' and 'args' from the tag safely
        mutableRow.id = mutableRow.tag?.tokenize(' ')?.first()
        mutableRow.args = mutableRow.tag?.split("args:")?.with { it.size() > 1 ? it[1].trim() : "default" }

        // Process the 'full_name' to extract workflow and process details
        mutableRow.full_name = mutableRow.name.split(/\(/)?.first()?.trim()
        def nameParts = mutableRow.full_name?.tokenize(':') ?: []
        mutableRow.process = nameParts ? nameParts.last() : null
        mutableRow.subworkflow = nameParts.size() > 1 ? nameParts[-2] : null

        return mutableRow
    }

    // Return the cleaned trace
    return cleanedTrace.findAll { it != null }
}



/**
 * Processes the latest trace file in the specified directory.
 *
 * This function identifies and parses the latest trace file based on the given pattern, filters columns to be reported for evaluation,
 * cleans the trace data, and extracts tree and alignment traces separately.
 *
 * @param traceDirPath The path to the directory containing trace files.
 * @param filePattern The pattern to identify the trace files.
 * @return A map containing the tree traces and alignment traces.
 */
def processLatestTraceFile(String traceDirPath) {

    // Parse the trace file
    def traceCsv = latesTraceFileToCSV(traceDirPath, "execution_trace")
    // Parse the co2 file
    def co2Csv = latesTraceFileToCSV(traceDirPath, "co2footprint_trace")

    // Merge the trace and co2 files
    // we need to do this because the co2 file has the energy consumption and CO2e but misses other columns of interest from the main file
    co2Csv = keepKeysFromArrayList(co2Csv, ["name", "energy_consumption", "CO2e", "powerdraw_cpu", "cpu_model", "requested_memory"])

    trace_co2_csv = mergeListsById(traceCsv.collect { it as Map }, co2Csv, "name")
    keys = ["id","name", "args", "tree", "aligner", "realtime", "%cpu", "rss", "peak_rss", "vmem", "peak_mem", "rchar", "wchar", "cpus", "energy_consumption", "CO2e", "powerdraw_cpu", "cpu_model", "requested_memory"]

    // Retain only the necessary columns and parse arguments from tree and aligner
    def cleanTraceData = cleanTrace(trace_co2_csv)
    // Extract the tree and align traces separately
    def traceTrees = prepTrace(cleanTraceData, suffix_to_replace = "_GUIDETREE", subworkflow = "COMPUTE_TREES", keys)
    def traceAlign = prepTrace(cleanTraceData, suffix_to_replace = "_ALIGN", subworkflow = "ALIGN", keys)

    // Return the extracted traces as a map
    return [traceTrees: traceTrees, traceAlign: traceAlign]
}


/**
 * Prepares and modifies trace data by retaining and transforming specified keys.
 * We need to do this because the trace data needs to have a suffix assigned
 * depending on the subworkflow type (ALIGN or COMPUTE_TREES), so that we can identify
 * which resource usage data corresponds to which process.
 *
 * @param trace The list of trace data maps.
 * @param suffix_to_replace The suffix to be removed from the process names.
 * @param subworkflow The subworkflow type to filter the trace data.
 * @param keys The list of keys to retain and transform in the trace data.
 * @return The modified trace data for the specified subworkflow.
 */
def prepTrace(trace, suffix_to_replace, subworkflow, keys) {

    // Extract the tree and align traces separately
    def trace_subworkflow = trace.findAll { it.subworkflow == subworkflow }

    // For each row, create a new row with the necessary keys and values
    trace_subworkflow.each { row ->
        def newRow = [:]

        // Clean the names (remove the unnecessary suffix)
        newRow.tree = row.process.replace(suffix_to_replace, "")

        def suffix = ""
        if(subworkflow == "ALIGN") {
            suffix = "_aligner"
            specific_key = "aligner"
        } else if(subworkflow == "COMPUTE_TREES") {
            suffix = "_tree"
            specific_key = "tree"
        }


        keys.each { key ->

            def newKey = key + suffix

            if (key in ['id', 'name', "tree", "aligner"]) {
                newKey = key
            }
            row[specific_key] = row.process.replace(suffix_to_replace, "")

            if ((key == 'realtime' || key == 'rss')) {
                newRow[newKey] = (key == 'realtime') ? convertTime(row[key]) : convertMemory(row[key])
            }else if(key == "args") {
                newRow[newKey+"_clean"] = row.args
            }else {
                newRow[newKey] = row[key]
            }
        }

        row.clear()
        row.putAll(newRow)
    }
    return trace_subworkflow
}



/**
 * Merges summary data with trace data from the latest trace file.
 *
 * @param summary_file The path to the summary file.
 * @param trace_dir_path The directory path containing trace files.
 * @param outFileName The name of the output file to save the merged data.
 */

def merge_summary_and_traces(summary_file, trace_dir_path, outFileName, shinyOutFileName) {

    // -------------------
    // TRACE FILE
    // -------------------

    // 1. Identify and parse the latest trace file
    // 2. Clean the trace (only completed tasks, keep only needed columns)
    // 3. Extract tree and align traces separately
    def trace_file = processLatestTraceFile(trace_dir_path)

    // -------------------
    // SUMMARY FILE
    // -------------------

    // Parse the summary data (scientific accuracy file: SP, TC etc.)
    def data = parseCsv(new File(summary_file).readLines().collect { it.replaceAll("\t", ",") }.join("\n"))
    data = data.collect { row ->
        def mutableRow = row as Map
        return mutableRow
    }


    // check if the trace file is empty
    if(trace_file.traceTrees.size() == 0 ){
        log.warn "Skipping merging of summary and trace files. Are you using -resume? \n \tIf so, you will not be able to access the running times of the modules and the final merging step will be skipped.\n\tPlease refer to the documentation.\n"
        // save the summary file to the output file
        saveMapToCsv(data, shinyOutFileName)
        return
    }

    // -------------------
    // MERGE
    // -------------------
    def mergedData = []
    data.each { row ->
        def treeMatch = trace_file.traceTrees.find { it.id == row.id && it.tree == row.tree && it.args_tree_clean == row.args_tree_clean}
        def alignMatch = trace_file.traceAlign.find { it.id == row.id && it.aligner == row.aligner && it.args_aligner_clean == row.args_aligner_clean}
        def mergedRow = row + (treeMatch ?: [:]) + (alignMatch ?: [:])
        mergedData << mergedRow
    }

    // Save the merged data to a file
    saveMapToCsv(mergedData, outFileName)
    saveMapToCsv(mergedData, shinyOutFileName)

}

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class Utils {



    public static cleanArgs(argString) {
        def cleanArgs = argString.toString().trim().replace("  ", " ").replace(" ", "_").replaceAll("==", "_").replaceAll("\\s+", "")
        // if clearnArgs is empty, return ""

        if (cleanArgs == null || cleanArgs == "") {
            return "default"
        }else{
            return cleanArgs
        }
    }

    public static clean_tree(argsTree){

        def tree = argsTree.toString()
        if(tree == null || tree == "" || tree == "null"){
            return "DEFAULT"
        }
        return tree
    }

    public static fix_args(tool,args,tool_to_be_checked, required_flag, default_value) {
        /*
        This function checks if the required_flag is present in the args string for the tool_to_be_checked.
        If not, it adds the required_flag and the default_value to the args string.
        */
        if(tool == tool_to_be_checked){
            if( args == null || args == ""|| args == "null" || !args.contains(required_flag+" ")){
                if(args == null || args == ""|| args == "null"){
                    args = ""
                }
                def prefix = ""
                if(args != ""){
                    prefix = args + " "
                }
                args = prefix + required_flag + " " + default_value
            }
        }
        return args
    }


    public static check_required_args(tool,args){

        // 3DCOFFEE
        args = fix_args(tool,args,"3DCOFFEE", "-method", "TMalign_pair")
        args = fix_args(tool,args,"3DCOFFEE", "-output", "fasta_aln")

        // REGRESSIVE
        args = fix_args(tool,args,"REGRESSIVE", "-reg", "")
        args = fix_args(tool,args,"REGRESSIVE", "-reg_method", "famsa_msa")
        args = fix_args(tool,args,"REGRESSIVE", "-reg_nseq", "1000")
        args = fix_args(tool,args,"REGRESSIVE", "-output", "fasta_aln")

        // TCOFFEE
        args = fix_args(tool,args,"TCOFFEE", "-output", "fasta_aln")

        // UPP
        args = fix_args(tool,args,"UPP", "-m", "amino")

        return args

    }





}
