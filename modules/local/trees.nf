


process FAMSA_PARTTREE {
    tag "$meta.id"
    label 'process_low'

    // TODO: change to the correct container
    container 'edgano/tcoffee:pdb'

    input:
    tuple val(id), path(seqs)

    output:
    tuple val (id), val(tree_method), path ("${prefix}.dnd"), emit: trees
    path "versions.yml" , emit: versions

    script:
    """
    famsa -gt upgma -parttree -t ${task.cpus} -gt_export ${seqs} ${prefix}.dnd

    cat <<-END_VERSIONS > versions.yml
    version=\$(famsa --version 2>&1 | head -n 1)
    "${task.process}":
        famsa: \$( echo \$version| grep -oP '(?<=ver\.\s)\S+' )
    END_VERSIONS
    """
}



