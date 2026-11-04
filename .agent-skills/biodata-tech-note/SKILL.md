---
name: biodata-tech-note
description: Write a reproducible BioDataLink tutorial that discovers or imports biological data, inspects its structure and provenance, and completes a small analysis.
---

# Author a worked tutorial

Read the relevant design record, reference pages, tests and
[Documentation](../../GUIDE.md#documentation). Write
`docs/en/Tutorials/<Name>.md` with the `TechNote` template, readable title,
paclet context and URI `WolframInstitute/BioDataLink/tutorial/<Name>`.
Link it from related guides and link those guides in its frontmatter.

Choose one small complete workflow: discover or identify data, inspect
metadata, import a supported representation, check identifiers and show a useful
result. Keep retrieval, source preprocessing and analysis transformations
explicit. State the dataset revision, subset, measurement scale and seed where
applicable. Label synthetic examples as such.

Use local data in ordinary evaluated builds. Put online retrieval instructions
and backend requirements in clearly identified examples without triggering
large downloads during rendering. Keep data selection and scientific parameters
visible where the reader changes them. Put reusable helpers in the final
`## Initialization` section; the build evaluates enabled helpers first and
marks their bottom notebook inputs as native initialization cells. Never
enable optional or online `#| eval: false` cells as initialization. Follow
the concise native-code rules in
[Reproducible examples](../../GUIDE.md#reproducible-examples).

Use computed plots for patterns and compact tables for exact metadata. Include
axes and scales that preserve the data's meaning. Follow
[Reproducible examples](../../GUIDE.md#reproducible-examples) and run independent
inputs as well as the whole page. A plot from synthetic data demonstrates the
interface; scientific interpretation needs the actual source and analysis.

Build and inspect the notebook, check initialization-only evaluation and the
bottom section position, confirm guide backlinks and report missing
runtime or rendering checks. Use the
[computational essay playbook](../biodata-computational-essay/SKILL.md) when the
piece makes a sustained analytical argument rather than teaching access.
