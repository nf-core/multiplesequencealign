process LEARNMSA_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/learnmsa_mmseqs2_pigz_pip_pruned:ccded0c18518fd60' :
        'community.wave.seqera.io/library/learnmsa_pigz:8a1bb578b28c7eaa' }"

    input:
    tuple val(meta), path(fasta)
    val(compress)

    output:
    tuple val(meta), path("*.aln{.gz,}"), emit: alignment
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def write_output = compress ? ">(pigz -cp ${task.cpus} > ${prefix}.aln.gz)" : "${prefix}.aln"
    """
    learnMSA \\
        $args \\
        -i <(unpigz -cdf $fasta) \\
        -o $write_output

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        learnmsa: \$(learnMSA -h | grep 'version' | awk -F 'version ' '{print \$2}' | awk '{print \$1}' | sed 's/)//g')
        pigz: \$(echo \$(pigz --version 2>&1) | sed 's/^.*pigz\\w*//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.aln${compress ? '.gz' : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        learnmsa: \$(learnMSA -h | grep 'version' | awk -F 'version ' '{print \$2}' | awk '{print \$1}' | sed 's/)//g')
        pigz: \$(echo \$(pigz --version 2>&1) | sed 's/^.*pigz\\w*//' ))
    END_VERSIONS
    """
}
