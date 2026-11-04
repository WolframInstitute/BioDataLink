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
RelatedTutorials: [AnalyzingSingleCellExpression, ChoosingMeasurementsToDistinguishModels, ConstructingBiologicalSimilarityNetworks, DiscretizingBiologicalMeasurements, ExploringBiologicalData, ExploringBiologicalDataGeometry, ExploringCellularAutomatonHypotheses, ExploringSimplePredictiveRules, ReadingAnnDataSlices, UnderstandingSparseMeasurements]
---

## Abstract

Import local expression matrices with aligned identifiers, metadata and
provenance. Supported formats are BioDataLink JSON and selected AnnData H5AD
matrices. H5AD reading requires a configured Python interpreter.

WL denotes a built-in Wolfram Language function.

## Functions

### Local Import

- `BioDatasetLoad` import a local matrix with aligned metadata
- `Dataset` (WL) query and display structured metadata
- `MatrixPlot` (WL) display a matrix
- `SparseArray` (WL) represent arrays with implicit zero entries

## References

- [AnnData on-disk format](https://anndata.readthedocs.io/en/stable/fileformat-prose.html)
