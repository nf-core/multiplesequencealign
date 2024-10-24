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

**nf-core/multiplesequencealign** is a pipeline to deploy and systematically evaluate Multiple Sequence Alignment (MSA) methods.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/proteinfold/results).

![Alt text](docs/images/nf-core-msa_metro_map.png?raw=true "nf-core-msa metro map")

The pipeline performs the following steps:

1. **Input files summary**: (Optional) computation of summary statistics on the input files, such as the average sequence similarity across the input sequences, their length, plddt extraction if available.

2. **Guide Tree**: (Optional) Renders a guide tree with a chosen tool (list available in [usage](docs/usage.md#2-guide-trees)). Some aligners use guide trees to define the order in which the sequences are aligned.
3. **Align**: (Required) Aligns the sequences with a chosen tool (list available in [usage](docs/usage.md#3-align)).
4. **Evaluate**: (Optional) Evaluates the generated alignments with different metrics: Sum Of Pairs (SoP), Total Column score (TC), iRMSD, Total Consistency Score (TCS), etc.
5. **Report**: Reports the collected information of the runs in a Shiny app and a summary table in MultiQC.

## Usage

:::note
If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.
:::

#### 1. SAMPLESHEET

The sample sheet defines the **input data** that the pipeline will process.
It should look like this:

`samplesheet.csv`:

```csv
id,fasta,reference,dependencies,template
seatoxin,seatoxin.fa,seatoxin-ref.fa,seatoxin_structures,seatoxin_template.txt
toxin,toxin.fa,toxin-ref.fa,toxin_structures,toxin_template.txt
```

Each row represents a set of sequences (in this case the seatoxin and toxin protein families) to be aligned and the associated (if available) reference alignments and dependency files (this can be anything from protein structure or any other information you would want to use in your favourite MSA tool).

:::note
The only required input is the id column and either fasta or dependencies.
:::

#### 2. TOOLSHEET

The toolsheet specifies **which combination of tools will be deployed and benchmark in the pipeline**.
Each line of the toolsheet defines a combination of guide tree and multiple sequence aligner to run with the respective arguments to be used.
The only required field is `aligner`. The fields `tree`, `args_tree` and `args_aligner` are optional and can be left empty.

It should look at follows:

`toolsheet.csv`:

```csv
tree,args_tree,aligner,args_aligner,
FAMSA, -gt upgma -medoidtree, FAMSA,
, ,TCOFFEE,
FAMSA,,REGRESSIVE,
```

:::note
The only required input is aligner.
:::

#### 3. RUN THE PIPELINE

Now, you can run the pipeline using:

```bash
nextflow run nf-core/multiplesequencealign \
   -profile test,docker \
   --input samplesheet.csv \
   --tools toolsheet.csv \
   --outdir outdir
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/multiplesequencealign/usage) and the [parameter documentation](https://nf-co.re/multiplesequencealign/parameters).

## Pipeline output

To see the results of an example test run with a full-size dataset refer to the [results](https://nf-co.re/multiplesequencealign/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/multiplesequencealign/output).

## Extending the pipeline

For details on how to add your favourite guide tree, MSA or evaluation step in nf-core/multiplesequencealign please refer to the [extending documentation](docs/extending.md).

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
