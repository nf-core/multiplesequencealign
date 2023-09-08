
process TCOFFEE_REGRESSIVEALIGN {
    tag "$meta.id"
    label 'process_medium'


    input:
    tuple val(meta), path(fasta), path(tree)

    output:
    tuple val(meta), path ("*.aln"), emit: msa
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    t_coffee -reg $args \
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




