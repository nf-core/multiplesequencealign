## FAQs

### INPUT

<details>
  <summary> Where can I find some example input data?  </summary>
    Find some example input data <a href="https://github.com/nf-core/test-datasets/tree/multiplesequencealign">here</a>
</details>

<details>
  <summary> What happens if I have the only PDBs and not the corresponding fasta files?  </summary>

No problem, you can provide the PDBs as input (either via the samplesheet using the optional_data column or via the flag <code>--pdbs_dir</code>).

The flag <code>--skip_pdbcoversion</code> false will make sure that the fasta file is automatically extracted from the provided PDBs and subsequently used in the pipeline.

  <pre><code> nextflow run nf-core/multiplesequencealign \
      -profile easy_deploy,docker \
      --pdbs_dir YOUR_PDB_DIR \
      --aligner FAMSA \
      --tree CLUSTALO \
      --outdir results \
      --skip_pdbconversion false </code></pre>

</details>

### USE CASES

<details>
  <summary> I want to deploy one tool on one dataset. I am not interested in any evaluation, report etc. </summary>

You should use the easy_deploy profile!

This will skip all the evaluation, reporting etc. step and keep the deployment to the minimum.

The following example: running FAMSA (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

  <pre><code>nextflow run nf-core/multiplesequencealign \
  -profile easy_deploy,docker \
  --seqs YOUR_FASTA \
  --aligner FAMSA \
  --args_aligner "-refine_mode on" \
  --tree CLUSTALO \
  --outdir results</code></pre>

You can leave the <code>--tree</code> and <code>--args_aligner</code> and <code>--args_tree</code> empty (just do not use the flags). Default values will be used.

Change the profile from docker to singularity or your preferred choice!

</details>

<details>
  <summary> I want to deploy one tool on one dataset. I want to run a structural aligner. </summary>

The following example: running FOLDMASON (with arguments -refine_mode on) using the guidetree built using CLUSTALO.

  <pre><code>nextflow run nf-core/multiplesequencealign \
  -profile easy_deploy,docker \
  --pdbs_dir YOUR_PDB_DIR\
  --aligner FOLDMASON \
  --tree CLUSTALO \
  --outdir results</pre></code>

You can leave the <code>--tree</code> and <code>--args_aligner</code> and <code>--args_tree</code> empty (just do not use the flags). Default values will be used.
Foldmason is just an example, you can pick any other structural aligner.

</details>

<details>
  <summary> One dataset, multiple tools. </summary>
  You should use the <a href="https://nf-co.re/multiplesequencealign/usage/#toolsheet-input">toolsheet</a> to specify the tools use.

  <pre><code>nextflow run nf-core/multiplesequencealign \
  -profile easy_deploy,docker \
  --seqs YOUR_FASTA\
  --tools YOUR_TOOLSHEET\
  --outdir results</pre></code>

Your input dataset can be passed via the <code>--seqs</code> or <code>--pdbs_dir</code>, as explained in the examples above.

</details>

<details>
  <summary> Can i run the same tool multiple times with different arguments?  </summary>

    Absolutely yes! Create different rows in the toolsheet and add different arguments in the args_aligner column.

</details>

<details>
  <summary> Can i run a structural evaluation on sequence-based aligners?  </summary>

Yes, as long as you provide the structures, either via the samplesheet or via the <code>--pdbs_dir</code> flag.

You can also run proteinfold before to get your structures, in case you do not have them already.
<a href="https://nf-co.re/multiplesequencealign/usage/#toolsheet-input"> Here </a> instructions on how to do it.

</details>
