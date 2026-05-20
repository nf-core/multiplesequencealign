import nextflow.Nextflow
import groovy.text.SimpleTemplateEngine

class Utils {

    static cleanArgs(argString) {
        def cleanArgs = argString.toString().trim().replace("  ", " ").replace(" ", "_").replaceAll("==", "_").replaceAll("\\s+", "")

        if (cleanArgs == null || cleanArgs == "" || cleanArgs == "null") {
            return "default"
        } else {
            return cleanArgs
        }
    }

    static clean_tree(treeIn) {
        def tree = treeIn.toString()
        if(tree == null || tree == "" || tree == "null") {
            return "DEFAULT"
        }
        return tree
    }

    static fix_args(tool, args, tool_to_be_checked, required_flag, default_value) {
        if(tool == tool_to_be_checked) {
            if(args == null || args == "" || args == "null" || !args.contains(required_flag + " ")) {
                if(args == null || args == "" || args == "null") {
                    args = ""
                }
                def prefix = ""
                if(args != "") {
                    prefix = args + " "
                }
                args = prefix + required_flag + " " + default_value
            }
        }
        return args
    }

    static check_required_args(tool, args) {
        // 3DCOFFEE
        args = fix_args(tool, args, "3DCOFFEE", "-method", "TMalign_pair")
        args = fix_args(tool, args, "3DCOFFEE", "-output", "fasta_aln")

        // REGRESSIVE
        args = fix_args(tool, args, "REGRESSIVE", "-reg", "")
        args = fix_args(tool, args, "REGRESSIVE", "-reg_method", "famsa_msa")
        args = fix_args(tool, args, "REGRESSIVE", "-reg_nseq", "1000")
        args = fix_args(tool, args, "REGRESSIVE", "-output", "fasta_aln")

        // TCOFFEE
        args = fix_args(tool, args, "TCOFFEE", "-output", "fasta_aln")

        // UPP
        args = fix_args(tool, args, "UPP", "-m", "amino")

        return args
    }
}
