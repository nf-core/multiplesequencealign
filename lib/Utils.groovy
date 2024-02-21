//
// This file holds several functions specific to the workflow/multiplesequencealign.nf in the nf-core/multiplesequencealign pipeline
//

import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class Utils {



    public static cleanArgs(argString) {
        def cleanArgs = argString.toString().trim().replace("-", "").replace("  ", " ").replace(" ", "_").replaceAll("==", "_").replaceAll("\\s+", "")
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
                args = args + " " + required_flag + " " + default_value
            }
        }
        return args
    }

    public static check_required_args(tool,args){

        // 3DCOFFEE
        args = fix_args(tool,args,"3DCOFFEE", "-method", "TMalign_pair")
        // REGRESSIVE
        args = fix_args(tool,args,"REGRESSIVE", "-reg", "")
        args = fix_args(tool,args,"REGRESSIVE", "-reg_method", "famsa_msa")
        args = fix_args(tool,args,"REGRESSIVE", "-reg_nseq", "1000")
        args = fix_args(tool,args,"REGRESSIVE", "-output", "fasta_aln")
        // TCOFFEE
        args = fix_args(tool,args,"TCOFFEE", "-output", "fasta_aln")

        return args

    }



}
