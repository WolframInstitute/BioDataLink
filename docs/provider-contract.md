# Provider adapter contract

An adapter connects a provider's catalog and artifact access to BioDataLink's
public operations. Keep provider details behind those operations. This is the
extension contract; the [build index](build-index.md) identifies implemented
capabilities.

The long-term scope spans biological data domains. The cells-by-genes rules
below apply to expression imports, not to every future provider: sequences,
structures, images and other data require their own documented representations.

## Identity and evidence

Identify a dataset by `{provider, id}`. The provider is an explicit namespace;
the identifier is the exact identifier supported by that adapter. Treat both
as case-sensitive unless the provider documents normalization. Never resolve
an ambiguous short name by selecting the first match.

State what an identifier names: a study, dataset, processed version, loader or
data file. A study may produce several catalog records. In the initial Pertpy
catalog the ID is a loader name, not a repository accession. Preserve source
accessions separately when available; do not infer them from loader names.

Record the source landing page, citation and source release where available.
An adapter review must identify which metadata were read from provider records
and which fields were curated. Preserve absent values explicitly. Discovery
should display the source's license or terms when supplied without asserting
that every dataset shares a single license.

## Capabilities

Each adapter advertises only implemented operations. Version 0.3 provides the
offline Identifiers.org source directory, resolver links, live BioStudies/GEO
metadata queries, the offline Pertpy catalog, explicit HTTPS file downloads,
local BioDataLink JSON reading and optional selected H5AD reading. Remote
matrix subsets are planned:

| Capability | Meaning |
| --- | --- |
| Source directory | Registered identifier systems and endpoints can be discovered |
| Identifier link | A resolver URL can be constructed without contacting the source |
| Catalog | A dataset can be discovered and its metadata inspected |
| Download | A specified artifact can be retrieved and its result checked |
| Native import | A documented format can be converted to Wolfram data |
| Remote subset | The provider returns a requested slice before a full artifact is downloaded |

A cell limit applied after downloading a file is not remote subset support.
Display transfer requirements separately from the amount of data returned to
the caller. H5AD downloads alone do not establish AnnData conversion support,
and a generic H5AD reader does not certify each catalog file. Keep per-entry
import flags false until the particular source and import route are checked.

## Metadata search and credentials

Source-directory records describe identifier systems; live query results
describe source studies or other explicitly documented entities. Keep these
record types distinct. The current GEO query returns Series, while BioStudies
returns study records. Preserve the provider's complete search hit or summary
alongside normalized fields, and retain missing values explicitly.

A live query returns one page with retrieval time, source endpoint, query,
reported total, total exactness and continuation cursor. Use provider-side
pagination and batch metadata summaries when available. Do not present a page
size as a byte-transfer limit. An estimated total must not determine whether
pagination has ended; follow the source's continuation signal. State when
pages can shift as a live index changes.

Accept credential references, not literal secrets. Resolve references only
when a request runs, and exclude credentials from records, cursors, provenance
and failures. The current implementation supports optional GEO API-key references for public
request quotas; it does not implement private-study access. A future private
provider needs a reviewed authentication flow, explicit access scope, and
separate tests demonstrating authorized retrieval without disclosure.

## Artifacts

An artifact has a source URL, format and filename. Include source byte length
and checksum when available, and distinguish these expected values from values
measured after download. An adapter must reject unsupported formats explicitly
before attempting a conversion.

Retrieve data only after an explicit data operation. Keep search and metadata
inspection cheap. The shared downloader owns byte limits, expected size/hash
checks, timeouts, temporary files and final placement. An adapter must not
introduce a second downloader with different semantics. The current downloader
does not cache, retry, resume or decompress data; a future cache must preserve
the same integrity checks.

Expected hashes need their own provenance. A successful comparison proves
agreement with the supplied digest, not that the source published it. Retain
computed and expected hashes separately. Source URL query parameters are
removed from the retrieval record; the exact requested URL is represented by
a hash instead of exposing potentially sensitive query values.

## Native expression imports

For a cells-by-genes matrix, preserve:

- Matrix dimensions and sparse storage.
- Ordered cell and gene identifiers with aligned metadata.
- Measurement layer, units and transformation state.
- The distinction between numerical zero and an unmeasured or unknown value.
- Source release, artifact identity and subset description.
- Missing and duplicate metadata values without silently inventing replacements.

Readers need to know whether values are raw counts, normalized measurements or
another layer. Matrix orientation and annotation alignment are part of the
public result contract, not implementation details. Integer-valued data alone
do not establish that values are raw counts, and counts may refer to reads or
molecules. A declared normalization label is not evidence that the procedure
was correctly applied. Retain the source's statements and local validation
results as distinct evidence.

BioDataLink JSON version 1 represents every omitted matrix coordinate as zero.
It cannot preserve a missing-measurement mask. A provider reader must refuse an
unsupported conversion or make an explicit, documented selection that avoids
unknown entries; it must not fill unmeasured genes with zeros silently. Unique
row and column labels establish alignment, not cell type, biological replication
or a valid gene-reference mapping.

The current H5AD reader is explicitly selected by format and interpreter.
It retains a selected matrix, ordered axis metadata and source positions;
duplicate labels remain separate. It does not construct a complete AnnData
object, import all unstructured provenance or infer processing from layer
names. Every result lists omitted structures. Its file-size and modification
fingerprint is not a full-file checksum, and its result-size limits are not
promises about all decompressed HDF5 data or process memory.

## Failure handling

Distinguish an unknown dataset, unsupported capability, unavailable provider,
invalid source response, interrupted transfer and checksum mismatch. A failed
transfer must not be returned as a completed artifact. A provider outage must
not produce an empty catalog that appears to be a successful search.

Return enough structured evidence for a caller to diagnose a failed retrieval
without exposing credentials or access tokens. Preserve original source
identifiers and URLs in provenance, with secret query parameters removed when
applicable.

## Adapter acceptance

Before advertising support, add an offline fixture and tests for the complete
small result, unsupported inputs, missing fields, wrong checksums, cache hits
and malformed artifacts where applicable. Test native imports against expected
matrix entries and labels obtained independently from the reader.

Keep live checks opt-in. Record their provider, release, time, artifact and
result. Update the catalog snapshot and relevant symbol pages only after the
implemented capability and its limits have been checked.
