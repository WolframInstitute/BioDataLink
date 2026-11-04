---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
Description: Discover biological datasets and import expression matrices with metadata and provenance
ContributedBy: Wolfram Institute
Keywords: [biology, datasets, gene expression, perturbations, sparse arrays, provenance]
MainGuide: Documentation/English/Guides/BioDataLink.nb
License: MIT
WolframVersion: 15.0+
Categories: [Scientific and Medical Data & Computation]
Links: ["[Pertpy dataset catalog](https://pertpy.scverse.org/en/stable/api/datasets_index.html)", "[scPerturb](https://projects.sanderlab.org/scperturb/)"]
---

## Basic Description

BioDataLink provides offline discovery of biological dataset metadata and a
validated local expression-data reader for Wolfram Language. Data retain their
cell and gene identifiers, declared measurement scale and source information.

## Details & Options

The initial catalog contains 55 records from a fixed revision of Pertpy's data
loaders. They include examples and processed variants, rather than 55
independent studies. Descriptions and links are source-declared metadata,
not scientific annotations reviewed by BioDataLink. Search and metadata
inspection do not download expression matrices.

The local reader accepts BioDataLink JSON version 1 and returns a cells-by-genes
sparse matrix, aligned cell and gene metadata, source provenance and a content
hash. Omitted entries become numerical zeros; the format cannot separately
represent missing measurements. Structural validation does not establish the
meaning of the values or verify a declared normalization procedure. The bundled
example is synthetic. Remote downloads, H5AD/AnnData conversion and access to
additional data sources are planned.

After installing a built paclet archive, load its main context with
<code>Needs["WolframInstitute\`BioDataLink\`"]</code>.
