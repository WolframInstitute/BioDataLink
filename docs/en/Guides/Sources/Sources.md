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

Find registered identifier namespaces, inspect their conventions and construct
accession links. These operations use the bundled Identifiers.org registry
without a network request.

WL denotes a built-in Wolfram Language function.

## Functions

### Find a Source

- `BioDataSourceInfo` inspect source metadata and identifier conventions
- `BioDataSourceSearch` find registered data sources
- `Dataset` (WL) query and display structured metadata

### Link an Identifier

- `BioDataURL` construct a resolver URL from an accession

## References

- [Identifiers.org registry](https://registry.identifiers.org/)
- [Identifiers.org documentation](https://docs.identifiers.org/)
