
process CALCULATE_SEQSTATS {
    tag "$meta.id"
    label 'process_low'

    container 'luisas/structural_regression:20'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_seqstats.csv"), emit: seqstats
    tuple val(meta), path("*_seqstats_summary.csv"), emit: seqstats_summary
    path "versions.yml" , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def id = meta.id
    """
    calc_seqstats.py $id ${fasta} "${prefix}_seqstats.csv" "${prefix}_seqstats_summary.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

