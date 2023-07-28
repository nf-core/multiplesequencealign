

process SUMMARY_CSV {
    tag "$samplesheet"
    label 'process_low'

    input:
    tuple path(meta), path(scores)

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: 
    def args = task.ext.args ?: ''
    """
    parsers.py \\
        -meta $meta \\
        -scores $scores \\
        test.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}