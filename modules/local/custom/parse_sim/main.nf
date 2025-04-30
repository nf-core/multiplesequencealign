process PARSE_SIM {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(infile)

    output:
    tuple val (meta), path("*.sim_tot"), emit: sim_tot
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "$prefix" > tmp
    grep ^TOT $infile | cut -f4 >> tmp
    #remove empty spaces
    sed -i 's/ //g' tmp

    echo "id,perc_sim" > ${prefix}.sim_tot
    cat tmp | tr '\\n' ',' | awk 'gsub(/,\$/,x)' >>  ${prefix}.sim_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.sim_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}
