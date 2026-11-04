# Provider adapter contract

Adapters expose source capabilities through BioDataLink's public operations.
The [build index](build-index.md) lists implemented functions. Expression-matrix
rules below do not define future sequence, image or structure representations.

## Identity and evidence

Use `{provider, id}` with exact source identifiers, case-sensitive unless a
provider specifies otherwise. State whether an ID names a study, dataset,
processed version, loader or file. Pertpy loader names are not accessions;
retain source accessions separately. Never resolve an ambiguous name by taking
the first match.

Keep landing page, citation, release and source-specific terms when supplied.
Distinguish source metadata from curated fields and local checks. Missing
values stay missing; one provider need not have one license for all datasets.

## Capabilities

| Capability | Meaning |
| --- | --- |
| Source directory | Registered identifier systems and endpoints can be discovered |
| Identifier link | A resolver URL can be constructed without contacting the source |
| Catalog | A dataset can be discovered and its metadata inspected |
| Download | A specified artifact can be retrieved and its result checked |
| Native import | A documented format can be converted to Wolfram data |
| Remote subset | The provider returns a requested slice before a full artifact is downloaded |

Current support covers the Identifiers.org directory, resolver links,
BioStudies/GEO metadata, Pertpy catalog, HTTPS downloads, JSON import and
selected H5AD reading. Remote subsets remain planned.

A selection made after downloading a whole file is not a remote subset.
Generic format support does not certify each catalog file; advertise native
import per entry only after checking that source and import route.

## Metadata search and credentials

Keep namespace records distinct from study records. GEO returns Series and
BioStudies returns studies. Preserve full source hits beside normalized fields.
Each page records query, endpoint, retrieval time, total, exactness and cursor.
Follow continuation signals, not estimated totals. Live indexes can shift
between pages; page size limits records, not file bytes. Batch summaries when
the provider supports it.

Accept credential references, resolved only when requests run. Keep secrets
out of results, cursors, provenance and failures. Current GEO keys affect
public quotas. Private access needs its own reviewed authorization flow,
documented scope and tests.

## Artifacts

Record source URL, format, filename and any expected size or checksum.
Retrieve files only through an explicit data operation. Reuse the shared
downloader for limits, timeouts, temporary files, validation and placement;
reject unsupported formats before conversion.

Keep expected and computed hashes separate, including the origin of an
expected hash. Matching proves agreement with that digest, not its provenance.
Retrieval records redact URL query values and retain a hash of the exact request.
Current downloads do not cache, retry, resume or decompress; future facilities
must preserve the same integrity checks.

## Native expression imports

Preserve dimensions, sparse storage, ordered IDs, aligned metadata, units,
layer, processing, source revision and selection. Distinguish zero from
unmeasured values. Do not silently replace missing annotations or collapse
duplicate IDs. Integer values and layer names do not establish raw counts or
normalization; keep source declarations separate from local validation.

JSON version 1 has no measurement mask. Refuse unsupported conversion or
document a selection with no unknown entries; never silently zero-fill
unmeasured genes. Unique labels do not establish cell identity or replication.

H5AD requires an explicit format and configured interpreter. It preserves a
selected matrix, metadata and source positions, including duplicates, and lists
omitted structures. It is not a complete AnnData conversion. File size and
modification time are not checksums; result limits do not bound every HDF5 read
or all process memory.

## Failure handling

Distinguish unknown IDs, unsupported capabilities, provider outages, invalid
responses, interrupted transfers and checksum mismatches. Outages must not
appear as successful empty searches; incomplete files must not appear complete.
Return diagnostic context without credentials or secret URL values.

## Adapter acceptance

Test small offline results against independently specified values and labels.
Cover unsupported inputs, missing fields, corrupt files, checksum errors and
cache behavior where applicable. Keep live checks opt-in and record provider,
release, time, artifact and result. Update capability flags and documentation
only after the advertised path is checked.
