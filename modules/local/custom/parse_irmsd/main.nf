process PARSE_IRMSD {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.11.0   conda-forge::biopython=1.80 conda-forge::pandas=1.5.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-27978155697a3671f3ef9aead4b5c823a02cc0b7:548df772fe13c0232a7eab1bc1deb98b495a05ab-0' :
        'biocontainers/mulled-v2-27978155697a3671f3ef9aead4b5c823a02cc0b7:548df772fe13c0232a7eab1bc1deb98b495a05ab-0' }"

    input:
    tuple val(meta), path(infile)

    output:
    tuple val(meta), path("${prefix}.irmsd_tot"), emit: irmsd_tot
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${infile.baseName}"
    def header = meta.keySet().join(",")
    def values = meta.values().join(",")
    """
    # Parse irmsd file
    grep "TOTAL" $infile > ${prefix}.total_irmsd

    parsers.py -i ${prefix}.total_irmsd -o ${prefix}.scores.csv

    # Prep metadata file
    echo "${header}" > meta.csv
    echo "${values}" >> meta.csv

    # Add metadata info to output file
    paste -d, meta.csv ${prefix}.scores.csv > ${prefix}.irmsd_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.irmsd_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
