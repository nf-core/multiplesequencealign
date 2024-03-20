process EXTRACT_PLDDT {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
    'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(structures)

    output:
    tuple val (meta), path("*_plddt.csv"), emit: template
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Prep templates
    for structure in \$(ls *.pdb); do protein_name=\$(basename "\$structure" .pdb); avg=\$(awk '{if(\$1=="ATOM" && \$3=="CA") print \$6}' "\$structure" | awk '{sum+=\$1} END {print sum/NR}'); echo "\$protein_name,\$avg" >> proteins_plddts.csv; done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -V | grep "GNU Awk" | sed 's/GNU Awk //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_plddt.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -V | grep "GNU Awk" | sed 's/GNU Awk //')
    END_VERSIONS
    """
}