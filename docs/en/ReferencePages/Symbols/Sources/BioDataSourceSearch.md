---
Template: Symbol
Name: BioDataSourceSearch
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDataSourceSearch
Keywords: [sources, registry, identifiers, repositories, search]
SeeAlso: [BioDataSourceInfo, BioDataURL, BioDatasetQuery, BioDatasetSearch, Dataset]
RelatedGuides: [BioDataLink, Catalog, Sources]
RelatedTutorials: [FindingDataSources]
---

## Usage

<code>[BioDataSourceSearch]()[]</code> gives active identifier namespaces from the bundled source directory as a [Dataset]().

<code>[BioDataSourceSearch]()[*query*]</code> selects registered prefixes, names and descriptions containing the text *query*.

## Details & Options

- Search runs offline against the bundled Identifiers.org registry. It finds source namespaces, not individual studies or data files.
- Matching is a case-insensitive substring search. An empty query matches all records before filtering and limits.
- The registry contains 867 namespaces, including 93 deprecated namespaces; the default result contains 774 active records.
- Coverage is broad and nonexhaustive. Some namespaces describe data outside biology, and inclusion does not establish open access or implemented query/download support.
- Results preserve the registry's order. A limit selects the first matching records; results are not ranked by relevance.
- No matches gives an empty `Dataset`.
- The bundled registry is loaded and checked on first use, then reused within the Wolfram kernel session.
- Each returned record contains these fields:

| | |
| --- | --- |
| `"Prefix"` | Registered identifier namespace, used by `BioDataSourceInfo` and `BioDataURL` |
| `"Name"`, `"Description"` | Source name and description from the registry |
| `"Deprecated"` | Whether the registry marks the namespace deprecated |
| `"ResourceCount"` | Number of registered access endpoints, including any deprecated endpoints |

- Options are listed with defaults in the middle column:

| | | |
| --- | --- | --- |
| `"IncludeDeprecated"` | `False` | Include deprecated namespaces when `True` |
| `"Limit"` | `All` | Maximum number of returned records; a nonnegative integer or `All` |

## Basic Examples

Find sources mentioning proteins and display two columns at a time.
The returned dataset retains all source fields:

```wl
Dataset[BioDataSourceSearch["protein", "Limit" -> 3], MaxItems -> {3, 2}]
```

## Scope

Find source records mentioning PDB and show their names:

```wl
BioDataSourceSearch["pdb", "Limit" -> 5][All, {"Prefix", "Name"}]
```

## Options

### IncludeDeprecated

Include historical namespaces when examining registry coverage:

```wl
BioDataSourceSearch["", "IncludeDeprecated" -> True, "Limit" -> 3][All,
    {"Prefix", "Deprecated"}]
```

### Limit

Return two source records in compact columns:

```wl
BioDataSourceSearch["", "Limit" -> 2][All, {"Prefix", "Name"}]
```

## Possible Issues

A query with no matching registry text gives an empty result:

```wl
BioDataSourceSearch["no-such-biodatalink-source"]
```

A namespace may have multiple endpoints, and a repository may use multiple
namespaces. Neither record counts nor endpoint counts measure the number of
independent repositories, studies or experiments.
