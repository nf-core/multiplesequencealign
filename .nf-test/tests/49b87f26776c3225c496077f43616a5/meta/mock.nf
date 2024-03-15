import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2


// comes from testflight to find json files
params.nf_test_output  = ""

// function mapping
def input = []

//----

// include function

include { getWorkflowVersion } from '/home/luisasantus/Desktop/multiplesequencealign/subworkflows/nf-core/utils_nextflow_pipeline/main.nf'


// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

  result = getWorkflowVersion(*input)
  if (result != null) {
  	new File("${params.nf_test_output}/function.json").text = jsonOutput.toJson(result)
  }
  
}


workflow.onComplete {

	def result = [
		success: workflow.success,
		exitStatus: workflow.exitStatus,
		errorMessage: workflow.errorMessage,
		errorReport: workflow.errorReport
	]
    new File("${params.nf_test_output}/workflow.json").text = jsonOutput.toJson(result)
    
}