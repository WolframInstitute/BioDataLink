---
Template: Symbol
Name: BioDatasetInfo
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetInfo
Keywords: [catalog, metadata, provenance, identifiers]
SeeAlso: [Association, BioDatasetDownload, BioDatasetLoad, BioDatasetSearch]
RelatedGuides: [BioDataLink, Catalog]
RelatedTutorials: [ExploringBiologicalData]
---

## Usage

<code>[BioDatasetInfo]()[{*provider*, *id*}]</code> gives the bundled catalog record for the specified provider and identifier.

## Details & Options

- The result is an `Association` containing the complete record.
- Both *provider* and *id* are case-sensitive strings.
- Information comes from the bundled catalog; this operation performs no network request.
- Pertpy identifiers are data-loader names, not repository accessions. Multiple records can refer to files or processed versions from the same study.
- Descriptions and links are extracted from the source. BioDataLink has not independently reviewed them as scientific annotations.
- An unknown pair gives a `Failure` with tag `"UnknownDataset"`.
- The catalog records these fields:

| | |
| --- | --- |
| `"Provider"`, `"ID"` | Provider namespace and source identifier |
| `"Title"`, `"Description"` | Description derived from the source loader |
| `"Organism"`, `"Citation"` | Reported organism and citation, or `Missing` when unavailable |
| `"DocumentationURL"` | Dataset documentation page |
| `"SourceURL"`, `"SourceRevision"` | Source code location and pinned revision used for the snapshot |
| `"DownloadURLs"` | Data-file links recorded from the source loader |
| `"NativeImportSupported"` | Whether this catalog entry advertises a verified import route |

- Source links are metadata. This function neither downloads those files nor verifies that a remote server is currently available.
- `"Organism"` is `Missing["NotAvailable"]` throughout the current catalog because the source lacks structured organism annotations. This does not imply that the underlying studies lack organism information.
- `"NativeImportSupported"` is `False` for all current Pertpy records.
- A general H5AD reader does not by itself verify every provider file. The catalog flag remains separate from format support and optional-interpreter availability.

## Basic Examples

Inspect the record for Pertpy's `"norman_2019"` loader:

```wl
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

## Scope

Inspect the source citation alongside an unavailable organism annotation:

```wl
KeyTake[BioDatasetInfo[{"Pertpy", "norman_2019"}], {"ID", "Organism", "Citation"}]
```

Keep `Missing["NotAvailable"]` as unknown. A citation or a familiar study title
does not supply a structured organism annotation that can safely be inferred
by this function.

## Applications

Inspect file links for two versions associated with one study:

```wl
Dataset[KeyTake[BioDatasetInfo[{"Pertpy", #}], {"ID", "DownloadURLs"}] & /@ {"norman_2019", "norman_2019_raw"}]
```

These are source-declared links. The metadata lookup neither transfers the
files nor verifies that their processing makes them suitable for a comparison.

Retain the source revision alongside a selected identifier:

```wl
KeyTake[BioDatasetInfo[{"Pertpy", "norman_2019"}], {"Provider", "ID", "SourceRevision", "DocumentationURL"}]
```

## Possible Issues

An unknown source identifier gives a structured failure:

```wl
BioDatasetInfo[{"Pertpy", "no-such-biodatalink-dataset"}]
```
