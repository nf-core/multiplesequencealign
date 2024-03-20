process CALC_GAPS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
    'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(msa)

    output:
    tuple val (meta), path("*_gaps.csv"), emit: gaps
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def header = meta.keySet().join(",")
    def values = meta.values().join(",")
    """
    echo "${header},total_gaps,avg_gaps" > ${prefix}_gaps.csv
    total_gaps=\$(grep -v ">" $msa | awk -F "-" '{total += NF-1; seq_count++} END {print total}'); 
    avg_gaps=\$(grep -v ">" $msa | awk -F "-" '{total += NF-1; seq_count++} END {avg = total / seq_count; print avg}'); 
    echo "${values},\$total_gaps,\$avg_gaps" >> ${prefix}_gaps.csv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -V | grep "GNU Awk" | sed 's/GNU Awk //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_gaps.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -V | grep "GNU Awk" | sed 's/GNU Awk //')
    END_VERSIONS
    """
}
