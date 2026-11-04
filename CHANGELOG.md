# Changelog

## 0.2.0 — Broad source discovery

- Add offline source discovery, namespace metadata and identifier resolver URLs
  from a provenance-bearing Identifiers.org registry snapshot (CC BY 4.0).
- Add explicit paginated public metadata queries for BioStudies and GEO, with
  provider-specific records, retrieval time and query-bound continuation cursors.
- Accept named environment or system-credential references for an optional NCBI
  API key; keep secret values out of results, URLs, cursors and diagnostics.
- Cache validated bundled catalogs per kernel. Precompute source search text
  and a namespace index, and batch GEO summaries per page.
- Keep source listing, public accessibility, file retrieval and native import
  capabilities distinct. Add scientist-facing discovery examples and limits.

## Unreleased — 0.1.0

- Add the initial BioDataLink paclet structure with Catalog and DataAccess areas.
- Add offline search and metadata inspection for a pinned Pertpy catalog snapshot.
- Add local BioDataLink JSON version 1 import with sparse matrices and aligned metadata.
- Parse and hash the same bounded input bytes, distinguish read failures, and reject malformed catalog records.
- Clarify source-declared metadata, loader variants, missing measurements and synthetic examples for scientific use.
- Add the provider design, interchange contract and initial reference/tutorial sources.
- Adapt contributor/review playbooks and documentation conventions from
  WolframInstitute/PureMath develop, and build/release automation from
  WolframInstitute/Ruliology.

Remote biological data download and AnnData/H5AD conversion are planned.
