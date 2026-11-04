---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
Description: Find data sources, search public study metadata and load local expression matrices
ContributedBy: Wolfram Institute
Keywords: [biology, datasets, sources, identifiers, gene expression, provenance]
MainGuide: Documentation/English/Guides/BioDataLink.nb
License: MIT
WolframVersion: 15.0+
Categories: [Scientific and Medical Data & Computation]
Links: ["[Identifiers.org registry](https://registry.identifiers.org/)", "[BioStudies](https://www.ebi.ac.uk/biostudies/)", "[GEO](https://www.ncbi.nlm.nih.gov/geo/)", "[Pertpy dataset catalog](https://pertpy.scverse.org/en/stable/api/datasets_index.html)"]
---

## Basic Description

BioDataLink helps Wolfram Language researchers find data sources, construct
identifier links, search public study metadata and read local expression data.
Source records retain identifiers and provenance; expression matrices retain
aligned metadata and their declared measurement scale.

## Details & Options

Version 0.2 includes 867 Identifiers.org namespaces and 1,039 endpoints, with
774 active namespaces shown by default. This broad directory spans biological
and other domains and is not exhaustive. A listing or generated resolver link
does not establish current availability, open access or data-file import support.
Directory search, source inspection and link construction run offline.

Live queries search public BioStudies study metadata or GEO Series one page
at a time, retaining source descriptions, original metadata, retrieval time
and a continuation cursor. Reported totals can change between requests.
Optional GEO API-key references affect public request quotas; private-data
access is not implemented.

The separate Pertpy catalog contains 55 records from a fixed revision of its data
loaders. They include examples and processed variants, rather than 55
independent studies. Descriptions and links are source-declared metadata,
not scientific annotations reviewed by BioDataLink. Search and metadata
inspection do not download expression matrices.

The local reader accepts BioDataLink JSON version 1 and returns a cells-by-genes
sparse matrix, aligned cell and gene metadata, source provenance and a content
hash. Omitted entries become numerical zeros; the format cannot separately
represent missing measurements. Structural validation does not establish the
meaning of the values or verify a declared normalization procedure. The bundled
example is synthetic. Data-file downloads, H5AD/AnnData conversion and
additional source APIs are planned. This is a local development milestone;
no published release is implied.

The source registry is provided by Identifiers.org under CC BY 4.0. Its license
and attribution are retained alongside the bundled data; the paclet code is MIT.

After installing a built paclet archive, load its main context with
<code>Needs["WolframInstitute\`BioDataLink\`"]</code>.
