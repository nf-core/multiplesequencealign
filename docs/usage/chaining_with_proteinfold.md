# Using nf-core/proteinfold to generate the input protein structures

Structural aligners leverage protein structural information to render the final MSA. 

You can provide your PDB structures via the samplesheet, as outlined in the primary usage documentation. However, if you do not already have protein structures available, you may opt to use protein structure prediction tools to create these models.

To facilitate this, we offer seamless integration with the nf-core/proteinfold pipeline, enabling you to generate the protein structures required for this workflow. 

To do so, you only need to build one samplesheet file, in the exact format required by nf-core/multiplesequencealign pipeline.
This is made compatible with nf-core/proteinfold :) 

Now, to run you simply can use the following code.


```bash
nextflow run nf-core/proteinfold --input ./samplesheet.csv \
                                 --split_fasta \
                                 -r dev \
                                 --outdir ./proteinfold_results \
                                 -profile <singularity/docker/conda> \
                                 -c your_proteinfold_config.config


nextflow run nf-core/multiplesequencealign --input ./samplesheet.csv \
                                           --tools ./toolsheet.csv \
                                           --dependencies_dir ./proteinfold_results
                                           --outdir ./results \
                                           -profile <singularity/docker/conda> \
                                           -c your_msa_config.config

```

