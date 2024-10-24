# nf-core/multiplesequencealign: Usage

## :warning: Please read this documentation on the nf-core website: [https://nf-co.re/multiplesequencealign/usage](https://nf-co.re/multiplesequencealign/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Overview

**nf-core/multiplesequencealign** is a pipeline to deploy and systematically evaluate Multiple Sequence Alignment (MSA) methods.

The main steps of the pipeline are:

1. **Input files summary**: (Optional) computation of summary statistics on the input fasta file, such as the average sequence similarity across the input sequences, their length, etc. Skipped by the `--skip_stats` parameter.
2. **Guide Tree**: (Optional) Renders a guide tree. Only run if provided in the toolsheet input.
3. **Align**: aligns the sequences.
4. **Evaluate**: (Optional) The obtained alignments are evaluated with different metrics: Sum Of Pairs (SoP), Total Column score (TC), iRMSD, Total Consistency Score (TCS), etc. Skipped by passing `--skip_eval` as a parameter.
5. **Report**: Reports about the collected information of the runs are reported in a Shiny app and a summary table in MultiQC. These processes can be skipped by passing `--skip_shiny` and `--skip_multiqc`, respectively.

## 1. Input files summary statistics

This step generates the summary information about the input files and can be skipped using the `--skip_stats` parameter. The optional computed metrics are:

1. **Sequence similarity**: This step calculates pairwise and average sequence similarity using TCOFFEE. Activate with `--calc_sim` (default: `false`).
2. **General summary**: Calculates the number and the average length of sequences. Activate with `--calc_seq_stats` (default: `true`).
3. **Extract plddt**: If the structures were generated using AF2, plddt is extracted and reported. Activate with `--extract_plddt` (default: `false`).

## 2. Guide trees

Guide trees define the order in which sequences and profiles are aligned and play a crucial role in determining the final MSA accuracy. Tree rendering techniques most commonly rely on pairwise distances between sequences.

> **Note**
> None of the aligners listed below need an explicit definition of a guide tree: if they require one, they compute their own default guide tree. However, an explicit definition of a guide tree is available in case you want to test non-default combination of guide trees and aligner methods.

Currently available GUIDE TREE methods are: (Optional):

- [CLUSTALO](http://clustal.org/omega/#Documentation)
- [FAMSA](https://github.com/refresh-bio/FAMSA)

### 3. Align

The available assembly methods are listed below (those that accept guide trees indicate it in parentheses):

**sequence-based** (only require a fasta file as input):

- [CLUSTALO](http://clustal.org/omega/#Documentation) (accepts guide tree)
- [FAMSA](https://github.com/refresh-bio/FAMSA) (accepts guide tree)
- [KALIGN](https://github.com/TimoLassmann/kalign)
- [LEARNMSA](https://github.com/Gaius-Augustus/learnMSA)
- [MAFFT](https://mafft.cbrc.jp/alignment/server/index.html)
- [MAGUS](https://github.com/vlasmirnov/MAGUS) (accepts guide tree)
- [MUSCLE5](https://drive5.com/muscle5/manual/)
- [TCOFFEE](https://tcoffee.readthedocs.io/en/latest/index.html) (accepts guide tree)
- [REGRESSIVE](https://tcoffee.readthedocs.io/en/latest/tcoffee_quickstart_regressive.html) (accepts guide tree)
- [UPP](https://github.com/smirarab/sepp) (accepts guide tree)

**sequence- and structure-based** (require both fasta and structures as input):

- [3DCOFFEE](https://tcoffee.org/Projects/expresso/index.html) (accepts guide tree)

**structure-based** (only require stuctures as input):

- [MTMALIGN](https://bio.tools/mtm-align)
- [FOLDMASON](https://github.com/steineggerlab/foldmason)

Optionally, [M-COFFEE](https://tcoffee.org/Projects/mcoffee/index.html) will combine the output of all alignments into a consensus MSA (`--build_consensus`).

### 4. Evaluate

Optionally, the produced MSAs will be evaluated. This step can be skipped using the `--skip_eval` parameter. The evaluations implemented are listed below.

**sequence-based** (no extra input required):

1. **Number of gaps**. Calculates the number of gaps and its average across sequences. Activate using `--calc_gaps` (default: `true`).

**reference-based**:

The reference MSAs (see samplesheet) are used to evaluate the quality of the produced MSA.

2. **Sum Of Pairs (SP)**. Calculates the SP score using the [TCOFFEE](https://tcoffee.readthedocs.io/en/latest/tcoffee_main_documentation.html#comparing-alternative-alignments) implementation. Activated using `--calc_sp` (default: `true`).
3. **Total column (TC)**. Calculates the TC score [TCOFFEE](https://tcoffee.readthedocs.io/en/latest/tcoffee_main_documentation.html#comparing-alternative-alignments). Activate using `--calc_tc` (default: `true`).

**structure-based**:

The provided structures (see samplesheet) are used to evaluate the quality of the alignment.

4. **iRMSD**: Calculates the iRMSD using the [TCOFFEE](https://tcoffee.readthedocs.io/en/latest/tcoffee_main_documentation.html#apdb-irmsd) implementation. Activate using `--calc_irmsd` (default: false).

### 5. Report

Finally, a summary table with all the computed statistics and evaluations is reported in MultiQC (skip by using `--skip_multiqc`).
Moreover, a Shiny app is generated with interactive summary plots (skip with `--skip_shiny`).

:::warning
You will need to have [Shiny](https://shiny.posit.co/py/) installed to run it! See [output documentation](https://nf-co.re/multiplesequencealign/output) for more info.
:::

## Samplesheet input

The sample sheet defines the **input data** that the pipeline will process.
It should look like this:

```csv title="samplesheet.csv"
id,fasta,reference,dependencies,template
seatoxin,seatoxin.fa,seatoxin-ref.fa,seatoxin_structures,seatoxin_template.txt
toxin,toxin.fa,toxin-ref.fa,toxin_structures,toxin_template.txt
```

Each row represents a set of sequences (in this case the seatoxin and toxin protein families) to be processed.

| Column         | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`           | Required. Name of the set of sequences. It can correspond to the protein family name or to an internal id. It must be unique.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `fasta`        | Required (At least one of fasta or dependencies must be provided). Full path to the fasta file that contains the sequence to be aligned.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `reference`    | Optional. Full path to the reference alignment. It is used for the reference-based evaluation steps. It can be left empty.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `dependencies` | Required (At least one of fasta or dependencies must be provided). Full path to the folder that contains the dependency files (e.g. protein structures) for the sequences to be aligned. Currently, it is used for structural aligners and structure-based evaluation steps. It can be left empty.                                                                                                                                                                                                                                                                                                                                                                                                 |
| `template`     | Optional. Files that define the mapping between the input sequence and the dependency files (e.g. protein structures) to be used. Used by 3D-Coffee. If not specified, they will be automatically generated assuming that the sequence name provided in the fasta is the same as the file name of the corresponding PDB file. E.g. if you set (default) the parameter templates_suffix to .pdb, then: ">MyProteinName" in the fasta file and "MyProteinName.pdb" for the corresponding protein structure. For more information on how to generate a template file manually, please look at the T-Coffee [documentation](https://tcoffee.readthedocs.io/en/latest/tcoffee_main_documentation.html). |

:::note
You can have some samples with dependencies and/or references and some without. The pipeline will run the modules requiring dependencies/references only on the samples for which you have provided the required information and the others will be just skipped.
:::

## Toolsheet input

We provide a toolsheet as input to facilitate testing multiple arguments per tool when using the pipeline as a benchmarking framework. This, enables having multiple entries in the toolsheet, each corresponding to different arguments to be tested for the same tool.

Each line of the toolsheet defines a combination of guide tree and multiple sequence aligner to run with the respective arguments to be used.

A typical toolsheet should look at follows:

```csv title="toolsheet.csv"
tree,args_tree,aligner,args_aligner,
FAMSA, -gt upgma -medoidtree, FAMSA,
, ,TCOFFEE,
FAMSA,,REGRESSIVE,
```

:::note
Each of the trees and aligners are available as standalones. You can leave `args_tree` and `args_aligner` empty if you are cool with the default settings of each method. Alternatively, you can leave `args_tree` empty to use the default guide tree with each aligner.
:::

:::note
use the exact spelling as listed above in [align](#3-align) and [guide trees](#2-guide-trees)!
:::

`tree` is the tool used to build the tree (optional).

Arguments to the tree tool can be provided using `args_tree`. Please refer to each tool's documentation (optional).

The `aligner` column contains the tool to run the alignment (optional).

Finally, the arguments to the aligner tool can be set by using the `args_aligner` column (optional).

| Column         | Description                                                                      |
| -------------- | -------------------------------------------------------------------------------- |
| `tree`         | Optional. Tool used to build the tree.                                           |
| `args_tree`    | Optional. Arguments to the tree tool. Please refer to each tool's documentation. |
| `aligner`      | Required. Tool to run the alignment. Available options listed above.             |
| `args_aligner` | Optional. Arguments to the alignment tool.                                       |

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/multiplesequencealign --input ./samplesheet.csv --tools ./toolsheet.csv --outdir ./results -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/multiplesequencealign -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
tools: "./toolsheet.csv"
outdir: './results/'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/multiplesequencealign
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/multiplesequencealign releases page](https://github.com/nf-core/multiplesequencealign/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, >nor institutional specific profiles.
:::

## Core Nextflow arguments

:::tip
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
