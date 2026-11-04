---
Template: Guide
Name: BioDataLink
Title: BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/BioDataLink
Description: Find biological data sources, search study metadata and load supported local expression data
Keywords: [biology, datasets, gene expression, provenance]
RelatedGuides: [Catalog, DataAccess, Providers, Sources]
RelatedTutorials: [ExploringBiologicalData, FindingDataSources]
---

## Abstract

BioDataLink helps researchers find data sources across biological domains,
construct links from identifiers and search public study metadata. Its bundled
source directory spans biological and other domains and is not exhaustive.
BioStudies and GEO queries run online; the source directory and Pertpy catalog
can be searched offline.

The local reader loads expression matrices in BioDataLink JSON format, with
aligned cell and gene metadata and declared source information. It checks file
structure and alignment; scientific interpretation depends on the assay and
processing history.

Finding a catalog record does not mean its data file can already be loaded.

WL marks a built-in Wolfram Language function.

## Functions

### [Data Sources](paclet:WolframInstitute/BioDataLink/guide/Sources)

- `BioDataSourceInfo` inspect registered identifier conventions and source endpoints
- `BioDataSourceSearch` find registered sources in the bundled directory
- `BioDataURL` construct a source resolver link from an identifier

### [Online Study Search](paclet:WolframInstitute/BioDataLink/guide/Providers)

- `BioDatasetQuery` search public BioStudies or GEO study metadata online

### [Catalog](paclet:WolframInstitute/BioDataLink/guide/Catalog)

- `BioDatasetInfo` inspect a dataset's source and access metadata
- `BioDatasetSearch` search the bundled catalog

### [Data Access](paclet:WolframInstitute/BioDataLink/guide/DataAccess)

- `BioDatasetLoad` import a supported local expression file
- `Dataset` (WL) explore cell and gene metadata
- `SparseArray` (WL) represent sparse expression values
