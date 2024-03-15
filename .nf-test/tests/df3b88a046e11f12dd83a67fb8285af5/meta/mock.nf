import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test workflow
include { UTILS_NEXTFLOW_PIPELINE } from '/home/luisasantus/Desktop/multiplesequencealign/./subworkflows/nf-core/utils_nextflow_pipeline/tests/../main.nf'

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
    
                print_version        = false
                dump_parameters      = true
                outdir               = 'results'
                check_conda_channels = false

                input[0] = false
                input[1] = true
                input[2] = outdir
                input[3] = false
                
    //----

    //run workflow
    UTILS_NEXTFLOW_PIPELINE(*input)
    
    if (UTILS_NEXTFLOW_PIPELINE.output){

        // consumes all named output channels and stores items in a json file
        for (def name in UTILS_NEXTFLOW_PIPELINE.out.getNames()) {
            serializeChannel(name, UTILS_NEXTFLOW_PIPELINE.out.getProperty(name), jsonOutput)
        }	  
    
        // consumes all unnamed output channels and stores items in a json file
        def array = UTILS_NEXTFLOW_PIPELINE.out as Object[]
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
