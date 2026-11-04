# Template for a verified reproduction tutorial section

Use [biodata-tech-note](../../biodata-tech-note/SKILL.md). Create a showcase only
when there is a completed case to demonstrate; do not add an empty page.

## Frontmatter example

```yaml
---
Template: TechNote
Name: ReproducingBiologicalResults
Title: Reproducing Published Biological Results
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ReproducingBiologicalResults
Keywords: [application, biological data, reproduction]
RelatedGuides: [BioDataLink, DataAccess]
RelatedTutorials: []
---
```

## One section per paper

State the paper's claim, locus and qualifiers with a stable source link.
Describe the dataset release, processing and actual comparison. Where authors'
code is useful, cite its exact version and license; use only a brief excerpt
when permitted.

Show the BioDataLink input and actual return value before summaries. Generate
figures from recorded code. Keep ordinary builds local; clearly separate the
full online run from a small fixture demonstration.

End the section with the observed comparison and evidence limits. Compare
runtime only when both routes were measured under stated conditions. Link the
finished page from relevant guides and verify its rendered output.
