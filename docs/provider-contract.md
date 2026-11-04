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

Each adapter advertises only implemented operations. Version 0.1 implements
Catalog for the Pertpy snapshot and Native import for local BioDataLink JSON.
Download and Remote subset are planned:

| Capability | Meaning |
| --- | --- |
| Catalog | A dataset can be discovered and its metadata inspected |
| Download | A specified artifact can be retrieved and its result checked |
| Native import | A documented format can be converted to Wolfram data |
| Remote subset | The provider returns a requested slice before a full artifact is downloaded |

A cell limit applied after downloading a file is not remote subset support.
Display transfer requirements separately from the amount of data returned to
the caller. H5AD downloads alone do not establish AnnData conversion support.

## Artifacts

An artifact has a source URL, format and filename. Include source byte length
and checksum when available, and distinguish these expected values from values
measured after download. An adapter must reject unsupported formats explicitly
before attempting a conversion.

Retrieve data only after an explicit data operation. Keep search and metadata
inspection cheap. The artifact downloader owns cache verification, byte limits,
timeouts, temporary files and final placement. An adapter must not introduce a
second downloader with different semantics.

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
