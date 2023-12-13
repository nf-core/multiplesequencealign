process PARSE_IRMSD {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(infile)

    output:
    tuple val(meta), path("${prefix}.irmsd_tot"), emit: irmsd_tot

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
        tcoffee: \$( t_coffee -version | awk '{gsub("Version_", ""); print \$3}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.irmsd_tot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tcoffee: \$( t_coffee -version | awk '{gsub("Version_", ""); print \$3}')
    END_VERSIONS
    """
}
