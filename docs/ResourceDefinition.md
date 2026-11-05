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

Find biological datasets, download a chosen file and read local measurements
in Wolfram Language. Results retain identifiers, metadata and provenance.

### Search

- Identifiers.org directory: 774 namespaces, offline
- Pertpy dataset catalog: 55 loader records, offline
- BioStudies studies and GEO Series: online

### Real data in the tutorials

- Single-cell expression: 10x Genomics PBMC3k
- Protein structures: PDB 4AKE and 1AKE
- Genomes: *Borrelia burgdorferi* B31; SARS-CoV-2, RaTG13 and SARS-CoV
- Circadian expression: mouse liver, GEO GSE11923

## Details & Options

- Search the bundled Identifiers.org directory and 55 Pertpy loader records
  offline. Listings are source metadata, not verified data imports.
- Search public BioStudies studies or GEO Series online, one page at a time.
- Download an explicit HTTPS file with a size limit and optional expected
  SHA-256. Requires curl 8.4 or later.
- Read BioDataLink JSON as a cells-by-genes sparse matrix. Unlisted entries are
  zero; the format has no missing-measurement mask.
- Read selected AnnData H5AD measurements with an explicitly configured Python
  interpreter, h5py and NumPy. This preserves selected axis metadata, not the
  complete AnnData object. Normalization is unspecified; no whole-file hash is
  computed.

Readers check structure without normalizing values or validating biological
claims. Optional dependencies are installed separately.

Applications cover single-cell expression, protein structures, genomes and
circadian rhythms. Real examples retain their sources, selections, licenses
and checksums; synthetic examples are labeled.

The code is MIT licensed. Data keep their own terms: CC BY 4.0 for the registry,
Iris and PBMC examples; CC0 for PDB structures; NCBI policies for sequences and
GEO data.

After installation, load the package with
<code>Needs["WolframInstitute\`BioDataLink\`"]</code>.
