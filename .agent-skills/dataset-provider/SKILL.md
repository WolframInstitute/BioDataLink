---
name: dataset-provider
description: Add or update a BioDataLink catalog source, local data format, or external provider adapter; preserve identifiers, provenance, supported capabilities, and offline test fixtures.
---

# Add a dataset provider

Read [Dataset contracts](../../GUIDE.md#dataset-contracts), the relevant design
record and the current provider implementation. The initial implementation is
a bundled Pertpy metadata catalog and a local sparse JSON v1 importer. Network
download and Python/H5AD support remain proposals until implemented and tested.

## Establish the source contract

Use official API or format documentation and record the source revision and
retrieval date. Identify catalog, download, subset and import capabilities
separately. Inspect a small representative record or file before deciding what
metadata can be normalized. Keep source fields that do not fit the common
schema available without inventing values for missing annotations.

For catalog changes, retain accession, provider, source URL and citation.
Check record uniqueness and stable identity. A provider loader appearing in
Pertpy's catalog does not establish that this paclet imports its file format.
Mark verification status from actual evidence.

For data access, define axes, identifiers, layers, units, sparse representation,
revision selection and failure behavior. State whether slicing occurs remotely
or after a full download. Record API or schema differences in `docs/design.md` or a focused `docs/notes/` record
and link the relevant provider documentation.

## Implement and verify

Use [implement-biodata-functions](../implement-biodata-functions/SKILL.md) for
kernel changes. Prefer native HTTP and standard import facilities where they
fit; use an explicit optional Python adapter when the format requires it.
Apply [Cost and backend boundaries](../../GUIDE.md#cost-and-backend-boundaries)
for cache identity, bounded access and conversion.

Build a small independent fixture that catches dimension, axis-order and
identifier-alignment errors. Keep default tests offline. Live checks should be
explicit and bounded; report the exact accession, revision and operation tested.
Do not replace a working source adapter with a mock and call it a verified
remote import. Retain useful diagnostics for unreachable or changed providers.

Update the source record, capability description, tests and documentation
together. Changes to a dataset's counts/normalization meaning or identifier
mapping are contract changes, even if the file shape stays the same.
