process MTMALIGN_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta) , path(fasta)
    tuple val(meta3), path(structures)

    output:
    tuple val (meta), path ("*.aln"), emit: msa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "Running mtmalign"
    grep -o "^>.*" "$fasta" | sed 's/^>//g' | sed 's/\$/.pdb/' > "mtmalign_list.txt"
    mTM-align -i mtmalign_list.txt -o sup

    # remove .pdb from ids
    sed 's/.pdb//g' mTM_result/result.fasta > ${prefix}.aln
    """
}
