process MULTIQC_PREP_TABLE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(csv)

    output:
    tuple val (meta), path("*_multiqc_table.csv"), emit: multiqc_table

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    prep_multiqc_table.py -i $csv -o ${prefix}_multiqc_table.csv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_multiqc_table.csv
    """
}