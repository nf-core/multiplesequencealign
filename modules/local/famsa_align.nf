
process FAMSA_ALIGN {
    tag "$meta.id _ $meta.align _ $meta.args_align"
    label 'process_medium'

    input:
    tuple val(meta), path(fasta), path(tree)
    

    output:
    tuple val (meta), path ("*.aln"), emit: msa
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"    
    """
    famsa -gt import ${tree} $args ${fasta} ${prefix}.aln  &> "version.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        famsa: \$( cat version.txt | head -n 1 | sed 's/FAMSA (Fast and Accurate Multiple Sequence Alignment) ver. //g' )
    END_VERSIONS
    """
}

