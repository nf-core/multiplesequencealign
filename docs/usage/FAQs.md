## Here a collection of usecases and FAQs

## TODO: replace main.nf with nf-core/multiplesequencealign and test.fa with <<YOUR_FASTA.fa>>

<details>
  <summary> I want to deploy one tool on one dataset. I am not interested in any evaluation, report etc. </summary>

    You should use the easy_deploy profile!

    Running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

    nextflow run main.nf \
    -profile easy_deploy,docker \
    --seqs test.fa \
    --aligner FAMSA \
    --args_aligner "-refine_mode on" \
    --tree CLUSTALO \
    --outdir results

    You can leave the --tree and --args_aligner and --args_tree empty (just do not use the flags). Default values will be used.

    Change the profile from docker to singularity or your preferred choice!

</details>

<details>
  <summary> I want to deploy one tool on one dataset. I want to run a structural aligner. </summary>

    Running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

    nextflow run main.nf \
    -profile easy_deploy,docker \
    --seqs test.fa \
    --aligner FAMSA \
    --args_aligner "-refine_mode on" \
    --tree CLUSTALO \
    --outdir results

    You can leave the --tree and --args_aligner and --args_tree empty (just do not use the flags). Default values will be used.

</details>


Can i run the same tool multiple times with different arguments? 

Can i run a structural evaluation on sequence based aligners? 

How can I run one dataset on multiple tools? 

How can I run one 

What happens if i have the pdbs only and not the fasta?
What if i cannot download the large container?