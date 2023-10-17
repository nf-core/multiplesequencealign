process CREATE_TCOFFEETEMPLATE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(accessory_informations)

    output:
    tuple val (meta), path("*_template.txt"), emit: template

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Prep templates
    for structure in \$(ls *.pdb); do id=`echo \$structure| awk  {'gsub(".pdb", "", \$0); print'}`; echo -e ">"\$id "_P_" "\${id}" >>${prefix}_template.txt ; done
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_template.txt
    """
}
