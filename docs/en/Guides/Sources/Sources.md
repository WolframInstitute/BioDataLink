---
Template: Guide
Name: Sources
Title: Data Sources
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/Sources
Description: Find registered data sources and construct links from their identifiers
Keywords: [sources, identifiers, repositories, accessions, Identifiers.org]
RelatedGuides: [BioDataLink, Catalog, DataAccess]
RelatedTutorials: [ComparingCoronavirusGenomes, ComparingProteinConformations, FindingDataSources, ReadingBacterialGenomeComposition]
---

## Abstract

A source directory helps find repositories and understand their identifiers
before searching for a particular study or data file. An identifier namespace
is a named system such as `"pdb"` or `"ensembl"`; it tells a reader how to
interpret a local identifier. BioDataLink includes an
Identifiers.org registry with 867 identifier namespaces, 93 of them deprecated.
Search shows the 774 active namespaces by default. One namespace can list
several access endpoints; the registry contains 1,039 endpoints in total.

This is a broad, nonexhaustive directory spanning biological and other domains.
A listed namespace is not necessarily a distinct repository, an openly
accessible source or a supported data connection. Source descriptions and
access information are declarations from the registry. Creating a link does
not check that an accession exists or that its data can be downloaded.

## Functions

### Find a Source

- `BioDataSourceInfo` inspect identifier conventions, source endpoints and registry provenance
- `BioDataSourceSearch` search the bundled source directory without a network request
- `Dataset` (WL) explore source descriptions

### Link an Identifier

- `BioDataURL` construct an Identifiers.org link for a registered namespace and local identifier

## References

- [Identifiers.org registry](https://registry.identifiers.org/)
- [Identifiers.org documentation](https://docs.identifiers.org/)
