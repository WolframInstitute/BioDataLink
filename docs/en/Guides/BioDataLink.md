---
Template: Guide
Name: BioDataLink
Title: BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/BioDataLink
Description: Find biological data sources, retrieve verified files and read supported local measurements
Keywords: [biology, datasets, gene expression, provenance]
RelatedGuides: [Catalog, ComputationalExplorations, DataAccess, Downloads, Providers, Sources]
RelatedTutorials: [ChoosingMeasurementsToDistinguishModels, ConstructingBiologicalSimilarityNetworks, DiscretizingBiologicalMeasurements, DownloadingBiologicalData, ExploringBiologicalData, ExploringBiologicalDataGeometry, ExploringCellularAutomatonHypotheses, ExploringSimplePredictiveRules, FindingDataSources, ReadingAnnDataSlices, UnderstandingSparseMeasurements]
---

## Abstract

BioDataLink helps researchers find data sources across biological domains,
construct links from identifiers and search public study metadata. Its bundled
source directory spans biological and other domains and is not exhaustive.
BioStudies and GEO queries run online; the source directory and Pertpy catalog
can be searched offline.

An explicit HTTPS file download can check an expected byte count and SHA-256
before creating or replacing a local file. Local readers support BioDataLink
JSON and selected matrices from supported H5AD files. The optional H5AD reader
requires an explicitly configured Python interpreter and preserves the selected
layer, axis positions and metadata.

Transfer integrity and structural checks do not establish biological validity.
Scientific interpretation depends on the assay, sampling and processing history.

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

### [Data File Downloads](paclet:WolframInstitute/BioDataLink/guide/Downloads)

- `BioDatasetDownload` retrieve an explicit HTTPS file with byte limits and optional expected checksum

### [Computational Explorations](paclet:WolframInstitute/BioDataLink/guide/ComputationalExplorations)

- `ClusteringComponents` (WL) compare explicit clusterings and their sensitivity
- `PrincipalComponents` (WL) examine measurement geometry under a chosen scale
- `Quantile` (WL) turn continuous measurements into recorded finite bins
