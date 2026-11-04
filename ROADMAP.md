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

## Next — Broad source discovery

Build a source directory spanning sequences, structures, expression, pathways,
imaging and biodiversity. Use authoritative source registries and retain their
provenance. Make each source's identifiers, data types, access requirements and
implemented operations visible. Add tested search APIs incrementally; listing
a source does not establish a working data connection.

Plan explicit credential handling for restricted sources without embedding
secrets in catalog records, URLs, examples or provenance. Access rights remain
those of the source and the researcher's account.

Gate: directory records trace back to their source, supported live searches
return checked small results, and unsupported operations remain clear.

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

## Later — CELLxGENE and GEO

Add CELLxGENE Census queries with pinned releases and cell/gene selection.
Return source-study citations for selected slices. Distinguish a remote slice
from filtering a fully downloaded file.

Add GEO discovery and artifact metadata first. Native imports are then enabled
format by format. Repository breadth does not imply uniform data semantics.

Gate: provider capabilities and unsupported cases are visible, with independent
fixtures for each advertised import format and opt-in live checks.

## Later — Analysis consumers

Provide documented examples that use imported data in Wolfram analysis and
Ruliobiology models. Begin with perturbation summaries and held-out comparisons.
Keep discovery/import contracts separate from particular statistical models.

Gate: analysis notebooks retain source versions, selections and preprocessing,
and distinguish observed data from model predictions.
