process PREPARE_SHINY {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
    'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(table)
    path (app)

    output:
    tuple val(meta), path ("shiny_data.csv"), emit: data
    path ("shiny_app*"), emit: app
    path ("run.sh"), emit: run
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp $table shiny_data.csv
    cp $app/* .
    rm $app
    echo "shiny run --reload shiny_app.py" > run.sh
    chmod +x run.sh

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """

    stub:
    """
    touch shiny_data.csv
    touch shiny_app.R

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
