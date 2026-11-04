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
large downloads during rendering. Tutorial cells run in document order under the direct PacletPage build.
Place initialization before its first use, define the running example once,
and keep data selection visible where the reader changes it. Reference pages
retain independent example groups across headings and thematic breaks.

Use computed plots for patterns and compact tables for exact metadata. Include
axes and scales that preserve the data's meaning. Follow
[Reproducible examples](../../GUIDE.md#reproducible-examples) and run independent
inputs as well as the whole page. A plot from synthetic data demonstrates the
interface; scientific interpretation needs the actual source and analysis.

Build and inspect the notebook, confirm guide backlinks and report missing
runtime or rendering checks. Use the
[computational essay playbook](../biodata-computational-essay/SKILL.md) when the
piece makes a sustained analytical argument rather than teaching access.
