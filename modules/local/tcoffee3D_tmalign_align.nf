process TCOFFEE_ALIGN {
    tag "$meta.id _ $meta.align _ $meta.args_align"
    label 'process_medium'

    input:
    tuple val(meta) ,  path(fasta)
    tuple val(meta2),  path(tree)
    tuple val(meta3),  path(template), path(structures)

    output:
    tuple val (meta), path ("*.aln"), emit: msa
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Prep templates
    for i in `awk 'sub(/^>/, "")' ${fasta}`; do
        id_pdb=`echo \$i |  sed 's./._.g'`;  echo -e ">"\$i "_P_" "\${id_pdb}" >> template_list.txt
    done

    t_coffee ${fasta} -method TMalign_pair -template_file "template_list.txt" -out_lib ${prefix}.lib -output fasta_aln -outfile ${prefix}.aln


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        t_coffee: \$( t_coffee -version | sed 's/.*(Version_\\(.*\\)).*/\\1/' )
    END_VERSIONS
    """
}

