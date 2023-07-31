
process TCOFFEEREGRESSIVE_ALIGN {
    tag "$meta.family _ $meta_run.align _ $meta_run.args_align"
    label 'process_low'

    // TODO: change to the correct container

    input:
    tuple val(meta), val(meta_tree), val(meta_run), path(fasta), path(tree)
    

    output:
    tuple val(meta), val(meta_tree), val(meta_run), path ("*.aln"), emit: msa
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args_meta = meta_run.args_align == 'none' ? '' : meta_run.args_align
    def args_align_clean = cleanargs(meta_run.args_align)
    def args_tree_clean = cleanargs(meta_tree.args_tree)
    def prefix = task.ext.prefix ?: "${meta.family}_${meta_tree.tree}-args-${args_tree_clean}_${meta_run.align}-args-${args_align_clean}"
    print(args_align_clean)
    """
    t_coffee -reg $args_meta \
         -reg_tree ${tree} \
         -seq ${fasta} \
         -thread ${task.cpus} \
         -outfile ${prefix}.aln 2> tcoffee.stderr

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}


def cleanargs(String argstring) {

    cleanargs = argstring.strip().replaceAll(/-/, '')
                         .replaceAll(/\\s+/, '=')
                         .replaceAll(/==/, '=')
                         .replaceAll(/\s/, '')


    return cleanargs
}

