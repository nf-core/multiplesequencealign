
process TCOFFEE_IRMSD_EVAL {
    tag "$meta.id"
    label 'process_low'

    // TODO: change to the correct container

    input:
    tuple  val(meta), file (msa), file (ref_msa), file(structures)

    output:
    tuple val(meta), path ("*.total_irmsd.csv"), emit: scores
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def header = meta.keySet().join(",") 
    def values = meta.values().join(",")
    """
    # Prep templates
    for i in `awk 'sub(/^>/, "")' ${msa}`; do
        id_pdb=`echo \$i |  sed 's./._.g'`;  echo -e ">"\$i "_P_" "\${id_pdb}" >> template_list.txt
    done

    # Comp irmsd
    t_coffee -other_pg irmsd $msa -template_file template_list.txt | grep "TOTAL" > ${msa.baseName}.total_irmsd

    # Parse irmsd file
    parsers.py -i ${msa.baseName}.total_irmsd -o ${msa.baseName}.scores.csv

    # Prep metadata file
    echo "${header}" > meta.csv
    echo "${values}" >> meta.csv

    # Add metadata info to output file
    paste -d, meta.csv ${msa.baseName}.scores.csv > ${msa.baseName}.total_irmsd.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}