<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-multiplesequencealign_logo_dark.png">
    <img alt="nf-core/multiplesequencealign" src="docs/images/nf-core-multiplesequencealign_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/multiplesequencealign/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/multiplesequencealign/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/multiplesequencealign/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/multiplesequencealign/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/multiplesequencealign/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/multiplesequencealign)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23multiplesequencealign-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/multiplesequencealign)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/multiplesequencealign** is a pipeline to deploy and systematically evaluate Multiple Sequence Alignment (MSA) methods.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

<!-- TODO nf-core: Add full-sized test dataset and amend the paragraph below if applicable -->

On release, automated continuous integration tests run the pipeline on a full-sized dataset on the AWS cloud infrastructure. This ensures that the pipeline runs on AWS, has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.The results obtained from the full-sized test can be viewed on the [nf-core website](https://nf-co.re/proteinfold/results).

![Alt text](docs/images/nf-core-msa_metro_map.png?raw=true "nf-core-msa metro map")

1. **Collect Input Information**: computation of summary statistics on the input fasta file, such as the average sequence similarity across the input sequences, their length, etc. Skip by --skip_stats.
2. **Guide Tree**: (Optional, depends on alignment tools requirement) Renders a guide tree.
3. **Align**: Runs one or multiple MSA tools in parallel.
4. **Evaluate**: The obtained alignments are evaluated with different metrics: Sum Of Pairs (SoP), Total Column score (TC), iRMSD, Total Consistency Score (TCS), etc. Skip by --skip_eval.
5. **Compress**: As the final MSA files are very large, compression tools will be used before storing the final result. Skip by --skip_compress.

Available GUIDE TREE methods:

- CLUSTALO
- FAMSA

Available ALIGN methods:

- CLUSTALO
- FAMSA
- TCOFFEE
- 3DCOFFEE
- MAFFT
- KALIGN
- LEARNMSA
- MTMALIGN
- MUSCLE5

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
id,fasta,reference,structures
seatoxin,seatoxin.fa,seatoxin-ref.fa,seatoxin_structures
toxin,toxin.fa,toxin-ref.fa,toxin_structures
```

Each row represents a set of sequences (in this case the seatoxin and toxin protein families) to be processed.

`id` is the name of the set of sequences. It can correspond to the protein family name or to an internal id.

The column `fasta` contains the path to the fasta file that contains the sequences.

The column reference is optional and contains the path to the reference alignment. It is used for certain evaluation steps. It can be left empty.

The column structures is also optional and contains the path to the folder that contains the protein structures for the sequences to be aligned. It is used for structural aligners and certain evaluation steps. It can be left empty.

Then, you should prepare a toolsheet which defines which tools to run as follows:

`toolsheet.csv`:

```csv
tree,args_tree,aligner,args_aligner,
FAMSA, -gt upgma -partree, FAMSA,
, ,TCOFFEE, -output fasta_aln
```

Now, you can run the pipeline using:

```bash
nextflow run nf-core/multiplesequencealign \
   -profile test \
   --input samplesheet.csv \
   --tools toolsheet.csv \
   --outdir outdir
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/multiplesequencealign/usage) and the [parameter documentation](https://nf-co.re/multiplesequencealign/parameters).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/multiplesequencealign/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/multiplesequencealign/output).

## Credits

nf-core/multiplesequencealign was originally written by Luisa Santus ([@luisas](https://github.com/luisas)) and Jose Espinosa-Carrasco ([@JoseEspinosa](https://github.com/JoseEspinosa)) from The Comparative Bioinformatics Group at The Centre for Genomic Regulation, Spain.

The following people have significantly contributed to the development of the pipeline and its modules: Leon Rauschning ([@lrauschning](https://github.com/lrauschning)), Alessio Vignoli ([@alessiovignoli](https://github.com/alessiovignoli)) and Leila Mansouri ([@l-mansouri](https://github.com/l-mansouri)).

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#multiplesequencealign` channel](https://nfcore.slack.com/channels/multiplesequencealign) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/multiplesequencealign for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
