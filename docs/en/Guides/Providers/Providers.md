---
Template: Guide
Name: Providers
Title: Online Study Search
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/guide/Providers
Description: Search public BioStudies and GEO study metadata with pagination and retrieval information
Keywords: [online, study metadata, BioStudies, GEO, search]
RelatedGuides: [BioDataLink, Catalog, Sources]
RelatedTutorials: [FindingDataSources]
---

## Abstract

Online searches retrieve public BioStudies study records or GEO Series metadata
one page at a time. Results retain source accessions, the source's descriptions
and the query's retrieval time. These records help identify studies; they do
not download scientific data files or establish that BioDataLink can load them.

Use the returned continuation cursor to request another page. The source index
can change between requests, and a reported total can be approximate. Matching
records may refer to related or overlapping studies, so search totals do not
count independent experiments or biological replicates. Source descriptions
and absent annotations require checking against the original study.

## Functions

### Public Study Metadata

- `BioDatasetQuery` search BioStudies or GEO and return a page with retrieval information
- `Dataset` (WL) inspect the returned study records

## References

- [BioStudies search API](https://www.ebi.ac.uk/biostudies/help#api)
- [GEO programmatic access](https://www.ncbi.nlm.nih.gov/geo/info/geo_paccess.html)
