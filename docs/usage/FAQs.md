## Here a collection of usecases and FAQs

## TODO: replace main.nf with nf-core/multiplesequencealign and test.fa with <<YOUR_FASTA.fa>> AND ADD LINK

### INPUTS

### USECASES

<details>
  <summary> Where can I find some example input data?  </summary>
    Find some example input data <a href="https://github.com/nf-core/test-datasets/tree/multiplesequencealign">here</a>
</details>

<details>
  <summary> I want to deploy one tool on one dataset. I am not interested in any evaluation, report etc. </summary>

    You should use the easy_deploy profile!

    This will skip all the evaluation, reporting etc. step and keep the deployment to the minimum.

    The following example: running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

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

    The following example: running FOLDMASON (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

    nextflow run main.nf &\
    -profile easy_deploy,docker \
    --pdbs_dir <YOUR_PDB_DIR>\
    --aligner FOLDMASON \
    --tree CLUSTALO \
    --outdir results

    You can leave the --tree and --args_aligner and --args_tree empty (just do not use the flags). Default values will be used.
    Foldmason is just an example, you can pick any other structural aligner.

</details>

<details>
  <summary> One dataset, multiple tools. </summary>
    You should use the <a href="https://nf-co.re/multiplesequencealign/usage/#toolsheet-input">toolsheet</a> to specify the tools use.

    nextflow run main.nf &\
    -profile easy_deploy,docker \
    --seqs <YOUR_PDB_DIR>\
    --tools <YOUR_TOOLSHEET>\
    --outdir results

Your input dataset can be passed via the --seqs or --pdbs_dir, as explained in the examples above.

</details>

<details>
  <summary> Can i run the same tool multiple times with different arguments?  </summary>

    Absolutely yes! Create different rows in the toolsheet and add different arguments in the args_aligner column.

</details>

<details>
  <summary> Can i run a structural evaluation on sequence-based aligners?  </summary>

    Yes, as long as you provide the structures, either via the samplesheet or via the --pdbs_dir flag.

    You can also run proteinfold before to get your structures, in case you do not have them already.
    <a href="https://nf-co.re/multiplesequencealign/usage/#toolsheet-input">Here</a> instructions on how to do it.
    # ADD LINK

</details>

<details>
  <summary> What happens if I have the only PDBs and not the corresponding fasta files?  </summary>

    No problem, you can provide the PDBs as input (either via the samplesheet using the optional_data column or via the flag --pdbs_dir).

    The flag `--skip_pdbcoversion false` will make sure that the fasta file is automatically extracted from the provided PDBs and subsequently used in the pipeline.

    nextflow run main.nf &\
      -profile easy_deploy,docker \
      --pdbs_dir <YOUR_PDB_DIR>\
      --aligner FAMSA \
      --tree CLUSTALO \
      --outdir results \
      --skip_pdbconversion false

</details>
