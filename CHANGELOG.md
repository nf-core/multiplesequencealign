# nf-core/multiplesequencealign: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0 - Somorrostro](https://github.com/nf-core/multiplesequencealign/releases/tag/1.0.0)

Somorrostro is a beach in Barcelona.

Initial release of nf-core/multiplesequencealign, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- [[#29](https://github.com/nf-core/multiplesequencealign/issues/29)] - Add FAMSA_ALIGN module.
- [[#38](https://github.com/nf-core/multiplesequencealign/issues/38)] - Add FAMSA_GUIDETREE module.
- [[#42](https://github.com/nf-core/multiplesequencealign/issues/42)] - Add MAFFT module.
- [[#51](https://github.com/nf-core/multiplesequencealign/issues/51)] - Add CLUSTALO module.
- [[#41](https://github.com/nf-core/multiplesequencealign/issues/41)] - Add KALIGN module.
- [[#48](https://github.com/nf-core/multiplesequencealign/issues/48)] - Integrate NF-VALIDATION PLUGIN.
- [[#45](https://github.com/nf-core/multiplesequencealign/issues/45)] - Add module LearnMSA
- [[#35](https://github.com/nf-core/multiplesequencealign/issues/35)] - Add module Tcoffee_align.
- [[#60](https://github.com/nf-core/multiplesequencealign/issues/60)] - Add module Tcoffee3D_align and handle structures input.
- [[#35](https://github.com/nf-core/multiplesequencealign/issues/35)] - Add module MUSCLE5_SUPER5.
- [[#59](https://github.com/nf-core/multiplesequencealign/issues/59)] - Add support for passing structure template in samplesheet.
- [[#77](https://github.com/nf-core/multiplesequencealign/issues/77)] - Add module zip.
- [[#93](https://github.com/nf-core/multiplesequencealign/pull/93)] - Add multiqc basic support. Add custom params validation. Add basic shiny app.
- [[#100](https://github.com/nf-core/multiplesequencealign/pull/100)] - Add support for optional stats and evals. Clean tests.
- [[#110](https://github.com/nf-core/multiplesequencealign/issues/110)] - Add Readme documentation. Add nf-test for the pipeline.
- [[#76](https://github.com/nf-core/multiplesequencealign/issues/76)] - Add reading of trace files for shiny app.
- [[#99](https://github.com/nf-core/multiplesequencealign/issues/99)] - Add check for conflicting input parameters for stats and eval.
- [[#117](https://github.com/nf-core/multiplesequencealign/issues/117)] - Add data for full datasets.
- [[#90](https://github.com/nf-core/multiplesequencealign/issues/90)] - Add TCS evaluation metric.
- [[#89](https://github.com/nf-core/multiplesequencealign/issues/89)] - Add collection of plddt metrics in stats subworkflow.
- [[#96](https://github.com/nf-core/multiplesequencealign/issues/96)] - Add collection of number of gaps in eval subworkflow.
- [[#84](https://github.com/nf-core/multiplesequencealign/issues/84)] - Update Metromap.
- [[#139](https://github.com/nf-core/multiplesequencealign/pull/139)] - Add Foldmason.
- [[#146](https://github.com/nf-core/multiplesequencealign/pull/146)] - Only show additional process tags when they exists and use the same ubuntu version in all modules.
- [[#145](https://github.com/nf-core/multiplesequencealign/pull/145)] - Add consensus MSA.
- [[#147](https://github.com/nf-core/multiplesequencealign/pull/147)] - Add small testing profile + some fixes of the shiny app.
- [[#148](https://github.com/nf-core/multiplesequencealign/pull/148)] - Add UPP module.
- [[#150](https://github.com/nf-core/multiplesequencealign/pull/150)] - Update modules and readme for pre-release.

### `Fixed`

- [[#61](https://github.com/nf-core/multiplesequencealign/issues/61)] - Fix filtering of unique guidetree compuation instructions: no double GT computation.
- [[#57](https://github.com/nf-core/multiplesequencealign/issues/57)] - Update naming in the naming of the meta channels.
- [[#66](https://github.com/nf-core/multiplesequencealign/issues/66)] - README: add new metromap and available tool list.
- [[#54](https://github.com/nf-core/multiplesequencealign/issues/54)] - Update modules versions from nf-core tools.
- [[#80](https://github.com/nf-core/multiplesequencealign/pull/80)] - Update modules versions from nf-core tools with nf-test.
- [[#32](https://github.com/nf-core/multiplesequencealign/issues/32)] - Update Stats workflow with nf-core modules for merging.
- [[#81](https://github.com/nf-core/multiplesequencealign/pull/81)] - Update Eval workflow with nf-core modules for merging.
- [[#111](https://github.com/nf-core/multiplesequencealign/pull/111)] - Fix linting warnings (mostly versions).
- [[#134](https://github.com/nf-core/multiplesequencealign/pull/134)] - Code revision for release preparation.
- [[#138](https://github.com/nf-core/multiplesequencealign/pull/138)] - MultiQC as nf-core module and fix visualization.
- [[#152](https://github.com/nf-core/multiplesequencealign/pull/152)] - Ignore kalign error 132 and print a warning (incompatibility with some CPU types).
- [[#153](https://github.com/nf-core/multiplesequencealign/pull/153)] - Fix time parser in shiny app.
- [[#154](https://github.com/nf-core/multiplesequencealign/pull/154)] - Fix metromap.
- [[#155](https://github.com/nf-core/multiplesequencealign/pull/155)] - Fix typos.

### `Dependencies`

### `Deprecated`
