process CREATE_TCOFFEETEMPLATE {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
    'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(accessory_informations)

    output:
    tuple val (meta), path("*_template.txt"), emit: template
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Prep templates
    for structure in \$(ls *.pdb); do id=`echo \$structure| awk  {'gsub(".pdb", "", \$0); print'}`; echo -e ">"\$id "_P_" "\${id}" >>${prefix}_template.txt ; done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_template.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
    END_VERSIONS
    """
}
