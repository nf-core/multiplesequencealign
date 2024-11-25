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

                        tree_map["tree"] = meta_clone["tree"]
                        tree_map["args_tree"] = meta_clone["args_tree"]
                        tree_map["args_tree_clean"] = Utils.cleanArgs(meta_clone.args_tree)

                        align_map["aligner"] = meta_clone["aligner"]
                        align_map["args_aligner"] = Utils.check_required_args(meta_clone["aligner"], meta_clone["args_aligner"])
                        align_map["args_aligner_clean"] = Utils.cleanArgs(align_map["args_aligner"])

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

        if (shiny_trace_mode) {
            getTraceForShiny(trace_dir_path, shiny_dir_path, shiny_trace_mode)
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

def getHeader(trace_file){
    // Get the header of the trace file
    def trace_lines = trace_file.readLines()
    def header = trace_lines[0]
    return header
}

def filterTraceForShiny(trace_file){
    // Retain only the lines that contain "COMPLETED" and "MULTIPLESEQUENCEALIGN:ALIGN"
    def trace_lines = trace_file.readLines()
    def shiny_trace_lines = []
    for (line in trace_lines){
        if (line.contains("COMPLETED") && line.contains("MULTIPLESEQUENCEALIGN:ALIGN")){
            shiny_trace_lines.add(line)
        }
    }
    return shiny_trace_lines
}

// if multiple lines have the same name column
// only the one with the latest timestamp will be kept
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

def takeLatestComplete(traceInfos) {

    // colnames and the position of the columns name and start
    colnames = traceInfos.first().split('\t').collect { it.trim() }
    def name_index = colnames.indexOf("name")
    def start_index = colnames.indexOf("start")

    // remove the column name line
    traceInfos = traceInfos.drop(1)
    // Initialize a map to store entries by their names and latest submit timestamps
    def latestEntries = [:]
    def formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")
    // Iterate over each line
    // If the name is not in the map or the submit timestamp is after the latest one, update the map
    traceInfos.each { line ->
        def values = line.split('\t')
        def name = values[name_index]
        def submit = LocalDateTime.parse(values[start_index], formatter)
        if (!latestEntries.containsKey(name) || submit.isAfter(latestEntries[name][start_index])) {
            latestEntries[name] = values
        }
    }
    def filteredData = colnames.join('\t') + '\n'
    filteredData = filteredData + latestEntries.values().collect { it.join('\t') }.join('\n')
    def result = []
    result.addAll(filteredData)
    return result
}

def getTraceForShiny(trace_dir_path, shiny_dir_path, shiny_trace_mode){
        // According to the mode selected, get either the latest trace file or all trace files
        // If all trace files are selected, it is assumed that the trace files were generated with the "resume" mode
        def trace_dir = new File("${trace_dir_path}")
        def trace_files = []
        if (shiny_trace_mode == "all"){
            trace_files = trace_dir.listFiles().findAll { it.name.startsWith("execution_trace") }
        }
        else if(shiny_trace_mode == "latest"){
            trace_files = trace_dir.listFiles().findAll { it.name.startsWith("execution_trace") }.sort { -it.lastModified() }.take(1)
        }
        else{
            print("Invalid shiny trace mode. Please use either 'latest' or 'all'")
        }
        // Filter the trace files for shiny
        // and move the trace file to the shiny directory
        if (trace_files.size() > 0) {
            def trace_infos = []
            def header_added = false
            for (file in trace_files){
                if( !header_added ){
                    trace_infos = trace_infos + getHeader(file)
                    header_added = true
                }
                trace_infos = trace_infos + filterTraceForShiny(file)
            }
            // if trace infos is empty then print a message
            if(trace_infos.size() == 0){
                print("There is an issue with your trace file!")
            }

            trace_infos = takeLatestComplete(trace_infos)
            def shiny_trace_file = new File("${shiny_dir_path}/trace.txt")
            shiny_trace_file.write(trace_infos.join("\n"))
        }else{
            print("No trace file found in the " + trace_dir_path + " directory.")
        }
}

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class Utils {



    public static cleanArgs(argString) {
        def cleanArgs = argString.toString().trim().replace("  ", " ").replace(" ", "_").replaceAll("==", "_").replaceAll("\\s+", "")
        // if clearnArgs is empty, return ""

        if (cleanArgs == null || cleanArgs == "") {
            return ""
        }else{
            return cleanArgs
        }
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
