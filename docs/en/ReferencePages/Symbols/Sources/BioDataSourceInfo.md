---
Template: Symbol
Name: BioDataSourceInfo
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDataSourceInfo
Keywords: [sources, registry, identifiers, provenance, endpoints]
SeeAlso: [Association, BioDataSourceSearch, BioDataURL, BioDatasetQuery]
RelatedGuides: [BioDataLink, Sources]
RelatedTutorials: [FindingDataSources]
---

## Usage

<code>[BioDataSourceInfo]()[*prefix*]</code> gives the source record for a registered identifier namespace.

## Details & Options

- The result is an `Association` from the bundled Identifiers.org registry. No network request is made.
- The prefix lookup is case-insensitive; the returned `"Prefix"` uses the registry's canonical form.
- Deprecated namespaces can be inspected. An unknown prefix gives `Failure["UnknownSource", ...]`.
- Source descriptions, patterns and endpoint metadata are registry declarations, not independent checks of scientific content, current availability or access rights.
- The complete record contains these fields:

| | |
| --- | --- |
| `"Prefix"`, `"Name"`, `"Description"` | Namespace and source description |
| `"Deprecated"`, `"ResourceCount"` | Namespace status and number of registered endpoints |
| `"Pattern"`, `"SampleID"` | Declared identifier pattern and example identifier |
| `"NamespaceEmbeddedInLUI"` | Whether the namespace prefix is embedded in the locally used identifier |
| `"Resources"` | Endpoint records using the registry's original field names |
| `"RegistryRecord"` | Complete namespace record using the registry's original field names |
| `"Provenance"` | Registry retrieval metadata, source hash, license and transformation description |

- Absent JSON values in the registry are returned as `Missing["NotAvailable"]`. Original field names are retained within `"Resources"` and `"RegistryRecord"`.
- `"SampleID"` is preserved as supplied. It may omit a prefix that `BioDataURL` requires for an embedded-prefix namespace; use the identifier's complete original form in that case.
- Endpoint flags can describe deprecated or protected resources. A source's actual terms and authentication requirements must be checked at that source; registry flags are not permission to access data.
- Registry data and prefix indexes are reused within a Wolfram kernel session after their first successful load.

## Basic Examples

Inspect the complete PDB namespace record in a compact `Dataset` view:

```wl
Dataset[BioDataSourceInfo["pdb"], MaxItems -> {8, 2}]
```

## Scope

Inspect the declared Gene Ontology identifier convention:

```wl
KeyTake[BioDataSourceInfo["go"],
    {"Prefix", "Pattern", "SampleID", "NamespaceEmbeddedInLUI"}]
```

Look up the same source using an uppercase prefix:

```wl
KeyTake[BioDataSourceInfo["PDB"], {"Prefix", "Name"}]
```

## Applications

Retain evidence identifying the bundled registry used for a lookup:

```wl
KeyTake[BioDataSourceInfo["pdb"]["Provenance"],
    {"Provider", "SourceURL", "SourceSHA256", "RetrievedAt", "License"}]
```

## Possible Issues

An unknown namespace gives a structured failure:

```wl
BioDataSourceInfo["no-such-biodatalink-source"]
```

The registry's identifier pattern is informative metadata. `BioDataURL` does
not apply that pattern or check whether a particular identifier exists.
