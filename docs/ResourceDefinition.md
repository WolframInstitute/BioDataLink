---
Template: Paclet
ResourceType: Paclet
Name: WolframInstitute/BioDataLink
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
Description: Find data sources, download verified files and read supported local measurements
ContributedBy: Wolfram Institute
Keywords: [biology, datasets, sources, identifiers, gene expression, provenance]
MainGuide: Documentation/English/Guides/BioDataLink.nb
License: MIT
WolframVersion: 15.0+
Categories: [Scientific and Medical Data & Computation]
Links: ["[Source repository](https://github.com/WolframInstitute/BioDataLink)", "[Releases](https://github.com/WolframInstitute/BioDataLink/releases)", "[Identifiers.org registry](https://registry.identifiers.org/)", "[BioStudies](https://www.ebi.ac.uk/biostudies/)", "[GEO](https://www.ncbi.nlm.nih.gov/geo/)", "[Pertpy dataset catalog](https://pertpy.scverse.org/en/stable/api/datasets_index.html)"]
---

## Basic Description

BioDataLink helps Wolfram Language researchers find data sources, construct
identifier links, search public study metadata, download selected files and
read supported local measurements. Source and retrieval records retain
provenance; matrix results preserve aligned metadata and explicit selections.

## Details & Options

The bundled directory includes 867 Identifiers.org namespaces and 1,039 endpoints, with
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

Explicit HTTPS downloads use byte limits and optional expected size and SHA-256
checks. A verified result is moved to the selected destination; failed transfers
preserve an old destination. Downloads require curl 8.4 or later, with no
automatic installation, retry, resume or cache.

The default local reader accepts BioDataLink JSON version 1 and returns a cells-by-genes
sparse matrix, aligned cell and gene metadata, source provenance and a content
hash. Omitted entries become numerical zeros; the format cannot separately
represent missing measurements. Structural validation does not establish the
meaning of the values or verify a declared normalization procedure. The bundled
JSON example is synthetic.

An explicit AnnData format reads selected supported H5AD matrices using a
configured Python interpreter with h5py and NumPy. It preserves original axis
positions, duplicate labels and missing annotations, and lists omitted
structures. The result is not a complete AnnData object. Normalization is
unspecified and no whole-file checksum is computed. Optional dependencies are
not installed automatically.

Eleven worked tutorials connect discovery and import to measurement geometry,
finite-state encodings, sparse-data interpretation, similarity networks,
held-out rule comparison, explicit cellular-automaton observation models and
measurement selection under stated error bounds.
Computed figures use attributed Iris measurements or clearly labeled synthetic
inputs. These examples use built-in Wolfram Language and do not require a
sibling modeling paclet.

The source registry is provided by Identifiers.org under CC BY 4.0. Its license
and attribution are retained alongside the bundled data; the paclet code is MIT.
The UCI Iris example is also CC BY 4.0, with its source citation, units and
retrieved-content hash retained beside the unmodified data.

After installing a built paclet archive, load its main context with
<code>Needs["WolframInstitute\`BioDataLink\`"]</code>.
