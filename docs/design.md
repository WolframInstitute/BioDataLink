# BioDataLink design

BioDataLink aims to connect Wolfram Language researchers to biological data
across domains, including sequences, structures, expression, pathways, imaging
and biodiversity. Discovery should eventually cover public and controlled
sources, with access requirements stated explicitly. This broad scope is a
design goal, not a claim of current coverage.

Version 0.3 combines a source directory, resolver links, public BioStudies/GEO
metadata queries, explicit HTTPS downloads and local JSON or selected H5AD reading.
Ruliobiology can consume supported data later for model fitting and comparison.

This document separates the initial implementation from the extension contract.
The [build index](build-index.md) records public symbols and implementation
status. The [roadmap](../ROADMAP.md) records the release gates.

## Intended researcher workflow

1. Find a source in the bundled directory, search a supported public API, or search the offline Pertpy catalog.
2. Inspect available source descriptions, identifiers, study, organism and assay metadata.
3. Select a data file and an explicit download location.
4. Retrieve the artifact and keep its source identity and integrity evidence.
5. Import a supported representation, retaining cell and gene identifiers.

Discovery, download and native import are separate capabilities. A catalog
entry does not imply that the paclet can convert its data format. A study can
produce several datasets, processed versions and data files (called artifacts
in the retrieval interface). A source identifier may name a study, dataset,
loader or file; adapters must state which it identifies. A repository accession
is an identifier assigned by the repository, not an interchangeable name for
every catalog ID. The current implementation supports source metadata and
study queries, explicit file downloads, and documented local reader formats.

## Architecture

```mermaid
flowchart LR
    User[Wolfram notebook] --> Catalog[Catalog search and metadata]
    Catalog -. selected URL .-> Download[Explicit HTTPS download]
    Download --> Local[Local file and retrieval record]
    Local --> Import[Selected local format reader]
    Import --> Native[Wolfram arrays and metadata]
```

The kernel contains a small stable interface and provider-independent validation.
Provider adapters describe source identifiers, artifacts and capabilities.
Format readers own the conversion into Wolfram objects. Public functions return
ordinary Wolfram expressions where those express the result clearly.

Keep metadata discovery and provider queries in Wolfram Language. A small curl
interface streams explicit HTTPS file downloads; the selected H5AD reader uses
an explicit Python interpreter with pinned h5py/NumPy requirements. A future
CELLxGENE connection may use its data access library. Installing the core paclet
must not silently install optional dependencies.

Use bundled registry and catalog snapshots for reproducible offline discovery.
Updates are reviewed changes with their own source evidence. Live search is a
separate operation with a recorded query, provider and retrieval time.

## Implemented capabilities

`BioDataSourceSearch`, `BioDataSourceInfo` and `BioDataURL` use a bundled
Identifiers.org registry containing 867 namespaces and 1,039 endpoint records.
Of these, 93 namespaces and 35 endpoints are deprecated; source search excludes
deprecated namespaces by default. The registry includes biological and other
domains. A namespace is an identifier system, not necessarily a repository,
and registry inclusion is not proof of open access or an implemented API.

The source-info result preserves complete registry and endpoint records, with
source retrieval time, raw-byte hash, license and transformation details.
The registry is distributed under CC BY 4.0 with attribution and modifications
recorded separately from this paclet's MIT-licensed code.

`BioDataURL` constructs resolver links offline. Ordinary namespaces use compact
identifier form. Namespaces whose local identifiers embed a prefix use the
supported namespace/full-identifier URI form, preserving the complete original
identifier and its case. Bare IDs for these namespaces are rejected rather
than guessing a prefix. Colons and slashes remain literal because the resolver
does not interpret encoded forms consistently. Source regexes, accession
existence, current availability and licenses are not validated by link
construction. See the [Identifiers.org migration documentation](https://docs.identifiers.org/pages/migration.html)
for continued support of the URI form.

`BioDatasetQuery` provides one online page of BioStudies study metadata or GEO
Series metadata. A normalized view retains complete source search hits or
summaries in `ProviderMetadata`, absent values as `Missing`, and source-provided
organism strings or lists without inference. Results include the original
query, source endpoint, retrieval time, reported total, exactness flag and
continuation cursor. These live accessions are separate from the keys accepted
by the offline `BioDatasetInfo` function.

The Pertpy catalog provides search and metadata inspection over 55
loader records extracted from a pinned Pertpy source revision, plus import of
local BioDataLink JSON version 1 files. The records include example data and
processed variants; they are not 55 independent studies. Descriptions are
source-declared metadata, not reviewed scientific annotations. Missing organism
fields remain unknown even when a linked study reports its organism.

Many Pertpy datasets originate in scPerturb. Keep upstream identifiers and
source revisions. Catalog entries explicitly report that native
import of the listed provider artifacts has not yet been verified. The snapshot
records the code revision used for extraction; the listed remote artifacts have
not been downloaded or independently verified by this implementation.

`BioDatasetDownload` retrieves one explicitly supplied HTTPS URL into a chosen
local path. It streams to a sibling temporary file, enforces a finite file-size
limit, compares optional expected size and SHA-256, and places the file only
after validation. The result retains measured and expected hashes separately,
retrieval time, redacted source/final URLs and a hash of the exact request URL.
It does not infer a source file from a study accession, decompress archives,
cache, retry or resume. The implementation requires curl 8.4 or later so an
unknown Content-Length does not remove the transfer limit.

`BioDatasetLoad` defaults to the [JSON interchange format](interchange-format.md).
The explicit AnnData format reads supported dense/CSR/CSC H5AD measurements
with selected axis positions and layers, preserving source metadata and listing
omitted structures. It is a matrix-and-metadata selection, not a complete
AnnData-object conversion. A configured interpreter is required; no environment
is installed or discovered implicitly beyond the documented environment variable.

Generic format support does not validate every listed provider file; catalog
`NativeImportSupported` flags remain false until per-entry import verification.
GEO still provides metadata search rather than an accession-to-file retrieval
adapter. Offline coverage is defined by the bundled copies, not by newer
upstream versions.

## Performance and query boundaries

The kernel loads and validates each bundled registry or catalog only on first
use. Successful results are cached per file path for the rest of the kernel
session. Prefix indexes and lowercase search text are prepared once. Updating
a bundled source file is an explicit maintenance operation; restart the kernel
afterward to use the updated copy. No public cache-management API is required.

Live searches retrieve one page at a time. GEO obtains summaries in one batch
per page, avoiding one request per record. The public time limit includes
request pacing. A page-size limit controls the number of returned records,
not the byte size of scientific data or a promise of constant response time.

Follow continuation cursors until none remains. BioStudies may report an
estimated total; GEO's exact count applies to its current index and can change
between requests. These searches are not immutable database releases and may
include overlapping study records. A timeout or failed source must not be
reported as a successful empty result.

GEO API keys are optional references to an environment variable or system
credential, resolved at request time. They increase the public request quota;
they do not authorize private data access. Literal secrets are rejected, and
request URLs, credentials and response bodies are omitted from failures.
Future authenticated providers must define their own authorization, data
scope and secret handling before advertising private-data access.

The H5AD reader limits selected rows times columns and the serialized result
transferred back to Wolfram Language. It preserves sparsity and reads selected
source segments, but those limits do not bound all disk I/O or resident memory:
HDF5 chunks and variable-length strings can require larger intermediate
allocations. Keep whole-file size limits explicit. Performance measurements
must include interpreter startup, selection, metadata conversion, serialization
and Wolfram reconstruction, not only a Python slicing operation.

## Common data semantics

The local readers return two-dimensional sparse arrays with aligned row and
column metadata. JSON defines cells on rows and genes on columns. AnnData uses
observations and variables, which need not represent cells and genes despite
the shared property names. AnnData selections preserve duplicate original IDs
and add unique one-based source positions; JSON requires unique IDs. Never join
or collapse columns solely by a repeated display label.

The local format records a declared normalization string and source provenance.
These JSON fields are required but their scientific truth is not validated. The
`Counts` label requires nonnegative integer matrix values, which alone do not
establish read versus molecule counts or the processing history. Future provider
readers additionally record the selected source layer, transformations, units,
organism and reference assembly where supplied. Unknown metadata stays unknown.
Do not infer counts solely from integer values or cell types from row labels.

AnnData normalization remains unspecified even for a layer named `counts`,
`normalized` or the `raw` storage location. Missing annotations are preserved;
selected NaN or infinite measurements are rejected. The reader does not infer
measurement-presence masks from omitted structures. Metadata encoding records
retain categorical ordering, category count and the selected levels at their
source positions, without importing unused category labels.

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

There is currently no data-file cache. Future cache entries must use source
identity and release or artifact digest. A cache hit
must satisfy the same integrity checks as a fresh transfer. Interrupted
transfers must not become completed cache entries. Download limits, overwrite
behavior and failure modes belong in the public contract.

The JSON reader hashes the same bounded bytes it parses. The H5AD reader avoids
a full-file scan and returns `Missing["NotComputed"]` for the content hash;
file size and modification time are recorded as change-detection information,
not a checksum. Keep an independently retained download record or compute a
hash explicitly when a workflow requires stronger source-file identification.

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

- [Identifiers.org registry API](https://docs.identifiers.org/pages/api.html)
  documents the source directory, with [CC BY 4.0 terms](https://docs.identifiers.org/pages/terms_of_use.html).
- [BioStudies](https://www.ebi.ac.uk/biostudies/)
  supplies public study metadata and links to associated data.
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
