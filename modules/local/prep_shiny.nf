process PREPARE_SHINY {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(table)
    path (app)

    output:
    tuple val (meta), path("shiny_data.csv"), emit: data
    path ("shiny_app.py"), emit: app
    path ("run.sh"), emit: run

    when:

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    mv $table shiny_data.csv
    mv $app shiny_app.py
    echo "shiny run --reload shiny_app.py" > run.sh
    chmod +x run.sh
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch shiny_data.csv
    touch shiny_app.R
    """
}
