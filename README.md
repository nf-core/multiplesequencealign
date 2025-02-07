<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-multiplesequencealign_logo_dark.png">
    <img alt="nf-core/multiplesequencealign" src="docs/images/nf-core-multiplesequencealign_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/multiplesequencealign/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/multiplesequencealign/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/multiplesequencealign/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/multiplesequencealign/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/multiplesequencealign/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.13889386-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.13889386)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/multiplesequencealign)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23multiplesequencealign-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/multiplesequencealign)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

Use **nf-core/multiplesequencealign** to:

1. **Deploy** one (or many in parallel) of the most popular Multiple Sequence Alignment (MSA) tools.
2. **Benchmark** MSA tools (and their inputs) using various metrics.

Main steps:

  <details>
      <summary><strong>Inputs summary</strong> (Optional)</summary>
      <p>Computation of summary statistics on the input files (e.g., average sequence similarity across the input sequences, their length, pLDDT extraction if available).</p>
  </details>

  <details>
      <summary><strong>Guide Tree</strong> (Optional)</summary>
      <p>Renders a guide tree with a chosen tool (list available in <a href="docs/usage.md#2-guide-trees">usage</a>). Some aligners use guide trees to define the order in which the sequences are aligned.</p>
  </details>

  <details>
      <summary><strong>Align</strong> (Required)</summary>
      <p>Aligns the sequences with a chosen tool (list available in <a href="docs/usage.md#3-align">usage</a>).</p>
  </details>

  <details>
      <summary><strong>Evaluate</strong> (Optional)</summary>
      <p>Evaluates the generated alignments with different metrics: Sum Of Pairs (SoP), Total Column score (TC), iRMSD, Total Consistency Score (TCS), etc.</p>
  </details>

  <details>
      <summary><strong>Report</strong>(Optional)</summary>
      <p>Reports the collected information of the runs in a Shiny app and a summary table in MultiQC. Optionally, it can also render the <a href="https://github.com/steineggerlab/foldmason">Foldmason</a> MSA visualization in HTML format.</p>
  </details>

![Alt text](docs/images/nf-core-msa_metro_map.png?raw=true "nf-core-msa metro map")

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

### Quick start - test run

To get a feeling of what the pipeline does, run:

(No need to download or provide any file, try it!)

```
nextflow run nf-core/multiplesequencealign \
   -profile test,docker \
   --outdir results
```

## How to set up an easy run:

> [!NOTE]
> We have a lot more of use cases examples under [FAQs]("https://nf-co.re/multiplesequencealign/usage/FAQs)

### Input data

You can provide either (or both) a **fasta** file or a set of **protein structures**.

Alternatively, you can provide a [samplesheet](https://nf-co.re/multiplesequencealign/usage/#samplesheet-input) and a [toolsheet](https://nf-co.re/multiplesequencealign/usage/#toolsheet-input). 

See below how to provide them. 

> Find some example input data [here](https://github.com/nf-core/test-datasets/tree/multiplesequencealign)

### CASE 1: One input dataset, one tool.

If you only have one dataset and want align it using one specific MSA tool (e.g. FAMSA or FOLDMASON):

Your input is a fasta file ([example](https://github.com/nf-core/test-datasets/blob/multiplesequencealign/testdata/setoxin-ref.fa))? Then:

```bash
nextflow run nf-core/multiplesequencealign \
   -profile easy_deploy,docker \
   --seqs <YOUR_FASTA.fa> \
   --aligner FAMSA \
   --outdir outdir
```

Your input is a directory where your PDB files are stored ([example](https://github.com/nf-core/test-datasets/blob/multiplesequencealign/testdata/af2_structures/seatoxin-ref.tar.gz))? Then:

```bash
nextflow run nf-core/multiplesequencealign \
   -profile easy_deploy,docker \
   --pdbs_dir <PATH_TO_YOUR_PDB_DIR> \
   --aligner FOLDMASON \
   --outdir outdir
```

<details>
  <summary> FAQ: Which are the available tools I can use?</summary>
  Check the list here: <a href="https://nf-co.re/multiplesequencealign/usage/#2-guide-trees"> available tools</a>.
</details>

<details>
  <summary> FAQ: Can I use both <em>--seqs</em> and <em>--pdbs_dir</em>?</summary>
  Yes, go for it! This might be useful if you want a structural evaluation of a sequence-based aligner for instance.
</details>

<details>
  <summary> FAQ: Can I specify also which guidetree to use? </summary>
  Yes, use the --tree flag. More info: <a href="https://nf-co.re/multiplesequencealign/usage">usage</a> and <a href="https://nf-co.re/multiplesequencealign/parameters">parameters</a>.
</details>

<details>
  <summary> FAQ: Can I specify the arguments of the tools (tree and aligner)? </summary>
  Yes, use the --args_tree and --args_aligner flags. More info: <a href="https://nf-co.re/multiplesequencealign/usage">usage</a> and <a href="https://nf-co.re/multiplesequencealign/parameters">parameters</a>.
</details>

### CASE 2: Multiple datasets, multiple tools.

```bash
nextflow run nf-core/multiplesequencealign \
   -profile test,docker \
   --input <samplesheet.csv> \
   --tools <toolsheet.csv> \
   --outdir outdir
```

You need **2 input files**:

- **samplesheet** (your datasets)
- **toolsheet** (which tools you want to use).

<details>
  <summary> What is a samplesheet?</summary>
  The sample sheet defines the <b>input datasets</b> (sequences, structures, etc.) that the pipeline will process.

A minimal version:

```csv
id,fasta
seatoxin,seatoxin.fa
toxin,toxin.fa
```

A more complete one:

```csv
id,fasta,reference,optional_data
seatoxin,seatoxin.fa,seatoxin-ref.fa,seatoxin_structures
toxin,toxin.fa,toxin-ref.fa,toxin_structures
```

Each row represents a set of sequences (in this case the seatoxin and toxin protein families) to be aligned and the associated (if available) reference alignments and dependency files (this can be anything from protein structure or any other information you would want to use in your favourite MSA tool).

Please check: <a href="https://nf-co.re/multiplesequencealign/usage/#samplesheet-input">usage</a>.

> [!NOTE]
> The only required input is the id column and either fasta or optional_data.

</details>

<details>
  <summary> What is a toolsheet?</summary>
  The toolsheet specifies **which combination of tools will be deployed and benchmark in the pipeline**.

Each line defines a combination of guide tree and multiple sequence aligner to run with the respective arguments to be used.

The only required field is `aligner`. The fields `tree`, `args_tree` and `args_aligner` are optional and can be left empty.

A minimal version:

```csv
tree,args_tree,aligner,args_aligner
,,FAMSA,
```

This will run the FAMSA aligner.

A more complex one:

```csv
tree,args_tree,aligner,args_aligner
FAMSA, -gt upgma -medoidtree, FAMSA,
, ,TCOFFEE,
FAMSA,,REGRESSIVE,
```

This will run, in parallel:

- the FAMSA guidetree with the arguments <em>-gt upgma -medoidtree</em>. This guidetree is then used as input for the FAMSA aligner.
- the TCOFFEE aligner
- the FAMSA guidetree with default arguments. This guidetree is then used as input for the REGRESSIVE aligner.

Please check: <a href="https://nf-co.re/multiplesequencealign/usage/#toolsheet-input">usage</a>.

> [!NOTE]
> The only required input is `aligner`.

</details>

For more details on more advanced runs: [usage documentation](https://nf-co.re/multiplesequencealign/usage) and the [parameter documentation](https://nf-co.re/multiplesequencealign/parameters).

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Pipeline output

Example results: [results](https://nf-co.re/multiplesequencealign/results) tab on the nf-core website pipeline page.
For more details: [output documentation](https://nf-co.re/multiplesequencealign/output).

## Extending the pipeline

For details on how to add your favourite guide tree, MSA or evaluation step in nf-core/multiplesequencealign please refer to the [extending documentation](docs/usage/adding_a_tool.md).

## Credits

nf-core/multiplesequencealign was originally written by Luisa Santus ([@luisas](https://github.com/luisas)) and Jose Espinosa-Carrasco ([@JoseEspinosa](https://github.com/JoseEspinosa)) from The Comparative Bioinformatics Group at The Centre for Genomic Regulation, Spain.

The following people have significantly contributed to the development of the pipeline and its modules: Leon Rauschning ([@lrauschning](https://github.com/lrauschning)), Alessio Vignoli ([@alessiovignoli](https://github.com/alessiovignoli)), Igor Trujnara ([@itrujnara](https://github.com/itrujnara)) and Leila Mansouri ([@l-mansouri](https://github.com/l-mansouri)).

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#multiplesequencealign` channel](https://nfcore.slack.com/channels/multiplesequencealign) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/multiplesequencealign for your analysis, please cite it using the following doi: [10.5281/zenodo.13889386](https://doi.org/10.5281/zenodo.13889386)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
