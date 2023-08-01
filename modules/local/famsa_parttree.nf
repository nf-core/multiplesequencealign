


process FAMSA_PARTTREE {
    tag "$meta.family _ $meta.tree _ $meta.args_tree"
    label 'process_low'


    input:
    tuple val(meta), path(fasta)
    

    output:
    tuple val (meta), path ("*.dnd"), emit: tree
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.family}"    
    """
    famsa -gt upgma -parttree -t ${task.cpus} -gt_export ${fasta} $args ${prefix}.dnd &> "version.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        famsa: \$( cat version.txt | head -n 1 | sed 's/FAMSA (Fast and Accurate Multiple Sequence Alignment) ver. //g' )
    END_VERSIONS
    """
}






