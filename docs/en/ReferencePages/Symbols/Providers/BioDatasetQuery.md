---
Template: Symbol
Name: BioDatasetQuery
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetQuery
Keywords: [online, study metadata, BioStudies, GEO, pagination]
SeeAlso: [BioDataSourceInfo, BioDataSourceSearch, BioDataURL, BioDatasetInfo, BioDatasetSearch, Dataset]
RelatedGuides: [BioDataLink, Catalog, Providers, Sources]
RelatedTutorials: [FindingDataSources]
---

## Usage

<code>[BioDatasetQuery]()[*provider*, *query*]</code> gives one page of public study metadata from an online provider.

## Details & Options

- Supported provider names are the case-sensitive strings `"BioStudies"` and `"GEO"`. This operation makes network requests; `BioDatasetSearch` instead searches the bundled Pertpy catalog offline.
- Both arguments are strings. Queries may contain at most 4096 characters, and an empty query is allowed.
- Queries use the selected source's search syntax. GEO queries are restricted to Series records, with the user query grouped before adding the Series restriction.
- Results contain source descriptions, not downloaded expression matrices or other scientific data files. They do not establish that a file can be loaded by this paclet.
- The returned `Association` contains these fields:

| | |
| --- | --- |
| `"Records"` | `Dataset` of study records for the requested page |
| `"Total"` | Number of matches reported by the source |
| `"TotalIsExact"` | Whether the source reports that count as exact |
| `"NextCursor"` | Opaque continuation string, or `None` when no next page is available |
| `"Provider"`, `"Query"` | Provider and original query |
| `"RetrievedAt"` | Retrieval time in UTC |
| `"SourceURL"` | Official search API endpoint, without query parameters or credentials |

- Each record has these properties:

| | |
| --- | --- |
| `"Provider"`, `"ID"` | Source name and study accession; a GSE accession for GEO |
| `"Title"`, `"Description"` | Study description reported by the source |
| `"Organism"` | Source organism text or list of organism strings when available |
| `"Citation"` | `Missing["NotAvailable"]` for the current providers; original citation-related fields remain in `"ProviderMetadata"` |
| `"SourceURL"` | Official landing page for the study record |
| `"NativeImportSupported"` | `False`: live discovery does not establish data-file import support |
| `"ProviderMetadata"` | Complete source search hit or summary with its original field names |

- Missing values become `Missing["NotAvailable"]`. Organisms are not inferred from BioStudies descriptions; GEO organism text is preserved as supplied. Citations are not constructed from incomplete metadata.
- Records can overlap across pages or sources. Search totals do not measure independent experiments, samples or biological replicates.
- BioStudies can report an estimated total. Follow `"NextCursor"` until it is `None`, rather than using the total to decide when to stop.
- GEO totals reflect the index at request time; results can shift between pages as the index changes. A paginated query is not a fixed release of the source database.
- Cursor strings must be returned unchanged with the same provider and query. They are not accessions accepted by `BioDatasetInfo`.
- Requests are paginated. GEO summaries are retrieved in a batch for each page. Page size limits records, not bytes or the size of associated scientific files.
- A timeout, invalid response or unavailable provider gives a `Failure`, not a successful empty search. Transient errors are not retried automatically.
- The following options can be given:

| | | |
| --- | --- | --- |
| `"APIKey"` | `None` | GEO only: a credential reference `{"Environment", name}` or `{"SystemCredential", name}` |
| `"Cursor"` | `Automatic` | Start a search, or continue using a returned cursor string |
| `"PageSize"` | `20` | Maximum records per page; an integer from 1 to 100 |
| `"TimeConstraint"` | `30` | Total operation time in seconds, including request pacing; finite and positive, at most 300 |

- `"APIKey"` references are resolved when a call runs. Literal secret strings are not accepted. A GEO API key affects the permitted request rate for public data; it does not provide private-study access.

## Basic Examples

Search public BioStudies records online. This input is not evaluated during
documentation generation. Stop if an online call returns a `Failure` before
using its result in a later input:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]
```

## Scope

Search GEO Series using the source's organism field syntax. This is an online operation:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

## Options

### APIKey

Use a GEO API key already stored in an environment variable. Only its name
appears in this online input:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR", "APIKey" -> {"Environment", "NCBI_API_KEY"}]
```

### Cursor

Request a second page only if the source provides a continuation cursor.
This input makes up to two online queries:

```wl
#| eval: false
With[{page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]},
    Which[FailureQ[page], page, page["NextCursor"] === None, None,
        True, BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3, "Cursor" -> page["NextCursor"]]]]
```

A `Failure` is returned unchanged. A `"NextCursor"` value of `None` means pagination has ended. Do not pass it
as a new cursor or use a changing total to infer how many pages remain.

### PageSize

Request at most five records in one online page:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 5]
```

### TimeConstraint

Allow up to 10 seconds for the online operation, including request pacing:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "TimeConstraint" -> 10]
```

## Applications

Review accession, title and organism together after one bounded online query:

```wl
#| eval: false
With[{page = BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 5]},
    If[FailureQ[page], page, page["Records"][All, {"ID", "Title", "Organism"}]]]
```

The organism annotation is supplied by GEO. It can be a string or a list of
strings. Inspect the original record and sampling design before deciding that
the returned studies are comparable.

Retain the provider, query, endpoint and retrieval time of an online search:

```wl
#| eval: false
With[{page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]},
    If[FailureQ[page], page, KeyTake[page, {"Provider", "Query", "SourceURL", "RetrievedAt"}]]]
```

This records a particular search, not a frozen release of the provider's
database. Preserve returned accessions separately if the selection is used in
an analysis.

## Possible Issues

An invalid page size is rejected before a network request:

```wl
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 0]
```

A string that is not a returned cursor is rejected before a network request:

```wl
BioDatasetQuery["GEO", "CRISPR", "Cursor" -> "not-a-returned-cursor"]
```

Provider-specific accessions from live results are not entries in the bundled
Pertpy catalog. Use the returned study landing page and source metadata to
inspect them. `BioDatasetInfo` only accepts identifiers in its bundled catalog.

Credential references support public GEO requests here. Access to private or
controlled research data requires a separately implemented source connection
and authorization; it is not supplied by this function.
