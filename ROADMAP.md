# BioDataLink roadmap

The [build index](docs/build-index.md) lists current APIs; the
[design record](docs/design.md) explains their contracts. Discovery coverage,
access rights, file retrieval and scientific interpretation are separate.

## Implemented milestones

| Milestone | Delivered |
| --- | --- |
| 0.1 | Offline Pertpy catalog, source-aware records, validated JSON expression interchange, tests and build tooling |
| 0.2 (local milestone) | Identifiers.org directory and resolver links, paginated BioStudies/GEO metadata, cached indexes, batched GEO summaries and named API-key references |
| 0.3 | Bounded HTTPS downloads, selected H5AD reading with explicit Python, preserved labels/missing annotations, Iris and synthetic fixtures, computational tutorials |
| 0.3.2 | Five real-data case studies: PBMC expression, protein conformations, bacterial composition, coronavirus genomes and liver rhythms |

Current H5AD support is a selected matrix read, not complete AnnData conversion.
Downloads have no automatic cache, retry or resume. Generic format support
does not certify every catalog entry. See the
[source-discovery validation](docs/notes/2026-11-04-source-discovery-validation.md)
and [artifact/import validation](docs/notes/2026-11-04-artifact-import-validation.md)
for recorded evidence.

## Next — More source APIs and authorized access

Add tested metadata APIs across biological domains. Private access needs
provider-specific authorization, explicit scope and credential references.
Current GEO keys only affect public quotas.

Acceptance: independently checked small results, clear access requirements and
no secrets in records, cursors or failures.

## Next — Dataset-specific import verification

Check representative files by source release, selected layer, values, labels
and provenance before setting per-entry import flags. Extend encodings and
missingness support only when semantics can be preserved.

Acceptance: agreement with independent evidence; future caching or resume
must retain fresh-transfer integrity checks.

## Later — CELLxGENE subsets and GEO data files

Add pinned CELLxGENE Census slices with source-study citations, and extend GEO
discovery to file metadata and retrieval. Distinguish remote slicing from
filtering a full download. Enable native formats individually.

Acceptance: explicit capabilities and limits, independent fixtures and opt-in
live checks.

## Later — Dataset-specific analysis consumers

Add source-specific perturbation summaries and tested Ruliobiology integrations.
Keep data access separate from an observation model and fitted hypothesis.

Acceptance: reproducible notebooks with source versions, selections,
preprocessing and a clear distinction between observations and predictions.
