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
marks their bottom notebook inputs as native initialization cells in one
closed Initialization group with a visible opener. Readers can expand it to
inspect the helpers. Never enable optional or online `#| eval: false` cells as initialization. Follow
the concise native-code rules in
[Reproducible examples](../../GUIDE.md#reproducible-examples).

Make each figure a single copyable input, using `With` for short figure-only
setup. Keep shared data and scientific selections as explicit prerequisites;
do not repeat the full workflow in every plot.

Use computed plots for patterns and compact tables for exact metadata. An
opening image follows [Page images](../../GUIDE.md#page-images-and-the-resource-description).
Include axes and scales that preserve the data's meaning, and choose plot types and
color maps by the [Figures](../../GUIDE.md#figures) rules. Follow
[Reproducible examples](../../GUIDE.md#reproducible-examples) and run independent
inputs as well as the whole page. A plot from synthetic data demonstrates the
interface; scientific interpretation needs the actual source and analysis.
Prefer a small subset of real public data, bundled with its source, license,
checksum and selection rule, when the tutorial teaches science. Check every
number and claim in the prose against the evaluated output.

Build and inspect the notebook, check initialization-only evaluation and the
final closed group, confirm guide backlinks and report missing
runtime or rendering checks. Use the
[computational essay playbook](../biodata-computational-essay/SKILL.md) when the
piece makes a sustained analytical argument rather than teaching access.
