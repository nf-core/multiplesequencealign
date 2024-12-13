@Grab('com.xlson.groovycsv:groovycsv:1.3')
import static com.xlson.groovycsv.CsvParser.parseCsv

def cleanTrace(trace) {
    // Convert each row into a mutable map for dynamic property addition
    def cleanedTrace = trace.collect { row ->
        def mutableRow = row.toMap()

        // Extract the tag from the 'name' column using a regex pattern
        def tagMatch = (mutableRow.name =~ /\((.*)\)/)
        mutableRow.tag = tagMatch ? tagMatch[0][1] : null

        // Extract 'id' and 'args' from the tag safely
        mutableRow.id = mutableRow.tag?.tokenize(' ')?.first()
        mutableRow.args = mutableRow.tag?.split("args:")?.with { it.size() > 1 ? it[1].trim() : null }

        // Process the 'full_name' to extract workflow and process details
        mutableRow.full_name = mutableRow.name.split(/\(/)?.first()?.trim()
        def nameParts = mutableRow.full_name?.tokenize(':') ?: []
        mutableRow.process = nameParts ? nameParts.last() : null
        mutableRow.subworkflow = nameParts.size() > 1 ? nameParts[-2] : null

        // Replace "null" strings with actual null values
        mutableRow.each { key, value ->
            if (value == 'null') {
                mutableRow[key] = null
            }
        }

        return mutableRow
    }

    // Return the cleaned trace
    return cleanedTrace.findAll { it != null }
}

// Utility function to convert time strings to minutes
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

// Utility function to convert memory to GB
def convertMemory(String memory) {
    if (!memory) return null

    if (memory.contains("GB")) {
        return memory.replace("GB", "").toDouble()
    } else if (memory.contains("MB")) {
        return memory.replace("MB", "").toDouble() / 1000
    } else if (memory.contains("KB")) {
        return memory.replace("KB", "").toDouble() / 1000000
    }
    return null
}

// Prepare trace trees
def prepTreeTrace(trace) {
    def traceTrees = trace.findAll { it.subworkflow == "COMPUTE_TREES" }
    traceTrees.each { row ->
        row.args_tree = row.args
        row.tree = row.process.replace("_GUIDETREE", "")
        row.time_tree = convertTime(row.realtime)
        row.memory_tree = convertMemory(row.rss)
        row.cpus_tree = row.cpus
    }
    return traceTrees
}

// Prepare align traces
def prepAlignTrace(trace) {
    def traceAlign = trace.findAll { it.subworkflow == "ALIGN" }
    traceAlign.each { row ->
        row.args_aligner = row.args
        row.aligner = row.process.replace("_ALIGN", "")
        row.time_align = convertTime(row.realtime)
        row.memory_align = convertMemory(row.rss)
        row.cpus_align = row.cpus
    }
    return traceAlign
}

def merge_summary_and_traces(summary_file, trace_dir_path, outFileName){

    // Read the summary file with the scientific evaluation 
    def data  = new File(summary_file).readLines()

    // Identify and parse the latest trace file
    def trace_file = new File("${trace_dir_path}").listFiles().findAll { it.name.startsWith("execution_trace") }.sort { -it.lastModified() }.take(1)[0]

    // Keep only the lines that report running times related to evaluation
    def header = trace_file.readLines()[0].replaceAll("\t", ",")
    def trace_file_align = trace_file.readLines().findAll { it.contains("CACHED") && it.contains("MULTIPLESEQUENCEALIGN:ALIGN") }.collect { it.replaceAll("\t", ",") }.join("\n")
    def trace = header + "\n" + trace_file_align
    def trace_csv = parseCsv(trace)

    def cleanTraceData = cleanTrace(trace_csv)
    def traceTrees = prepTreeTrace(cleanTraceData)
    def traceAlign = prepAlignTrace(cleanTraceData)

    def mergedData = []
    data.each { row ->
        def treeMatch = traceTrees.find { it.id == row.id && it.tree == row.tree && it.args_tree == row.args_tree }
        def alignMatch = traceAlign.find { it.id == row.id && it.aligner == row.aligner && it.args_aligner == row.args_aligner }
        def mergedRow = row + (treeMatch ?: [:]) + (alignMatch ?: [:])
        mergedData << mergedRow
    }
    new File(outFileName).withWriter { writer -> writer.write(mergedData as String) }

}

outdir = "/home/luisasantus/Desktop/multiplesequencealign/results"

def summary_file = "${outdir}/summary/complete_summary_stats_eval.csv"
def outFileName = "${outdir}/../test_merged.csv"
def trace_dir_path = "${outdir}/pipeline_info/"

merge_summary_and_traces(summary_file, trace_dir_path, outFileName)