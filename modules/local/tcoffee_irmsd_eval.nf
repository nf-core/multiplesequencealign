
process TCOFFEE_IRMSD_EVAL {
    tag "$meta.family"
    label 'process_low'

    // TODO: change to the correct container

    input:
    tuple  val(meta), file (msa), file (ref_msa), file(structures)

    output:
    tuple val(meta), path ("*.total_irmsd"), emit: scores
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    # Prep templates
    for i in `awk 'sub(/^>/, "")' ${msa}`; do
        id_pdb=`echo \$i |  sed 's./._.g'`;  echo -e ">"\$i "_P_" "\${id_pdb}" >> template_list.txt
    done

    # Comp irmsd
    t_coffee -other_pg irmsd $msa -template_file template_list.txt | grep "TOTAL" > ${msa.baseName}.total_irmsd


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}