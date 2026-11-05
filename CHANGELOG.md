# Changelog

## 0.3.4 — 2026-11-05

- Add a resource-page hero showing prefixes from the bundled Identifiers.org
  directory around the BioDataLink mark. Word size reflects registered access
  endpoints; colors show keyword-based subject domains.
- Add `make hero` to rebuild the image offline and include it in publication.
  Archive builds reject a missing or unreadable hero image.

## 0.3.3 — 2026-11-05

- Simplify all seven guides, eight symbol references and sixteen tutorials,
  retaining data provenance, measurement units, analysis choices and scientific
  limitations. Shorten supporting project and data-format documentation.
- Follow Wolfram Language reference conventions with concise usage descriptions,
  compact details, short example captions and separate scope, option and issue
  examples. Show imported matrices before metadata and provenance.
- Remove redundant analyses and unused tutorial helpers. Preserve native
  initialization, offline examples and explicit optional-backend requirements.

## 0.3.2 — 2026-11-04

- Add five case-study tutorials on real public data: single-cell expression in
  human blood (10x Genomics PBMC 3k), open and closed adenylate kinase
  structures (PDB 4AKE and 1AKE), sequence-composition patterns in the *Borrelia
  burgdorferi* chromosome, a comparison of SARS-CoV-2, RaTG13 and SARS-CoV
  genomes, and circadian rhythms in an hourly mouse liver time series
  (GEO GSE11923).
- Bundle the subsets behind these tutorials with provenance records, licenses
  and SHA-256 hashes. `make example-data` rebuilds them from pinned downloads
  through `BioDatasetDownload`; offline tests check the bundled files.
- Make tutorial and reference inputs copy-ready: figure-only setup sits in
  `With` beside each plot, one-use variables are removed and several
  computations use shorter built-in functions.
- Record figure rules: accessible category palettes, color maps chosen by
  the kind of value, area-scaled marks and checks for clipped plot ranges.
- Close the tutorial Initialization group by default in generated notebooks,
  with a visible opener for inspecting helpers. Check closure before and after
  native initialization, including cached and changed-helper builds.
- Add a single-cell example to the README quick start.
- Keep all cells and genes visible in the PCA plots and show the full range of
  protein backbone-angle changes. Check regenerated PBMC content independently
  of its changing retrieval timestamp while retaining fixed provenance checks.

## 0.3.1 — 2026-11-04

- Simplify the eleven tutorials and eight symbol references with shorter Wolfram
  Language inputs and focused examples. Retain the computed scientific figures,
  measurement semantics and progressive rule explorations.
- Move tutorial helpers to a final Initialization section. Generated notebooks
  evaluate these helpers before examples and retain native initialization cells.
- Shorten the README to installation, a quick start and published documentation
  links; README-only changes no longer start CI.
- Record concise example, reference-page and README conventions in the project
  documentation skills.

## 0.3.0 — 2026-11-04 — Initial public release

This release includes the discovery and local-import capabilities developed
during the 0.1 and 0.2 milestones, together with the additions below.

- Add explicit HTTPS artifact downloads with transfer limits, optional expected
  lengths and SHA-256 hashes, and verified placement in a caller-selected file.
- Add optional, bounded H5AD import through `BioDatasetLoad`, retaining selected
  matrix values, original axis identifiers and annotation missingness. The
  source layer and omitted structures are explicit; normalization is not inferred.
- Expand researcher examples for discovery, provenance, pagination, verified
  downloads, matrix selection and interpretation of missing annotations.
- Provide eleven worked tutorials, including measured-data geometry, finite-state
  encodings, predictive rule search, similarity networks, sparse measurements,
  cellular automaton hypotheses and measurement panel selection, with computed
  figures and explicit limits on scientific interpretation.
- Develop rules progressively from constants and individual thresholds to
  combined comparisons and wider spatial neighborhoods. Use graphs of rule
  changes, shared predictions and perturbation stability to compare hypotheses
  and analysis choices with fixed visual layouts.

## 0.2.0 — Development milestone: broad source discovery

Internal development milestone; not separately released.

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

## 0.1.0 — Development milestone: foundation

Internal development milestone; not separately released.

- Add the initial BioDataLink paclet structure with Catalog and DataAccess areas.
- Add offline search and metadata inspection for a pinned Pertpy catalog snapshot.
- Add local BioDataLink JSON version 1 import with sparse matrices and aligned metadata.
- Parse and hash the same bounded input bytes, distinguish read failures, and reject malformed catalog records.
- Clarify source-declared metadata, loader variants, missing measurements and synthetic examples for scientific use.
- Add the provider design, interchange contract and initial reference/tutorial sources.
- Adapt contributor/review playbooks and documentation conventions from
  WolframInstitute/PureMath develop, and build/release automation from
  WolframInstitute/Ruliology.

At version 0.1.0, remote file download and AnnData/H5AD import were planned.
