

process TCOFFEE_SEQREFORMAT_SIM {
    tag "$meta.id"
    label 'process_low'

    // TODO: change to the correct container
    container 'luisas/structural_regression:20'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.sim"), emit: perc_sim
    path "versions.yml" , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.family}"
    """
    t_coffee -other_pg seq_reformat -in ${fasta} -output=sim_idscore > "${prefix}.sim"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """

}