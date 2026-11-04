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

A study record may link to several files with different processing histories.
Choose the required file explicitly, set a byte limit and retain its source
and checksum. BioDataLink downloads an HTTPS file into a temporary location,
checks the result, then places it at the chosen destination. Existing files
are preserved unless replacement is explicitly requested and the new download
passes its checks.

The download result records what was retrieved. A matching expected SHA-256
confirms agreement with the supplied digest; it does not establish a data
license, correct scientific annotation or suitability for an analysis.
Interpret the file with an appropriate reader after retrieval. Downloads
require curl 8.4 or later; the paclet does not install it automatically.

## Functions

### Retrieve and Verify a File

- `BioDatasetDownload` retrieve an HTTPS file with byte limits and optional expected size and SHA-256
- `FileHash` (WL) compute a local file's content hash

### Read the Retrieved Data

- `BioDatasetLoad` read supported local expression formats
- `Import` (WL) read other formats such as CSV using the file's documented structure

WL marks a built-in Wolfram Language function.
