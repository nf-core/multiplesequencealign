# Extending nf-core/multiplesequencealign

This pipeline is designed to be extensible, both by adding new methods for assembling MSAs or guidetrees, and for evaluating MSAs.
Before any component is added, a nextflow module has to be created for it.
It usually makes sense to directly create an nf-core module, but for some usecases or for testing it may make sense to create a local module instead.
Even when creating a local module, it is still advisable to follow the nf-core conventions in creating the module.
Useful resources are:
  - The [nf-core documentation](https://nf-co.re/docs/usage/tutorials/nf_core_usage_tutorial)
  - The [nextflow documentation](https://www.nextflow.io/docs/latest/module.html) for modules
  - The [nf-core DSL2 module tutorial](https://nf-co.re/docs/contributing/tutorials/dsl2_modules_tutorial)
  - The [nf-core module documentation](https://nf-co.re/docs/contributing/modules)
  - The [nf-test documentation](https://code.askimed.com/nf-test/docs/getting-started/)
  - The [nf-core slack](https://nf-co.re/join), particularly the [multiplesequencealign channel](https://nfcore.slack.com/archives/C05LZ7EAYGK). Feel free to reach out!


The pipeline consists of four different subworkflows, one for computing the guidetrees of guidetree-based methods, one for performing the MSAs, one for evaluating the produced MSAs and one for computing statistics about the input dataset.
The subworkflows are to a significant degree isolated from each other, and not all of them may run in any given execution of the pipeline.

`subworkflows/local/evaluate.nf` handles the evaluation step. It calls the modules used for evaluation and merges their output into some summary statistics.
If it is not skipped, it is the last part of the pipeline to run.


## Adding an aligner
  1. Create a local or nf-core module
  2.

## Adding a guide tree estimator
  1. Create a local or nf-core module
  2.

## Adding an evaluation module

Adding a new evaluation module into the pipeline is a bit more tricky, since the output of the evaluation modules gets processed and merged in different ways in the pipeline.
This requires changes in the `evaluate.nf` subworkflow and the pipeline config as well as adding an option to the main pipeline.
The process of adding `ULTRAMSATRIC` evaluation to the pipeline may be a useful reference: [commit history](https://github.com/lrauschning/multiplesequencealign/commits/ultramsatric/).
In general, the process of adding another evaluation module to the pipeline can be thought of as three steps:

  1. Create a local or nf-core module.
    * Make sure the evaluation output is returned from the module in CSV format!
    * For merging the correct evaluation files in reporting the final output, the pipeline uses the `meta` field containing the tools to use. This information has to be included in the CSV returned by the module so as to merge it later.
    * Have a look at how `TCOFFEE_ALNCOMPARE` and `ULTRAMSATRIC` handle this.
  2. Include the evaluation module in the evaluation subworkflow
    * Add a `calc_yourscore` parameter to the pipeline in `nextflow.config` and document it in `nextflow_schema.json`. The parameter can then be passed by the user to decide whether to run your evaluation workflow.
    * Add a codeblock to `subworkflows/local/evaluate` that calls the newly added evaluation module if the appropriate parameter is passed to the pipeline.
    * For the called module to produce an output file with the appropriate name to use for merging the evaluation outputs, a config option needs to be added in `conf/modules.config`.
  3. Incorporate the evaluation output into the summary output.
    * After computing the scores of the different evaluation tools, the pipeline merges them into different summary CSVs (per metric, total and in combination with the dataset statistics).
    * For this to happen, the output of the individual evaluation runs needs to be concatenated using the `CSVTK_CONCAT` module twice, first in the evaluation call to merge all calls of a single evaluation tool and then in the merging step.
    * For the first step, import another copy of `CSVTK_CONCAT` as `CONCAT_<YOUR SCORE>` and call it on the output channel of your module.
    * Then, add the output channel of the newly added `CONCAT_` module to the list of inputs for `MERGE_EVAL` at the end block of `evaluate.nf`.

Now your evaluation metric should be incorporated into the nf-core/multiplesequencealign pipeline!
Congratulations!


