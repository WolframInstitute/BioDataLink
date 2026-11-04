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

## Next — More source APIs and authorized access

Extend tested metadata APIs across biological domains while preserving each
source's record types and search semantics. Add authenticated access only for
explicitly supported providers, using credential references and recording the
permitted scope without exposing secrets. Current GEO key support affects
public rate limits; it does not grant access to private research data.

Gate: checked small results, explicit access requirements and no credentials in
records, provenance, cursors or failure reports. A directory entry alone is
not an implemented connection.

## Next — Verified remote artifacts

Add explicit artifact download with source byte lengths, expected checksums,
local content hashes, bounded transfers, atomic cache placement and retryable
failures. Validate representative small public files and mock the failure paths
in default tests. Preserve provenance beside each cached artifact.

Gate: download and cache results match independent checks; failed transfers
cannot appear as completed data. Search remains usable without network access.

## Next — Pertpy and AnnData imports

Add an optional, versioned Python environment for H5AD/AnnData conversion.
Verify three representative datasets before advertising native import support.
Keep matrices sparse, preserve cell/gene alignment, expose the chosen expression
layer and record transformations and omitted structures.

Gate: an independently checked small slice agrees in matrix values, labels,
normalization state and provenance. Installing or searching the core paclet
must not implicitly install Python dependencies or download biological matrices.

## Later — CELLxGENE subsets and GEO data files

Add CELLxGENE Census queries with pinned releases and cell/gene selection.
Return source-study citations for selected slices. Distinguish a remote slice
from filtering a fully downloaded file.

Extend existing GEO Series discovery with file metadata and retrieval. Native
imports are enabled format by format. Repository breadth does not imply
uniform data semantics.

Gate: provider capabilities and unsupported cases are visible, with independent
fixtures for each advertised import format and opt-in live checks.

## Later — Analysis consumers

Provide documented examples that use imported data in Wolfram analysis and
Ruliobiology models. Begin with perturbation summaries and held-out comparisons.
Keep discovery/import contracts separate from particular statistical models.

Gate: analysis notebooks retain source versions, selections and preprocessing,
and distinguish observed data from model predictions.
