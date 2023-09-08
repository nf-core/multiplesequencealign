

process MERGE_EVALUATIONS_REPORT {
    label 'process_low'

    input:
    path(tcoffee_alncompare_scores_summary)
    path(tcoffee_irmsd_scores_summary)

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    merge_scores.py \
        "evaluation_summary_report.csv" \
        ${tcoffee_alncompare_scores_summary} \
        ${tcoffee_irmsd_scores_summary}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
