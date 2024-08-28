# Extending nf-core/multiplesequencealign

This pipeline is designed to be extensible, both by adding new methods for assembling MSAs or guidetrees, and for evaluating MSAs.
Before any component is added, a Nextflow module has to be created for it.
It generally makes sense to directly create an nf-core module, but for certain use cases or testing purposes it maybe more appropriate to create a local module instead.
Even when creating a local module, it is still advisable to adhere to nf-core conventions.
Useful resources are:

- The [nf-core documentation](https://nf-co.re/docs/usage/tutorials/nf_core_usage_tutorial)
- The [Nextflow documentation](https://www.nextflow.io/docs/latest/module.html) for modules
- The [nf-core DSL2 module tutorial](https://nf-co.re/docs/contributing/tutorials/dsl2_modules_tutorial)
- The [nf-core module documentation](https://nf-co.re/docs/contributing/modules)
- The [nf-test documentation](https://code.askimed.com/nf-test/docs/getting-started/)
- The [nf-core slack](https://nf-co.re/join), particularly the [multiplesequencealign channel](https://nfcore.slack.com/archives/C05LZ7EAYGK). Feel free to reach out!

The pipeline consists of four different subworkflows:

1. Compute the guide trees for guide tree-based methods.
2. Perform the MSAs.
3. Evaluate the produced MSAs.
4. Compute statistics about the input dataset.

The subworkflows are to a significant degree isolated from each other, and not all of them may run in any given execution of the pipeline.

## Adding an aligner

-[] Create a module for your tool (ideally nf-core). Ensure the output is in FASTA format. Use other modules in the pipeline as template.
-[] Include the module in the alignment subworkflow (`subworkflows/local/align.nf`)
   - Import the module
   - Add a branch to the correct channel, depending on your tool input (see other examples)
   - Call the aligner with the respective branch (see other examples)
   - Feed the output alignment and versions channels back into the `msa`. Make sure to `mix()` them so they do not get overwritten!
-[] Add the aligner to the aligner config in `conf/modules.config`.
-[] Update docs/usage.md
-[] Update CITATIONS.md
-[] Update CHANGELOG.md

You can look at an example of a new tool integration [here](https://github.com/nf-core/multiplesequencealign/pull/139).
Congratulations, your aligner is now in nf-core/multiplesequencalignment!



## Adding a guide tree estimator

1. Create a local or nf-core module and ensure the output is in Newick format
2. Add the estimator to the README.md
3. Add a config to `conf/modules.config`, see the example of CLUSTALO [here](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/conf/modules.config#L82-L91)
4. Include it in the guidetree subworkflow (`subworkflows/local/compute_trees.nf`)
   - Import the module (see [here](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/subworkflows/local/compute_trees.nf#L6) an example)
   - Add a branch for the estimator to the beginning of call block [here](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/subworkflows/local/compute_trees.nf#L26-L28)
   - Call the estimator e.g. of [CLUSTALO](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/subworkflows/local/compute_trees.nf#L36), and add the output to `ch_trees` and `ch_versions`, respectively [here](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/subworkflows/local/compute_trees.nf#L37) and [here](https://github.com/nf-core/multiplesequencealign/blob/000ef2a535ed246ff89c7cd93afaca53879af3ef/subworkflows/local/compute_trees.nf#L38)

Congratulations, your guide tree estimator is now in nf-core/multiplesequencalignment!

## Adding an evaluation module

Adding a new evaluation module into the pipeline is a bit more tricky, since the output of the evaluation modules gets processed and merged in different ways in the pipeline.
This requires changes in the `evaluate.nf` subworkflow and the pipeline config as well as adding an option to the main pipeline.

In general, the process of adding another evaluation module to the pipeline can be thought of as three steps:

1. Create a local or nf-core module.

   - Make sure the evaluation output is returned from the module in CSV format!
   - To merge the correct evaluation files and report the final output, the pipeline utilizes the `meta` field, which specifies the tools to be used. This information has to be included in the CSV returned by the module so as to merge it later
   - Have a look at how `TCOFFEE_ALNCOMPARE` handles this

2. Include the evaluation module in the evaluation subworkflow

   - Add a `calc_yourscore` parameter to the pipeline in `nextflow.config` and document it in `nextflow_schema.json`. The parameter can then be passed by the user to decide whether to run your evaluation workflow.
   - Add a codeblock to `subworkflows/local/evaluate` that calls the newly added evaluation module if the appropriate parameter is passed to the pipeline.
   - For the called module to produce an output file with the appropriate name to use for merging the evaluation outputs, a config option needs to be added in `conf/modules.config`.

3. Incorporate the evaluation output into the summary output.

   - After computing the scores of the different evaluation tools, the pipeline merges them into different summary CSVs (per metric, total and in combination with the dataset statistics).
   - For this to happen, the output of the individual evaluation runs needs to be concatenated using the `CSVTK_CONCAT` module twice, first in the evaluation call to merge all calls of a single evaluation tool and then in the merging step.
   - For the first step, import another copy of `CSVTK_CONCAT` as `CONCAT_<YOUR SCORE>` and call it on the output channel of your module.
   - Then, add the output channel of the newly added `CONCAT_` module to the list of inputs for `MERGE_EVAL` at the end block of `evaluate.nf`.

Now your evaluation metric should be incorporated into the nf-core/multiplesequencealign pipeline!
Congratulations!
