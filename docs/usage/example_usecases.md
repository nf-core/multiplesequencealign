## Here a collection of usecases and FAQs

## TODO: replace main.nf with nf-core/multiplesequencealign and test.fa with <<YOUR_FASTA.fa>>

<details>
  <summary> I want to deploy one tool on one dataset. I am not interested in any evaluation, report etc. </summary>

    Running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

    nextflow run main.nf \
    -profile docker \
    --seqs test.fa \
    --aligner FAMSA \
    --args_aligner "-refine_mode on" \
    --tree CLUSTALO \
    --outdir outdir \
    --skip_stats \
    --skip_eval \
    --skip_preprocessing \
    --skip_multiqc \
    --skip_visualisation

    You can leave the --tree and --args_aligner and --args_tree empty (just do not use the flags). Default values will be used.

</details>


<details>
  <summary> I want to deploy one tool on one dataset. I want to run a structural aligner. </summary>

    Running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

    nextflow run nf-core/multiplesequencealign \
    -profile docker \
    --seqs <YOUR_FASTA.fa> \
    --aligner FAMSA \
    --args_aligner "-refine_mode on" \
    --tree CLUSTALO \
    --outdir outdir \
    --skip_stats \ 
    --skip_eval \
    --skip_preprocessing \
    --skip_multiqc \
    --skip_visualisation

    You can leave the --tree and --args_aligner and --args_tree empty (just do not use the flags). Default values will be used.

</details>
