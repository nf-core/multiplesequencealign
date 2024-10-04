process PREPARE_SHINY {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(table)
    path (app)

    output:
    tuple val(meta), path("shiny_data.csv"), emit: data
    path "shiny_app*"                      , emit: app
    path "static*"                         , emit: static_dir
    path "run.sh"                          , emit: run
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args         = task.ext.args ?: ''
    prefix           = task.ext.prefix ?: "${meta.id}"
    def docker_url   = "community.wave.seqera.io/library/pip_numpy_pandas_plotly_pruned:e8ce557dd7db3767"
    def bash_command = "bash -c 'cd /app && shiny run --reload shiny_app.py'"
    """
    cp $table shiny_data.csv
    cp -r $app/* .
    rm $app
    echo -n 'docker run -v \$PWD:/app --network=host ' > run.sh
    echo -n "$docker_url $bash_command" >> run.sh
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
    touch run.sh
    mkdir static

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$(bash --version | grep -Eo 'version [[:alnum:].]+' | sed 's/version //'))
    END_VERSIONS
    """
}
