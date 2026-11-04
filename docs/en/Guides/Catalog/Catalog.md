---
Template: Guide
Name: Catalog
Title: Catalog
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/Catalog
Description: Search biological dataset metadata in the bundled Pertpy catalog
Keywords: [catalog, metadata, Pertpy, datasets]
RelatedGuides: [BioDataLink, DataAccess, Providers, Sources]
RelatedTutorials: [ExploringBiologicalData, FindingDataSources]
---

## Abstract

The bundled catalog contains 55 entries extracted from a fixed revision of
Pertpy's data loaders. Search runs locally and returns source descriptions and
links; it does not retrieve expression matrices. A provider and identifier
select one complete record. These descriptions are source-declared metadata,
not scientific annotations reviewed by BioDataLink.

A study can produce several datasets or processed versions, each stored in one
or more data files. A repository accession identifies a record at its source.
The Pertpy identifiers used here are loader names, not repository accessions:
55 catalog entries do not imply 55 independent studies. Inspect the linked
source to establish the study, assay, processing and citation.

For live BioStudies and GEO metadata queries, see
[Online Study Search](paclet:WolframInstitute/BioDataLink/guide/Providers).
Live results are separate from the records in this offline catalog.

## Functions

### Dataset Discovery

- `BioDatasetInfo` inspect one record by provider and identifier
- `BioDatasetSearch` find records by text, provider and organism
- `Dataset` (WL) query returned metadata

## References

- [Pertpy dataset catalog](https://pertpy.scverse.org/en/stable/api/datasets_index.html)
- [scPerturb harmonized single-cell perturbation data](https://projects.sanderlab.org/scperturb/)
