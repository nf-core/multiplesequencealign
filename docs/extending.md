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

## Adding an aligner
  1. Create a local or nf-core module
  2.

## Adding a guide tree estimator
  1. Create a local or nf-core module
  2.

## Adding an evaluation module

  1. Create a local or nf-core module
  2.


