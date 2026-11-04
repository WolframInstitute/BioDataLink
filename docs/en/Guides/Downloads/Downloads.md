---
Template: Guide
Name: Downloads
Title: Data File Downloads
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/Downloads
Description: Download an explicit HTTPS data file with size limits and optional checksum verification
Keywords: [download, data files, checksum, provenance, HTTPS]
RelatedGuides: [BioDataLink, Catalog, ComputationalExplorations, DataAccess, Providers, Sources]
RelatedTutorials: [ComparingCoronavirusGenomes, ComparingProteinConformations, DiscretizingBiologicalMeasurements, DownloadingBiologicalData, ExploringBiologicalDataGeometry, ExploringSimplePredictiveRules, ReadingAnnDataSlices, ReadingBacterialGenomeComposition]
---

## Abstract

Download a chosen HTTPS file with size limits and optional checksum
verification. The result records the file, source URL, retrieval time and
content hash. Downloaded files can be read with `BioDatasetLoad` or `Import`.

WL denotes a built-in Wolfram Language function.

## Functions

### Retrieve and Verify a File

- `BioDatasetDownload` download an HTTPS file with integrity checks
- `FileHash` (WL) compute a file content hash

### Read the Retrieved Data

- `BioDatasetLoad` import a local matrix with aligned metadata
- `Import` (WL) read data from a file
