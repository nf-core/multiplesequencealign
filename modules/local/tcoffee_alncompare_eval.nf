

process TCOFFEE_ALNCOMPARE_EVAL {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::t-coffee=13.45.0.4846264"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/t-coffee:13.45.0.4846264--hc57179f_5':
        'biocontainers/t-coffee:13.45.0.4846264--hc57179f_5' }"
    input:
    tuple  val(meta), file (msa), file (ref_msa)

    output:
    tuple val(meta), path ("*.scores"), emit: scores
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def header = meta.keySet().join(",")
    def values = meta.values().join(",")
    """
    ## Sum-of-Pairs Score ##
    t_coffee -other_pg aln_compare \
        -al1 ${ref_msa} \
        -al2 ${msa} \
        -compare_mode sp \
        | grep -v "seq1" | grep -v '*' | \
        awk '{ print \$4}' ORS="\t" \
        >> "scores.txt"

    ## Total Column Score ##
    t_coffee -other_pg aln_compare \
        -al1 ${ref_msa} \
        -al2 ${msa} \
        -compare_mode tc \
        | grep -v "seq1" | grep -v '*' | \
        awk '{ print \$4}' ORS="\t" \
        >> "scores.txt"

    ## Column Score ##
        t_coffee -other_pg aln_compare \
            -al1 ${ref_msa} \
            -al2 ${msa} \
            -compare_mode column \
            | grep -v "seq1" | grep -v '*' | \
            awk '{ print \$4}' ORS="\t" \
            >> "scores.txt"


    # Add metadata info to output file
    echo "${header},sp,tc,column" > "${msa.baseName}.scores"

    # Add values
    scores=\$(awk '{sub(/[[:space:]]+\$/, "")} 1' scores.txt | tr -s '[:blank:]' ',')
    echo "${values},\$scores" >> "${msa.baseName}.scores"


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}
