---
Template: Symbol
Name: BioDatasetInfo
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetInfo
Keywords: [catalog, metadata, provenance, identifiers]
SeeAlso: [BioDatasetDownload, BioDatasetLoad, BioDatasetSearch, Association]
RelatedGuides: [BioDataLink, Catalog]
RelatedTutorials: [ExploringBiologicalData]
---

## Usage

<code>[BioDatasetInfo]()[{*provider*, *id*}]</code> gives the bundled metadata for a dataset.

## Details

- The result is an `Association` obtained without a network request.
- *provider* and *id* are case-sensitive strings. Pertpy IDs are loader names, not repository accessions.
- Returned properties include:

| | |
| --- | --- |
| `"Provider"`, `"ID"` | Provider namespace and source identifier |
| `"Title"`, `"Description"` | Description derived from the source loader |
| `"Organism"`, `"Citation"` | Reported organism and citation, or `Missing` when unavailable |
| `"DocumentationURL"` | Dataset documentation page |
| `"SourceURL"`, `"SourceRevision"` | Source code location and pinned revision used for the snapshot |
| `"DownloadURLs"` | Data-file links recorded from the source loader |
| `"NativeImportSupported"` | Whether this catalog entry advertises a verified import route |

- Descriptions and links are source declarations. Several records can refer to one study.
- Current Pertpy records have `"NativeImportSupported" -> False` and `"Organism" -> Missing["NotAvailable"]`.
- A catalog record does not establish a verified download or import. Missing catalog metadata do not imply missing study information.

## Basic Examples

Get a catalog record's identifier and title:

```wl
KeyTake[BioDatasetInfo[{"Pertpy", "norman_2019"}], {"Provider", "ID", "Title"}]
```

## Scope

Get reported organism and citation metadata:

```wl
KeyTake[BioDatasetInfo[{"Pertpy", "norman_2019"}], {"ID", "Organism", "Citation"}]
```

## Applications

Compare download links for two file variants:

```wl
Dataset[KeyTake[BioDatasetInfo[{"Pertpy", #}], {"ID", "DownloadURLs"}] & /@ {"norman_2019", "norman_2019_raw"}]
```

---

Record the catalog revision:

```wl
KeyTake[BioDatasetInfo[{"Pertpy", "norman_2019"}], {"Provider", "ID", "SourceRevision", "DocumentationURL"}]
```

## Possible Issues

Unknown identifiers give `Failure["UnknownDataset", ...]`:

```wl
BioDatasetInfo[{"Pertpy", "no-such-biodatalink-dataset"}]
```
