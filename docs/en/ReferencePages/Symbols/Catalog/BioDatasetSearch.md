---
Template: Symbol
Name: BioDatasetSearch
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetSearch
Keywords: [catalog, search, metadata, Pertpy]
SeeAlso: [BioDatasetInfo, BioDatasetLoad, Dataset]
RelatedGuides: [BioDataLink, Catalog]
RelatedTutorials: [ExploringBiologicalData]
---

## Usage

<code>[BioDatasetSearch]()[]</code> gives the bundled biological dataset catalog as a [Dataset]().

<code>[BioDatasetSearch]()[*query*]</code> selects records containing the text *query*.

## Details & Options

- Search uses the bundled catalog and performs no network request.
- The current catalog contains 55 Pertpy loader records, including examples and processed variants. This is not a count of independent studies.
- Text matching is a case-insensitive substring search over dataset identifiers, titles and descriptions.
- Descriptions are taken from the source, not scientifically curated by BioDataLink. Text matches do not establish assay, organism or experimental suitability.
- The provider and organism filters use exact values. `All` disables a filter.
- An empty query matches all records before filters and limits are applied.
- No matches gives an empty `Dataset`.
- A catalog match does not imply that its data file can be loaded. `"NativeImportSupported"` is currently `False` for all Pertpy records.
- Options are listed with defaults in the middle column:

| | | |
| --- | --- | --- |
| `"Limit"` | `All` | Maximum number of returned records; a nonnegative integer or `All` |
| `"Organism"` | `All` | Exact organism string or `All` |
| `"Provider"` | `All` | Exact provider string or `All` |

## Basic Examples

Find catalog records mentioning CRISPR and display two columns at a time.
The returned dataset retains the complete records:

```wl
Dataset[BioDatasetSearch["CRISPR", "Limit" -> 3], MaxItems -> {3, 2}]
```

## Scope

Show provider and identifier columns for two records from the complete catalog:

```wl
BioDatasetSearch[][1 ;; 2, {"Provider", "ID"}]
```

Search by a dataset identifier and show compact catalog columns:

```wl
BioDatasetSearch["norman_2019"][All, {"Provider", "ID"}]
```

## Options

### Limit

Return one record and show its provider and identifier:

```wl
BioDatasetSearch["", "Limit" -> 1][All, {"Provider", "ID"}]
```

### Organism

Request records with an explicit human organism annotation. The current
source has no structured organism annotations, so this returns no records.
This does not imply an absence of human studies:

```wl
BioDatasetSearch["", "Organism" -> "Homo sapiens", "Limit" -> 3]
```

### Provider

Restrict discovery to the Pertpy snapshot and show compact catalog columns:

```wl
BioDatasetSearch["", "Provider" -> "Pertpy", "Limit" -> 3][All, {"Provider", "ID"}]
```

## Possible Issues

A query that matches no catalog text returns an empty result:

```wl
BioDatasetSearch["no-such-biodatalink-dataset"]
```

Provider and organism filters do not infer metadata that the source
omits. A catalog record with a missing organism is excluded by an organism filter.
