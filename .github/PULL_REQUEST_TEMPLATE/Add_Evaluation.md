<!--
# nf-core/multiplesequencealign pull request

Many thanks for contributing to nf-core/multiplesequencealign!

Please fill in the appropriate checklist below (delete whatever is not relevant).
These are the most common things requested on pull requests (PRs).

Remember that PRs should be made against the dev branch, unless you're preparing a pipeline release.

Learn more about contributing: [CONTRIBUTING.md](https://github.com/nf-core/multiplesequencealign/tree/master/.github/CONTRIBUTING.md)
-->

## PR checklist

- [ ] This comment contains a description of changes (with reason).
- [ ] PR on the nf-core/multiplesequencealign _branch_ on the [nf-core/test-datasets](https://github.com/nf-core/test-datasets) repository to update the toolsheet.
- [ ] Make sure your code lints (`nf-core pipelines lint`).
- [ ] Ensure the test suite passes (`nextflow run . -profile test,docker --outdir <OUTDIR>`).
- [ ] Check for unexpected warnings in debug mode (`nextflow run . -profile debug,test,docker --outdir <OUTDIR>`).
- [ ] The new module is installed.
- [ ] `subworkflows/local/evaluate.nf` is updaded. 
- [ ] `modules.config` is updated.
- [ ] Usage Documentation in `docs/usage.md` is updated.
- [ ] Output Documentation in `docs/output.md` is updated.
- [ ] `CHANGELOG.md` is updated.
- [ ] `README.md` is updated (including new tool citations and authors/contributors).
- [ ] `CITATIONS` is updated.