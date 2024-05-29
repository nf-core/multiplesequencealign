process MULTIQC {
    label 'process_medium'

    conda 'bioconda::multiqc=1.22.1'
    container "community.wave.seqera.io/library/pip_multiqc:2c2e276ad8997cc4"

    input:
    path multiqc_config
    path multiqc_custom_config
    path software_versions
    path workflow_summary

    path (seqstats_summary)

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots
    path "versions.yml"        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def custom_config = params.multiqc_config ? "--config $multiqc_custom_config" : ''
    """
    multiqc \\
        -f \\
        $args \\
        $custom_config \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
