---
Template: Guide
Name: BioDataLink
Title: BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/BioDataLink
Description: Discover biological datasets and import supported expression data with provenance
Keywords: [biology, datasets, gene expression, provenance]
RelatedGuides: [Catalog, DataAccess]
RelatedTutorials: [ExploringBiologicalData]
---

## Abstract

BioDataLink searches a bundled catalog of Pertpy data sources and loads local
expression matrices in BioDataLink JSON format. The catalog contains source
descriptions; a record may refer to one of several files or processed versions
from a study. Local files connect a cells-by-genes matrix to ordered metadata
and declared source information. The reader checks file structure and alignment;
scientific interpretation depends on the assay and processing history.

Finding a catalog record does not mean its data file can already be loaded.

WL marks a built-in Wolfram Language function.

## Functions

### [Catalog](paclet:WolframInstitute/BioDataLink/guide/Catalog)

- `BioDatasetInfo` inspect a dataset's source and access metadata
- `BioDatasetSearch` search the bundled catalog

### [Data Access](paclet:WolframInstitute/BioDataLink/guide/DataAccess)

- `BioDatasetLoad` import a supported local expression file
- `Dataset` (WL) explore cell and gene metadata
- `SparseArray` (WL) represent sparse expression values
