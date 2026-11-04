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

<code>[BioDatasetQuery]()[*provider*, *query*]</code> gives one page of public study metadata matching *query*.

## Details & Options

- *provider* is `"BioStudies"` or `"GEO"`. Provider names are case-sensitive.
- *query* is a string of at most 4096 characters, using the source's search syntax. Empty queries are allowed.
- GEO searches return Series records. BioStudies searches return study records.
- Each call uses the internet and returns an `Association` with the following properties:

| | |
| --- | --- |
| `"Records"` | `Dataset` of study records for the requested page |
| `"Total"` | Number of matches reported by the source |
| `"TotalIsExact"` | Whether the source reports that count as exact |
| `"NextCursor"` | Opaque continuation string, or `None` when no next page is available |
| `"Provider"`, `"Query"` | Provider and original query |
| `"RetrievedAt"` | Retrieval time in UTC |
| `"SourceURL"` | Official search API endpoint, without query parameters or credentials |

- Each record in `"Records"` contains:

| | |
| --- | --- |
| `"Provider"`, `"ID"` | Source name and study accession; a GSE accession for GEO |
| `"Title"`, `"Description"` | Study description reported by the source |
| `"Organism"` | Source organism text or list of organism strings when available |
| `"Citation"` | `Missing["NotAvailable"]` for the current providers; original citation-related fields remain in `"ProviderMetadata"` |
| `"SourceURL"` | Official landing page for the study record |
| `"NativeImportSupported"` | `False`: live discovery does not establish data-file import support |
| `"ProviderMetadata"` | Complete source search hit or summary with its original field names |

- Missing annotations remain `Missing["NotAvailable"]`. BioStudies organisms and provider citations are not inferred from text.
- GEO organism strings or lists are preserved. Original search fields remain in `"ProviderMetadata"`.
- A cursor must be used unchanged with the same provider and query. `None` indicates the last page.
- BioStudies totals may be estimates. Live results can change or overlap between pages.
- Results describe studies; they do not download data or establish supported imports. Record counts do not count independent experiments.
- Provider errors and timeouts give `Failure`. Requests are not retried automatically.
- The following options can be given:

| | | |
| --- | --- | --- |
| `"APIKey"` | `None` | GEO only: a credential reference `{"Environment", name}` or `{"SystemCredential", name}` |
| `"Cursor"` | `Automatic` | Start a search, or continue using a returned cursor string |
| `"PageSize"` | `20` | Maximum records per page; an integer from 1 to 100 |
| `"TimeConstraint"` | `30` | Total operation time in seconds, including request pacing; finite and positive, at most 300 |

- GEO API keys affect public request quotas, not private-data access. Credential references are resolved at call time; literal secrets are rejected.
- Online examples require internet access and have no saved results.

## Basic Examples

Search BioStudies:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]
```

## Scope

Search GEO Series for an organism:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

## Options

### APIKey

Use a key stored in an environment variable:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR", "APIKey" -> {"Environment", "NCBI_API_KEY"}]
```

### Cursor

Request the next page when a cursor is available:

```wl
#| eval: false
With[{page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]},
    Which[FailureQ[page], page, page["NextCursor"] === None, None,
        True, BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3, "Cursor" -> page["NextCursor"]]]]
```

### PageSize

Return at most five study records:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 5]
```

### TimeConstraint

Allow ten seconds, including request pacing:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "TimeConstraint" -> 10]
```

## Applications

Extract accessions, titles and organisms:

```wl
#| eval: false
With[{page = BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 5]},
    If[FailureQ[page], page, page["Records"][All, {"ID", "Title", "Organism"}]]]
```

---

Retain the search provenance:

```wl
#| eval: false
With[{page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]},
    If[FailureQ[page], page, KeyTake[page, {"Provider", "Query", "SourceURL", "RetrievedAt"}]]]
```

This records a live query, not a frozen database release.

## Possible Issues

An invalid page size fails before a request:

```wl
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 0]
```

---

An invalid cursor fails before a request:

```wl
BioDatasetQuery["GEO", "CRISPR", "Cursor" -> "not-a-returned-cursor"]
```

Live accessions are not Pertpy catalog IDs accepted by `BioDatasetInfo`.
Use each record's `"SourceURL"` to reach the original study.
