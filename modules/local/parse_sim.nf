process PARSE_SIM {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(infile)

    output:
    tuple val (meta), path("${prefix}.sim_tot"), emit: sim_tot

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "$prefix" > tmp
    grep ^TOT $infile | cut -f4 >> tmp

    echo "id,perc_sim" > ${prefix}.sim_tot
    cat tmp | tr '\\n' ',' | awk 'gsub(/,\$/,x)' >>  ${prefix}.sim_tot   
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sim_tot
    """
}
