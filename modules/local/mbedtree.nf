
process MBEDTREE {
    tag "$meta.family _ $meta_run.tree _ $meta_run.args_tree"
    label 'process_low'

    // TODO: change to the correct container
    container 'edgano/tcoffee:pdb'

    input:
    tuple val(meta),val(meta_run), path(fasta)

    output:
    tuple val (meta), val(meta_run), path ("*.dnd"), emit: tree
    path "versions.yml" , emit: versions

    script:
    def args = meta_run.args_tree == 'none' ? '' : meta_run.args_tree
    def args_tree_clean = cleanargs(meta_run.args_tree)
    def prefix = task.ext.prefix ?: "${meta.family}_${meta_run.tree}-args-${args_tree_clean}"
    
    """
    clustalo -i ${fasta} --guidetree-out ${prefix}.dnd --force $args
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clustalo: \$( clustalo --version)
    END_VERSIONS
    """
}


def cleanargs(String argstring) {

    cleanargs = argstring.strip().replaceAll(/-/, '')
                         .replaceAll(/ /, '=')
                         .replaceAll(/==/, '=')
                         .replaceAll(/ /, '')


    return cleanargs
}