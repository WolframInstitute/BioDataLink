---
Template: Guide
Name: DataAccess
Title: Data Access
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/DataAccess
Description: Read local JSON expression data or selected AnnData matrices with aligned metadata
Keywords: [expression, sparse arrays, JSON, H5AD, AnnData, provenance]
RelatedGuides: [BioDataLink, Catalog, ComputationalExplorations, Downloads]
RelatedTutorials: [ConstructingBiologicalSimilarityNetworks, DiscretizingBiologicalMeasurements, ExploringBiologicalData, ExploringBiologicalDataGeometry, ExploringCellularAutomatonHypotheses, ExploringSimplePredictiveRules, ReadingAnnDataSlices, UnderstandingSparseMeasurements]
---

## Abstract

BioDataLink reads local BioDataLink JSON expression files and, with an explicit
Python configuration, selected measurements from supported AnnData H5AD files.
Results contain a sparse matrix and aligned axis metadata. The reader checks
their structure; it does not normalize values or verify their biological meaning.

Choose an H5AD layer and source positions explicitly when a complete matrix
would be too large. The result preserves repeated source labels and records
which structures were omitted. General AnnData observations and variables are
not necessarily cells and genes; interpret them using the source assay.

In the JSON format, unlisted matrix entries become numerical zeros and missing
measurements cannot be represented separately. The H5AD reader rejects selected
NaN or infinite matrix values instead of replacing them with zero. Missing
annotations remain missing. An observed zero count does not establish absence
of a transcript in a cell.

## Functions

### Local Import

- `BioDatasetLoad` read JSON expression data or a selected H5AD matrix with aligned metadata
- `Dataset` (WL) query cell and gene metadata
- `MatrixPlot` (WL) inspect a small expression matrix
- `SparseArray` (WL) retain zero entries implicitly

## References

- [AnnData on-disk format](https://anndata.readthedocs.io/en/stable/fileformat-prose.html)
