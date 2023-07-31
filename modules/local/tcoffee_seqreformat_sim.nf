

process TCOFFEE_SEQREFORMAT_SIM {
    tag "$meta.family"
    label 'process_low'

    // TODO: change to the correct container
    container 'luisas/structural_regression:20'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.sim"), emit: perc_sim
    tuple val(meta), path("*.sim_tot"), emit: perc_sim_tot
    path "versions.yml" , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.family}"
    """
    t_coffee -other_pg seq_reformat -in ${fasta} -output=sim_idscore > "${prefix}.sim"

    echo "$prefix" > tmp 
    grep ^TOT ${prefix}.sim | cut -f4 >> tmp

    echo "family,perc_sim" > ${prefix}.sim_tot
    cat tmp | tr '\\n' ',' | awk 'gsub(/,\$/,x)' >>  ${prefix}.sim_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}


