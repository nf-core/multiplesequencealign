import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { TCOFFEE_SEQREFORMAT } from '/home/luisasantus/Desktop/multiplesequencealign/modules/nf-core/tcoffee/seqreformat/main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                input[0] = [
                                [ id:'test' ], // meta map
                                file("https://raw.githubusercontent.com/nf-core/test-datasets/multiplesequencealign/testdata/setoxin-ref.fa", checkIfExists: true)
                            ]
                
    //----

    //run process
    TCOFFEE_SEQREFORMAT(*input)

    if (TCOFFEE_SEQREFORMAT.output){

        // consumes all named output channels and stores items in a json file
        for (def name in TCOFFEE_SEQREFORMAT.out.getNames()) {
            serializeChannel(name, TCOFFEE_SEQREFORMAT.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = TCOFFEE_SEQREFORMAT.out as Object[]
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
