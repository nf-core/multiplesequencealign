process EXTRACT_PLDDT {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/ubuntu:22.04' :
    'nf-core/ubuntu:22.04' }"

    input:
    tuple val(meta), path(structures)

    output:
    tuple val (meta), path("*_plddt_summary.csv"), emit: plddt_summary
    tuple val (meta), path("*full_plddt.csv")    , emit: plddts
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Extract plddt per protein
    echo "id,seq_id,plddt" > ${prefix}_full_plddt.csv
    for structure in \$(ls *.pdb); do
        protein_name=\$(basename "\$structure" .pdb)
        avg=\$(awk '{if(\$1=="ATOM" && \$3=="CA") print \$11}' "\$structure" | awk '{sum+=\$1} END {print sum/NR}')
        echo "${prefix},\$protein_name,\$avg" >> ${prefix}_full_plddt.csv
    done

    # Extract plddt summary
    echo "id,plddt" > ${prefix}_plddt_summary.csv
    plddt=\$(awk -F, 'NR>1 {sum+=\$2} END {print sum/NR}' ${prefix}_full_plddt.csv); echo "${prefix},\$plddt" >> ${prefix}_plddt_summary.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_plddt_summary.csv
    touch ${prefix}_full_plddt.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk -W version | grep "awk" | sed 's/mawk//')
    END_VERSIONS
    """
}
