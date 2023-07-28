
include { SUMMARY_CSV } from '../../modules/local/summary_csv'

workflow SUMMARY_REPORT {
    take:
    tcoffee_alncompare_scores
    tcoffee_irmsd_scores                
   

    main:

    ch_versions = Channel.empty()
    //tcoffee_seqreformat_sim = tcoffee_seqreformat_sim.map{ it -> [linkedHashMapToCSV(it[0]), it[1]] }

    // TODO later the storeDir must be removed and the file passed to the next process which should merge all the stats
    // tcoffee_seqreformat_sim.map{ it ->  "${it.text}" }
    //                        .collectFile(name: "similarities_summary.csv", newLine: true, storeDir:"/home/luisasantus/Desktop/")  
    
    SUMMARY_CSV(tcoffee_irmsd_scores)



    //SUMMARY_CSV(tcoffee_seqreformat_sim)
    tcoffee_alncompare_scores.view()
    

    emit:
    //csv              = SUMMARY_CSV.out.csv              
    versions         = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}



// TODO is there any better way to do this? 
File linkedHashMapToCSV(LinkedHashMap map) {
    def header = map.keySet().join(",") // Join keys to create the header row
    def values = map.values().join(",") // Join values to create the data row
    def csvContent = "$header\n$values" // Combine header and data row
    def csvFile = new File("meta.csv")
    csvFile.text = csvContent
    return csvFile
}