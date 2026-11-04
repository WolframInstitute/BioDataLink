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

<code>[BioDataSourceSearch]()[]</code> gives the active source namespaces as a [Dataset]().

<code>[BioDataSourceSearch]()[*query*]</code> finds registered prefixes, names and descriptions containing *query*.

## Details & Options

- The bundled Identifiers.org directory is searched without a network request.
- *query* is a string. Matching is case-insensitive; an empty query matches all records before filters and limits.
- The snapshot contains 867 namespaces, of which 774 are active. Deprecated namespaces are excluded by default.
- Results retain registry order. No matches gives an empty `Dataset`.
- Each record contains:

| | |
| --- | --- |
| `"Prefix"` | Registered identifier namespace, used by `BioDataSourceInfo` and `BioDataURL` |
| `"Name"`, `"Description"` | Source name and description from the registry |
| `"Deprecated"` | Whether the registry marks the namespace deprecated |
| `"ResourceCount"` | Number of registered access endpoints, including any deprecated endpoints |

- A namespace describes an identifier system, not an individual study. Namespaces and endpoints do not count independent repositories or experiments.
- Registry inclusion does not establish access or an implemented data connection.
- The following options can be given:

| | | |
| --- | --- | --- |
| `"IncludeDeprecated"` | `False` | Include deprecated namespaces when `True` |
| `"Limit"` | `All` | Maximum number of returned records; a nonnegative integer or `All` |

## Basic Examples

Find sources mentioning proteins:

```wl
BioDataSourceSearch["protein", "Limit" -> 3][All, {"Prefix", "Name"}]
```

## Scope

Find PDB-related namespaces:

```wl
BioDataSourceSearch["pdb"][All, {"Prefix", "Name"}]
```

## Options

### IncludeDeprecated

Include and select deprecated namespaces:

```wl
BioDataSourceSearch["", "IncludeDeprecated" -> True][Select[#Deprecated &], {"Prefix", "Name"}]
```

### Limit

Return at most two records:

```wl
BioDataSourceSearch["", "Limit" -> 2][All, {"Prefix", "Name"}]
```

## Applications

Find protein namespaces with multiple endpoints:

```wl
BioDataSourceSearch["protein"][Select[#ResourceCount > 1 &], {"Prefix", "Name", "ResourceCount"}]
```

## Possible Issues

A query with no matches gives an empty dataset:

```wl
BioDataSourceSearch["no-such-biodatalink-source"]
```
