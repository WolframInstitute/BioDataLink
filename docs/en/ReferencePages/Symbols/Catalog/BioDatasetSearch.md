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

<code>[BioDatasetSearch]()[]</code> gives the bundled dataset catalog as a [Dataset]().

<code>[BioDatasetSearch]()[*query*]</code> finds catalog records containing *query*.

## Details & Options

- The catalog contains 55 Pertpy loader records and is searched offline.
- *query* is a string. Matching is case-insensitive across identifiers, titles and descriptions.
- An empty query matches all records before filters and limits are applied.
- Provider and organism filters use exact matches. `All` disables a filter; missing annotations do not match a string.
- No matches gives an empty `Dataset`.
- Records include processed variants and examples, not just independent studies. All current records have `"NativeImportSupported" -> False`.
- The following options can be given:

| | | |
| --- | --- | --- |
| `"Limit"` | `All` | Maximum number of returned records; a nonnegative integer or `All` |
| `"Organism"` | `All` | Exact organism string or `All` |
| `"Provider"` | `All` | Exact provider string or `All` |

## Basic Examples

Find catalog records mentioning CRISPR:

```wl
BioDatasetSearch["CRISPR", "Limit" -> 3][All, {"Provider", "ID"}]
```

## Scope

Show identifiers from the catalog:

```wl
BioDatasetSearch[][1 ;; 2, {"Provider", "ID"}]
```

---

Search by identifier:

```wl
BioDatasetSearch["norman_2019"][All, {"Provider", "ID"}]
```

## Options

### Limit

Return at most one record:

```wl
BioDatasetSearch["", "Limit" -> 1][All, {"Provider", "ID"}]
```

### Organism

The current catalog has no structured organism annotations, so filtering gives an empty result:

```wl
BioDatasetSearch["", "Organism" -> "Homo sapiens"]
```

### Provider

Select one provider:

```wl
BioDatasetSearch["", "Provider" -> "Pertpy"][All, {"Provider", "ID"}]
```

## Applications

Compare available metadata for file variants:

```wl
BioDatasetSearch["norman_2019"][All, {"ID", "Organism", "NativeImportSupported"}]
```

Processing and measurement scale must be checked at the source.

## Possible Issues

A query with no matches gives an empty dataset:

```wl
BioDatasetSearch["no-such-biodatalink-dataset"]
```
