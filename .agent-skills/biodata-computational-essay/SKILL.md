---
name: biodata-computational-essay
description: Develop a BioDataLink computational essay using explicit dataset provenance, reproducible analyses, computed figures, and claims bounded by the observed evidence.
---

# Develop a computational essay

Use the [tutorial playbook](../biodata-tech-note/SKILL.md) and
[GUIDE.md](../../GUIDE.md) for page format and reproducible data handling.
Start from a question answerable with an implemented access path and a defined
dataset. Keep exploratory proposals separate from evaluated results.

Record accession and revision, source preprocessing, selected samples and
genes, analysis parameters and random seed. Explain the observational unit:
multiple cells from one sample do not create independent biological replicates.
Keep controls, batch structure and uncertainty visible where they affect a
comparison. Preserve training/test separation if fitting predictive models.

Compute each figure from recorded inputs. Inspect returned identifiers and
matrix orientation before interpreting a heatmap or embedding. State the scope
of each result and the assumptions linking measurements to interpretation.
Do not infer a causal molecular mechanism from an attractive plot alone.
Keep each computational step concise and use native presentation defaults;
preserve the labels, common scales and fixed layouts needed for comparison.
Keep reusable definitions in the tutorial's final Initialization section,
following the [reproducible-example rules](../../GUIDE.md#reproducible-examples).

Keep expensive or live analyses in explicitly run steps. Provide small local
examples for documentation builds and identify their reduced scope. Record
which claims the complete analysis supports and which only the fixture
illustrates. Verify saved outputs, citations and figure readability before
calling the essay complete.
