import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies

include { UNTAR } from '/home/luisasantus/Desktop/multiplesequencealign/./modules/nf-core/tcoffee/irmsd/tests/../../../untar/main.nf'


// include test process
include { TCOFFEE_IRMSD } from '/home/luisasantus/Desktop/multiplesequencealign/./modules/nf-core/tcoffee/irmsd/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

    // run dependencies
    
    {
        def input = []
        
                    input[0] = [ [ id:'test' ],
                                 file("https://raw.githubusercontent.com/nf-core/test-datasets/multiplesequencealign/testdata/structures/seatoxin-ref.tar.gz", checkIfExists: true)
                               ]

                    
        UNTAR(*input)
    }
    

    // process mapping
    def input = []
    
                input[0] = [
                                [ id:'test' ], // meta map
                                file("https://raw.githubusercontent.com/nf-core/test-datasets/multiplesequencealign/testdata/setoxin.ref", checkIfExists: true)
                            ]
                input[1] = UNTAR.out.untar.map { meta,dir -> [[ id:'test' ], file("https://raw.githubusercontent.com/nf-core/test-datasets/multiplesequencealign/testdata/templates/seatoxin-ref_template.txt", checkIfExists: true) ,file(dir).listFiles().collect()]}
                
    //----

    //run process
    TCOFFEE_IRMSD(*input)

    if (TCOFFEE_IRMSD.output){

        // consumes all named output channels and stores items in a json file
        for (def name in TCOFFEE_IRMSD.out.getNames()) {
            serializeChannel(name, TCOFFEE_IRMSD.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = TCOFFEE_IRMSD.out as Object[]
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
