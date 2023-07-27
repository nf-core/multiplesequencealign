process TCOFFEE3D_TMALIGN_ALIGN {
    tag "$meta.family _ $meta_run.align _ $meta_run.args_align"
    label 'process_low'

    // TODO: change to the correct container

    input:
    tuple val(meta), val(meta_tree), val(meta_run), path(fasta), path(tree), path (structures)
    

    output:
    tuple val(meta), val(meta_tree), val(meta_run), path ("*.aln"), emit: msa
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''
    def args_meta = meta_run.args_align == 'none' ? '' : meta_run.args_align
    def args_align_clean = cleanargs(meta_run.args_align)
    def args_tree_clean = cleanargs(meta_tree.args_tree)
    def prefix = task.ext.prefix ?: "${meta.family}_${meta_tree.tree}-args-${args_tree_clean}_${meta_tree.align}-args-${args_align_clean}"
    
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


def cleanargs(String argstring) {

    cleanargs = argstring.strip().replaceAll(/-/, '')
                         .replaceAll(/ /, '=')
                         .replaceAll(/==/, '=')
                         .replaceAll(/ /, '')


    return cleanargs
}
