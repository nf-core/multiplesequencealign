
process CLUSTALO_MBEDTREE {
    tag "$meta.id _ $meta.tree _ $meta.args_tree"
    label 'process_low'


    input:
    tuple val(meta), path(fasta)
    

    output:
    tuple val (meta), path ("*.dnd"), emit: tree
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"  
    
    """
    clustalo -i ${fasta} --guidetree-out ${prefix}.dnd --force $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        clustalo: \$( clustalo --version)
    END_VERSIONS
    """
}

