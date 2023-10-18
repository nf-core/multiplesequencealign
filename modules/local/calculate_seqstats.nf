
process CALCULATE_SEQSTATS {
    tag "$meta.id"
    label 'process_low'

    conda "bioconda::metabat2=2.15 conda-forge::python=3.6.7 conda-forge::biopython=1.74 conda-forge::pandas=1.1.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-e25d1fa2bb6cbacd47a4f8b2308bd01ba38c5dd7:75310f02364a762e6ba5206fcd11d7529534ed6e-0' :
        'biocontainers/mulled-v2-e25d1fa2bb6cbacd47a4f8b2308bd01ba38c5dd7:75310f02364a762e6ba5206fcd11d7529534ed6e-0' }"
    
    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_seqstats.csv"), emit: seqstats
    tuple val(meta), path("*_seqstats_summary.csv"), emit: seqstats_summary
    path "versions.yml" , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def id = meta.id
    """
    calc_seqstats.py $id ${fasta} "${prefix}_seqstats.csv" "${prefix}_seqstats_summary.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}


