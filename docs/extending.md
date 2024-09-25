# Extending nf-core/multiplesequencealign

This pipeline is extensible, allowing the incorporation of new methods for assembling MSAs, guide trees, and evaluating MSAs. Before adding a component, a Nextflow module must be created. Typically, it's best to create an nf-core module, but for specific cases or testing, a local module may be more suitable. Even for local modules, following nf-core conventions is recommended. Some useful resources for this process are listed below:

- The [nf-core documentation](https://nf-co.re/docs/usage/tutorials/nf_core_usage_tutorial)
- The [Nextflow documentation](https://www.nextflow.io/docs/latest/module.html) for modules
- The [nf-core DSL2 module tutorial](https://nf-co.re/docs/contributing/tutorials/dsl2_modules_tutorial)
- The [nf-core module documentation](https://nf-co.re/docs/contributing/modules)
- The [nf-test documentation](https://code.askimed.com/nf-test/docs/getting-started/)
- The [nf-core slack](https://nf-co.re/join), particularly the [multiplesequencealign channel](https://nfcore.slack.com/archives/C05LZ7EAYGK). Feel free to reach out!

Please also check the [contribution guidelines](../.github/CONTRIBUTING.md).

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

## Adding a guide tree estimator

To add a tool to estimate a guide tree, please follow exactly the steps of "Adding an aligner" with the only difference being that the subworkflow to be updated is [subworkflows/local/compute_trees.nf](https://github.com/nf-core/multiplesequencealign/blob/dev/subworkflows/local/compute_trees.nf).

## Adding an evaluation module

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
