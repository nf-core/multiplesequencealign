import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test workflow
include { UTILS_NFVALIDATION_PLUGIN } from '/home/luisasantus/Desktop/multiplesequencealign/./subworkflows/nf-core/utils_nfvalidation_plugin/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

    // run dependencies
    

    // workflow mapping
    def input = []
    
                help             = true
                workflow_command = "nextflow run noorg/doesntexist"
                pre_help_text    = null
                post_help_text   = null
                validate_params  = false
                schema_filename  = "/home/luisasantus/Desktop/multiplesequencealign/./subworkflows/nf-core/utils_nfvalidation_plugin/tests/nextflow_schema.json"

                input[0] = help
                input[1] = workflow_command
                input[2] = pre_help_text
                input[3] = post_help_text
                input[4] = validate_params
                input[5] = schema_filename
                
    //----

    //run workflow
    UTILS_NFVALIDATION_PLUGIN(*input)
    
    if (UTILS_NFVALIDATION_PLUGIN.output){

        // consumes all named output channels and stores items in a json file
        for (def name in UTILS_NFVALIDATION_PLUGIN.out.getNames()) {
            serializeChannel(name, UTILS_NFVALIDATION_PLUGIN.out.getProperty(name), jsonOutput)
        }	  
    
        // consumes all unnamed output channels and stores items in a json file
        def array = UTILS_NFVALIDATION_PLUGIN.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
}


def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
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
