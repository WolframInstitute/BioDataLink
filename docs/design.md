# BioDataLink design

BioDataLink aims to connect Wolfram Language researchers to biological data
across domains, including sequences, structures, expression, pathways, imaging
and biodiversity. Discovery should eventually cover public and controlled
sources, with access requirements stated explicitly. This broad scope is a
design goal, not a claim of current coverage.

The first implementation searches Pertpy metadata and reads local expression
matrices. Ruliobiology can consume supported data later for model fitting and
comparison.

This document separates the initial implementation from the extension contract.
The [build index](build-index.md) records public symbols and implementation
status. The [roadmap](../ROADMAP.md) records the release gates.

## Intended researcher workflow

1. Search the bundled catalog without starting Python or downloading matrices.
2. Inspect available source descriptions, identifiers, study, organism and assay metadata.
3. Select a dataset artifact and an explicit download location or cache.
4. Retrieve the artifact and keep its source identity and integrity evidence.
5. Import a supported representation, retaining cell and gene identifiers.

Discovery, download and native import are separate capabilities. A catalog
entry does not imply that the paclet can convert its data format. A study can
produce several datasets, processed versions and data files (called artifacts
in the retrieval interface). A source identifier may name a study, dataset,
loader or file; adapters must state which it identifies. A repository accession
is an identifier assigned by the repository, not an interchangeable name for
every catalog ID. The current implementation supports steps 1 and 2 using only
the fields in the bundled catalog, and step 5 for the local JSON format.

## Architecture

```mermaid
flowchart LR
    User[Wolfram notebook] --> Catalog[Catalog search and metadata]
    Catalog --> Adapter[Provider adapter]
    Adapter --> Cache[Artifact cache and provenance]
    Cache --> Import[Format-specific import]
    Import --> Native[Wolfram arrays and metadata]
```

The kernel contains a small stable interface and provider-independent validation.
Provider adapters describe source identifiers, artifacts and capabilities.
Format readers own the conversion into Wolfram objects. Public functions return
ordinary Wolfram expressions where those express the result clearly.

Keep metadata discovery and ordinary HTTP requests in Wolfram Language. The
planned Python adapter handles AnnData/H5AD and CELLxGENE's data access library.
Its environment must be explicit and its dependencies versioned. Installing
the core paclet must not silently install Python packages.

Use a bundled catalog snapshot for reproducible offline discovery. Updates are
reviewed changes with their own source evidence. Future live search is a
separate operation with a recorded query, provider and retrieval time.

## Initial scope

The initial implementation provides search and metadata inspection over 55
loader records extracted from a pinned Pertpy source revision, plus import of
local BioDataLink JSON version 1 files. The records include example data and
processed variants; they are not 55 independent studies. Descriptions are
source-declared metadata, not reviewed scientific annotations. Missing organism
fields remain unknown even when a linked study reports its organism.

Many Pertpy datasets originate in scPerturb. Keep upstream identifiers and
source revisions. Catalog entries explicitly report that native
import of the listed provider artifacts is not yet supported. The snapshot
records the code revision used for extraction; the listed remote artifacts have
not been downloaded or independently verified by this implementation.

Remote artifact download, AnnData conversion and CELLxGENE/GEO adapters are
later milestones. The [interchange format](interchange-format.md) is the current
local import contract. Catalog coverage is defined by the bundled snapshot, not
by what a newer upstream version may expose.

## Common data semantics

The implemented local JSON reader returns a two-dimensional `SparseArray` with
cells on rows and genes on columns. Future provider readers must preserve this
orientation. Cell and gene metadata have the same order
as the corresponding matrix axis. The interface must expose stable identifiers
alongside display names and preserve duplicate gene symbols explicitly.

The local format records a declared normalization string and source provenance.
These fields are required but their scientific truth is not validated. The
`Counts` label requires nonnegative integer matrix values, which alone do not
establish read versus molecule counts or the processing history. Future provider
readers additionally record the selected source layer, transformations, units,
organism and reference assembly where supplied. Unknown metadata stays unknown.
Do not infer counts solely from integer values or cell types from row labels.

Version 1 fills every unlisted matrix coordinate with zero and has no separate
missing-measurement representation. Importers must not map unmeasured genes or
unknown values to these zeros. For example, the
[Census schema](https://chanzuckerberg.github.io/cellxgene-census/cellxgene_census_docsite_schema.html)
records gene measurement presence by dataset separately from its expression
matrix. A future format must preserve such information, or the conversion must
explicitly restrict itself to a supported selection or refuse the import.

Keep additional layers, embeddings and observations available through documented
properties or source references. A conversion must not silently drop data and
present itself as a complete import. A subset records its row and column selection.

## Reproducible retrieval

A useful retrieval record identifies the provider, dataset, source release,
artifact URL, local file, byte count and content hash. Preserve an expected
upstream checksum separately from the locally calculated hash. A calculated
hash records what was received; it does not by itself establish agreement with
the provider's intended artifact.

Cache entries use source identity and release or artifact digest. A cache hit
must satisfy the same integrity checks as a fresh transfer. Interrupted
transfers must not become completed cache entries. Download limits, overwrite
behavior and failure modes belong in the public contract.

Source versions are important for cloud catalogs: CELLxGENE Census exposes
versioned releases as well as shorter-lived builds. Future adapters should pin
a release and retain the original study citations for a selected slice.

## Verification

Default tests and documentation examples use bundled metadata and small local
fixtures. They establish interface behavior without requiring provider uptime,
large downloads or credentials. Live provider checks are opt-in and report
source release, time, bytes and outcomes separately.

Before adding an adapter, verify a complete small result against the source:
metadata, dimensions, cell/gene alignment, selected values, missing fields,
checksum handling and failure behavior. New native import support needs an
independent expected fixture, not only a round trip through its own exporter.

## Source references

- [Pertpy dataset catalog](https://pertpy.scverse.org/en/stable/api/datasets_index.html)
  describes the available loaders and their source datasets.
- [scPerturb](https://projects.sanderlab.org/scperturb/) supplies harmonized
  single-cell perturbation datasets and links to versioned archives.
- [CELLxGENE Census](https://chanzuckerberg.github.io/cellxgene-census/)
  supports cell and gene queries, selected slices and versioned releases.
- [GEO programmatic access](https://www.ncbi.nlm.nih.gov/geo/info/geo_paccess.html)
  separates Entrez metadata discovery from data-file retrieval.
- [DISCOSingleCellAtlas](https://resources.wolframcloud.com/FunctionRepository/resources/DISCOSingleCellAtlas/)
  is an existing Wolfram Function Repository interface for tissue-level cell and
  expression data; BioDataLink's proposed contribution is a common provider and
  provenance contract across datasets.
