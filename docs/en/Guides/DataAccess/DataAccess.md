---
Template: Guide
Name: DataAccess
Title: Data Access
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/DataAccess
Description: Import local expression matrices with aligned metadata and provenance
Keywords: [expression, sparse arrays, JSON, provenance]
RelatedGuides: [BioDataLink, Catalog]
RelatedTutorials: [ExploringBiologicalData]
---

## Abstract

A supported local expression file contains sparse values, cell and gene
identifiers, a declared measurement scale and source information. The reader
checks their structure before returning a cells-by-genes matrix and aligned
metadata. It does not normalize values or verify their biological meaning.
The initial reader supports BioDataLink JSON version 1. H5AD/AnnData conversion
and remote downloads are planned extensions.

Unlisted matrix entries become numerical zeros. This format cannot distinguish
an unmeasured value from zero, so missing measurements must not be omitted as
though they were zeros. An observed zero count also does not establish absence
of a transcript in a cell.

## Functions

### Local Import

- `BioDatasetLoad` validate and import a local expression file
- `Dataset` (WL) query cell and gene metadata
- `MatrixPlot` (WL) inspect a small expression matrix
- `SparseArray` (WL) retain zero entries implicitly
