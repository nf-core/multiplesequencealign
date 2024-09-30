# nf-core/multiplesequencealign: Contributing Guidelines

Hi there!
Many thanks for taking an interest in improving nf-core/multiplesequencealign.

We try to manage the required tasks for nf-core/multiplesequencealign using GitHub issues, you probably came to this page when creating one.
Please use the pre-filled template to save time.

However, don't be put off by this template - other more general issues and suggestions are welcome!
Contributions to the code are even more welcome ;)

> [!NOTE]
> If you need help using or modifying nf-core/multiplesequencealign then the best place to ask is on the nf-core Slack [#multiplesequencealign](https://nfcore.slack.com/channels/multiplesequencealign) channel ([join our Slack here](https://nf-co.re/join/slack)).

## Contribution workflow

If you'd like to write some code for nf-core/multiplesequencealign, the standard workflow is as follows:

1. Check that there isn't already an issue about your idea in the [nf-core/multiplesequencealign issues](https://github.com/nf-core/multiplesequencealign/issues) to avoid duplicating work. If there isn't one already, please create one so that others know you're working on this
2. [Fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) the [nf-core/multiplesequencealign repository](https://github.com/nf-core/multiplesequencealign) to your GitHub account
3. Make the necessary changes / additions within your forked repository following [Pipeline conventions](#pipeline-contribution-conventions)
4. Use `nf-core schema build` and add any new parameters to the pipeline JSON schema (requires [nf-core tools](https://github.com/nf-core/tools) >= 1.10).
5. Submit a Pull Request against the `dev` branch and wait for the code to be reviewed and merged

If you're not used to this workflow with git, you can start with some [docs from GitHub](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests) or even their [excellent `git` resources](https://try.github.io/).

## Tests

You have the option to test your changes locally by running the pipeline. For receiving warnings about process selectors and other `debug` information, it is recommended to use the debug profile. Execute all the tests with the following command:

```bash
nf-test test --profile debug,test,docker --verbose
```

When you create a pull request with changes, [GitHub Actions](https://github.com/features/actions) will run automatic tests.
Typically, pull-requests are only fully reviewed when these tests are passing, though of course we can help out before then.

There are typically two types of tests that run:

### Lint tests

`nf-core` has a [set of guidelines](https://nf-co.re/developers/guidelines) which all pipelines must adhere to.
To enforce these and ensure that all pipelines stay in sync, we have developed a helper tool which runs checks on the pipeline code. This is in the [nf-core/tools repository](https://github.com/nf-core/tools) and once installed can be run locally with the `nf-core lint <pipeline-directory>` command.

If any failures or warnings are encountered, please follow the listed URL for more documentation.

### Pipeline tests

Each `nf-core` pipeline should be set up with a minimal set of test-data.
`GitHub Actions` then runs the pipeline on this data to ensure that it exits successfully.
If there are any failures then the automated tests fail.
These tests are run both with the latest available version of `Nextflow` and also the minimum required version that is stated in the pipeline code.

## Patch

:warning: Only in the unlikely and regretful event of a release happening with a bug.

- On your own fork, make a new branch `patch` based on `upstream/master`.
- Fix the bug, and bump version (X.Y.Z+1).
- A PR should be made on `master` from patch to directly this particular bug.

## Getting help

For further information/help, please consult the [nf-core/multiplesequencealign documentation](https://nf-co.re/multiplesequencealign/usage) and don't hesitate to get in touch on the nf-core Slack [#multiplesequencealign](https://nfcore.slack.com/channels/multiplesequencealign) channel ([join our Slack here](https://nf-co.re/join/slack)).

## Pipeline contribution conventions

To make the nf-core/multiplesequencealign code and processing logic more understandable for new contributors and to ensure quality, we semi-standardise the way the code and other contributions are written.

### Adding a new step

If you wish to contribute a new step, please use the following coding standards:

1. Define the corresponding input channel into your new process from the expected previous process channel
2. Write the process block (see below).
3. Define the output channel if needed (see below).
4. Add any new parameters to `nextflow.config` with a default (see below).
5. Add any new parameters to `nextflow_schema.json` with help text (via the `nf-core schema build` tool).
6. Add sanity checks and validation for all relevant parameters.
7. Perform local tests to validate that the new code works as expected.
8. If applicable, add a new test command in `.github/workflow/ci.yml`.
9. Update MultiQC config `assets/multiqc_config.yml` so relevant suffixes, file name clean up and module plots are in the appropriate order. If applicable, add a [MultiQC](https://https://multiqc.info/) module.
10. Add a description of the output files and if relevant any appropriate images from the MultiQC report to `docs/output.md`.

Specifically, here are the instructions for integrating specific type of modules:

## Adding an aligner

These steps will guide you to include a new MSA tool into the pipeline. Once done, this will allow you to systematically deploy and benchmark your tool against all others included in the pipeline. You are also welcome to contribute back to the pipeline if you wish.

- [ ] **0. Create an nf-core module** for your tool. Instructions on how to contribute new modules [here](https://nf-co.re/docs/tutorials/nf-core_components/components). Use other modules (e.g. [famsa](https://github.com/nf-core/modules/tree/master/modules/nf-core/famsa/align)) as template. Ensure the output is in FASTA format.

> **!!** You can look at an example of a new tool integration [here](https://github.com/nf-core/multiplesequencealign/pull/139).

- [ ] **1.** **Fork** this repository and create a **new branch** (e.g. add-famsa)
- [ ] **2. Include the module in the alignment subworkflow** (`subworkflows/local/align.nf`)

  - [ ] Install the module. E.g. with the command `nf-core modules install famsa/align`.
  - [ ] Include the module in `subworkflows/local/align.nf`, example [here](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/align.nf#L12).
  - [ ] Add a branch to the correct channel, depending on your tool input. Example for sequence-based tools [here](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/align.nf#L83) and structure-based [here](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/align.nf#L101).
  - [ ] Add the code to correctly execute the tool, as done [here](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/align.nf#L131-L144).
  - [ ] Feed the output alignment and versions channels back into the `msa`. Make sure to `mix()` them so they do not get overwritten! [example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/align.nf#L143-L144).

- [ ] **3.** Add the aligner to the **aligner config** in [conf/modules.config](https://github.com/nf-core/multiplesequencealign/blob/dev/conf/modules.config). [Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/conf/modules.config#L125-L143).
- [ ] **4. Update Docs**

  - [ ] Update docs/usage.md
  - [ ] Update CITATIONS.md
  - [ ] Update CHANGELOG.md
  - [ ] Update citations in utils subworkflow, [here](https://github.com/nf-core/multiplesequencealign/blob/dev/subworkflows/local/utils_nfcore_multiplesequencealign_pipeline/main.nf)

- [ ] **5.** Add your tool in the **toolsheet** in the test dataset repository. [Example](https://github.com/nf-core/test-datasets/pull/1324).
- [ ] **6.** Open a **PR** against the `dev` branch of the nf-core repository :)

Congratulations, your aligner is now in nf-core/multiplesequencalign!

### Adding a guide tree estimator

To add a tool to estimate a guide tree, please follow exactly the steps of "Adding an aligner" with the only difference being that the subworkflow to be updated is [subworkflows/local/compute_trees.nf](https://github.com/nf-core/multiplesequencealign/blob/dev/subworkflows/local/compute_trees.nf).

### Adding an evaluation module

Adding a new evaluation mainly requires changes in the [evaluate.nf](https://github.com/nf-core/multiplesequencealign/blob/dev/subworkflows/local/evaluate.nf) subworkflow.

- [ ] **0. Create a module, local or nf-core** for your evaluation tool. Instructions on how to contribute new modules [here](https://nf-co.re/docs/tutorials/nf-core_components/components). Use other modules (e.g. [tcoffee/alncompare](<[https://github.com/nf-core/modules/tree/master/modules/nf-core/famsa/align](https://github.com/nf-core/modules/tree/master/modules/nf-core/tcoffee/alncompare)>) as template. Ensure the output is in **CSV** format. To merge the correct evaluation files and report the final output, the pipeline utilizes the `meta` field, which specifies the tools to be used. This information has to be included in the CSV returned by the module so as to merge it later, these [lines](https://github.com/nf-core/modules/blob/3be751e610b332efd94c2e82ddab5b5c65cfe852/modules/nf-core/tcoffee/alncompare/main.nf#L24-L25) in tcoffe/alncompare take care of it.
- [ ] **1.** **Fork** this repository and create a **new branch** (e.g. add-tcoffee-alncompare)

- [ ] **2. Include the module in the evaluate subworkflow** (`subworkflows/local/evaluate.nf`)

  - [ ] Add a `calc_yourscore` parameter to the pipeline in `nextflow.config` and document it in `nextflow_schema.json`. The parameter can then be passed by the user to decide whether to run your evaluation workflow. [Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/nextflow.config#L32).
  - [ ] Add a codeblock to `subworkflows/local/evaluate` that calls the newly added evaluation module if the appropriate parameter is passed to the pipeline. [Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/evaluate.nf#L59-L77).
  - [ ] To ensure the called module produces an output file with the correct name for merging evaluation outputs, add a config option in `conf/modules.config`. [Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/conf/modules.config#L189-L192).

- [ ] **3. Incorporate the evaluation output into the summary output.**
      After computing the scores of the different evaluation tools, the pipeline merges them into different summary CSVs (per metric, total and in combination with the dataset statistics). For this to happen, the output of the individual evaluation runs needs to be concatenated using the `CSVTK_CONCAT` module twice, first in the evaluation call to merge all calls of a single evaluation tool and then in the merging step.
  - [ ] For the first step, **import another copy of `CSVTK_CONCAT` as `CONCAT_<YOUR SCORE>`** and call it on the output channel of your module. [Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/evaluate.nf#L12).
  - [ ] Add the output channel of the newly added `CONCAT_<YOUR SCORE>` module to the list of inputs for `MERGE_EVAL` at the end block of `evaluate.nf`.[Example](https://github.com/nf-core/multiplesequencealign/blob/4623d19f68b20f0ab16410eba496c329e4f31fa3/subworkflows/local/evaluate.nf#L74-L76).
- [ ] **4. Update Docs**
  - [ ] Update docs/usage.md
  - [ ] Update CITATIONS.md
  - [ ] Update CHANGELOG.md
  - [ ] Update citations in utils subworkflow, [here](https://github.com/nf-core/multiplesequencealign/blob/dev/subworkflows/local/utils_nfcore_multiplesequencealign_pipeline/main.nf)
- [ ] **5.** Open a **PR** :)

Now your evaluation metric is incorporated into nf-core/multiplesequencealign!
Congratulations!

### Default values

Parameters should be initialised / defined with default values in `nextflow.config` under the `params` scope.

Once there, use `nf-core schema build` to add to `nextflow_schema.json`.

### Default processes resource requirements

Sensible defaults for process resource requirements (CPUs / memory / time) for a process should be defined in `conf/base.config`. These should generally be specified generic with `withLabel:` selectors so they can be shared across multiple processes/steps of the pipeline. A nf-core standard set of labels that should be followed where possible can be seen in the [nf-core pipeline template](https://github.com/nf-core/tools/blob/master/nf_core/pipeline-template/conf/base.config), which has the default process as a single core-process, and then different levels of multi-core configurations for increasingly large memory requirements defined with standardised labels.

The process resources can be passed on to the tool dynamically within the process with the `${task.cpus}` and `${task.memory}` variables in the `script:` block.

### Naming schemes

Please use the following naming schemes, to make it easy to understand what is going where.

- initial process channel: `ch_output_from_<process>`
- intermediate and terminal channels: `ch_<previousprocess>_for_<nextprocess>`

### Nextflow version bumping

If you are using a new feature from core Nextflow, you may bump the minimum required version of nextflow in the pipeline with: `nf-core bump-version --nextflow . [min-nf-version]`

### Images and figures

For overview images and other documents we follow the nf-core [style guidelines and examples](https://nf-co.re/developers/design_guidelines).

## GitHub Codespaces

This repo includes a devcontainer configuration which will create a GitHub Codespaces for Nextflow development! This is an online developer environment that runs in your browser, complete with VSCode and a terminal.

To get started:

- Open the repo in [Codespaces](https://github.com/nf-core/multiplesequencealign/codespaces)
- Tools installed
  - nf-core
  - Nextflow

Devcontainer specs:

- [DevContainer config](.devcontainer/devcontainer.json)
