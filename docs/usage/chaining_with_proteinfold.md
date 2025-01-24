# Using nf-core/proteinfold to generate the input protein structures

Structural aligners leverage protein structural information to render the MSA.

You can provide your PDB structures via the samplesheet, as outlined in the primary usage documentation. However, if you do not already have protein structures available, you may opt to use protein structure prediction tools to create these models.

To facilitate this, we offer seamless integration with the nf-core/proteinfold pipeline, enabling you to generate the protein structures required for this workflow.

To do so, you only need to build one samplesheet file, in the exact format required by nf-core/multiplesequencealign pipeline.
This is made compatible with nf-core/proteinfold and will predict and output the structures in the format required by the nf-core/multiplesquencealign pipeline.

Now, to run you simply can use the following code.

> [!NOTE]
> Please refer to the [proteinfold documentation](https://nf-co.re/proteinfold/1.1.1/) for picking your favourite params.

Here we showcase how to run proteinfold in its colabfold local flavour - but it works for all the proteinfold modes.

```bash
nextflow run nf-core/proteinfold \
   --input ./samplesheet.csv \
   --outdir ./proteinfold_results \
   --split_fasta \
   -r dev \
   --mode colabfold \
   --colabfold_server local \
   --colabfold_db <null (default) | PATH> \
   --num_recycle 3 \
   --use_amber <true/false> \
   --colabfold_model_preset "AlphaFold2-ptm" \
   --use_gpu <true/false> \
   --db_load_mode 0
   -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>


nextflow run nf-core/multiplesequencealign \
   --input ./samplesheet.csv \
   --tools ./toolsheet.csv \
   --optional_data_dir ./proteinfold_results/*/*/top_ranked_structures \
   --outdir ./results \
   -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>

```

> [!NOTE]
> The one imporant parameter NOT to forget in proteinfold for the chaining is `--split_fasta`. This will allow to use a multifasta file as input for monomer predictions, needed by the MSA pipeline.The rest of the proteinfold parameters can and should be tuned according to your preferences for your proteinfold run. Please refer to the proteinfold documentation for this.

> [!WARNING]
> This is currently an experimetal feature and only available in the dev branch of proteinfold, so also do not forget `-r dev`. This feature will be soon available with the next release of nf-core/proteinfold.
