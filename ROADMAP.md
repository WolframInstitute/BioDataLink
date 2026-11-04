# BioDataLink roadmap

Each milestone adds a capability researchers can verify. Implemented symbols
are tracked in the [build index](docs/build-index.md); design details live in
[the design record](docs/design.md).

The long-term scope is biological data across domains, rather than expression
data alone. Discovery coverage, permission to access a source, file retrieval
and supported scientific interpretation are separate milestones. Broad source
coverage will not imply that every data type can be loaded or compared.

## 0.1 — Catalog and native interchange foundation

The initial implementation provides:

- Offline search of a pinned Pertpy dataset metadata snapshot.
- Source-aware dataset information through a provider and identifier pair.
- A validated local JSON interchange format with a cells-by-genes sparse matrix,
  aligned cell and gene metadata, declared measurement scale and provenance.
- Tests, Markdown documentation sources, notebook generation, packaging and
  release automation adapted from Ruliology, with PureMath develop as the
  preferred source for authoring and review conventions.

Before release, run the configured checks, inspect generated documentation,
verify the packed paclet in a fresh kernel, and record its runtime dependencies.
Documentation source presence alone does not satisfy the notebook review gate.
A public repository, release tag and cloud publication are separate deployment
steps.

## 0.2 — Source discovery and public study queries

The local development milestone adds:

- A bundled Identifiers.org directory with 867 namespaces and 1,039 endpoints,
  including deprecated records. Default search returns 774 active namespaces.
- Source descriptions, identifier conventions, complete registry records and
  source provenance through `BioDataSourceSearch` and `BioDataSourceInfo`.
- Offline resolver-link construction through `BioDataURL`, preserving complete
  original identifiers for namespaces with embedded prefixes.
- Paginated public BioStudies and GEO Series queries through `BioDatasetQuery`,
  retaining original metadata, missing values and retrieval information.
- Per-kernel caches and indexed source lookup, plus batched GEO summaries.
- Optional named GEO API-key references for public request quotas.

The directory spans biological and other domains and is nonexhaustive.
Registry membership does not establish open access or implemented data-file
retrieval. Live search and representative resolver checks are recorded in
[the validation note](docs/notes/2026-11-04-source-discovery-validation.md),
alongside qualified local performance measurements. Version 0.2 is a local
milestone, not a published release.

## 0.3 — Verified file downloads and selected H5AD reading

The local development milestone adds:

- `BioDatasetDownload` for explicit HTTPS files, bounded streamed transfers,
  optional expected byte counts and SHA-256, and destination replacement only
  after validation. Retrieval records distinguish computed and expected hashes.
- An explicit `"Format" -> "AnnData"` branch of `BioDatasetLoad`, backed by an
  optional configured Python interpreter with pinned h5py/NumPy requirements.
- Selected dense, CSR or CSC matrices with aligned metadata, original axis
  positions, duplicate labels, missing annotations and omitted-structure lists.
- Scientist-facing examples for metadata review, named JSON selections,
  pagination termination, verified downloads and measurement interpretation.
- Eleven worked tutorials with computed figures, including measurement geometry,
  discretization, similarity networks, sparse-data semantics and finite rule
  comparisons and measurement-panel selection, using built-in Wolfram Language.
- An attributed UCI Iris copy for offline tabular examples and a synthetic
  H5AD fixture checked against independently specified values.

There is no implicit cache, automatic retry, resume or complete AnnData-object
conversion. H5AD file fingerprints are not content hashes, and a generic reader
does not certify every catalog entry. Optional dependencies remain explicit.

## Next — More source APIs and authorized access

Extend tested metadata APIs across biological domains while preserving each
source's record types and search semantics. Add authenticated access only for
explicitly supported providers, using credential references and recording the
permitted scope without exposing secrets. Current GEO key support affects
public rate limits; it does not grant access to private research data.

Gate: checked small results, explicit access requirements and no credentials in
records, provenance, cursors or failure reports. A directory entry alone is
not an implemented connection.

## Next — Dataset-specific import verification

Verify representative provider files using explicit source releases, selected
layers and independently checked small results before advertising per-entry
import support. Extend supported encodings and missing-measurement semantics
only when they can be preserved without guessing. Keep transfer integrity,
format compatibility and scientific interpretation as separate checks.

Gate: selected values, labels, processing information and provenance agree with
independent evidence. Any future cache or resume facility must preserve the
integrity checks of a new transfer.

## Later — CELLxGENE subsets and GEO data files

Add CELLxGENE Census queries with pinned releases and cell/gene selection.
Return source-study citations for selected slices. Distinguish a remote slice
from filtering a fully downloaded file.

Extend existing GEO Series discovery with file metadata and retrieval. Native
imports are enabled format by format. Repository breadth does not imply
uniform data semantics.

Gate: provider capabilities and unsupported cases are visible, with independent
fixtures for each advertised import format and opt-in live checks.

## Later — Dataset-specific analysis consumers

Extend the current small computational tutorials to source-specific
perturbation summaries and tested Ruliobiology integrations. Retain the existing
separation between data access, an observation model and a fitted hypothesis.
Keep discovery/import contracts separate from particular statistical models.

Gate: analysis notebooks retain source versions, selections and preprocessing,
and distinguish observed data from model predictions.
