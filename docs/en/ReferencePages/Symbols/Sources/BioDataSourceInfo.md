---
Template: Symbol
Name: BioDataSourceInfo
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDataSourceInfo
Keywords: [sources, registry, identifiers, provenance, endpoints]
SeeAlso: [BioDataSourceSearch, BioDataURL, BioDatasetQuery, Association]
RelatedGuides: [BioDataLink, Sources]
RelatedTutorials: [FindingDataSources]
---

## Usage

<code>[BioDataSourceInfo]()[*prefix*]</code> gives metadata for a registered identifier namespace.

## Details

- The result is an `Association` from the bundled Identifiers.org registry. No network request is made.
- *prefix* is a string. Lookup is case-insensitive and returns the canonical prefix.
- Deprecated namespaces remain available.
- Returned properties include:

| | |
| --- | --- |
| `"Prefix"`, `"Name"`, `"Description"` | Namespace and source description |
| `"Deprecated"`, `"ResourceCount"` | Namespace status and number of registered endpoints |
| `"Pattern"`, `"SampleID"` | Declared identifier pattern and example identifier |
| `"NamespaceEmbeddedInLUI"` | Whether the namespace prefix is embedded in the locally used identifier |
| `"Resources"` | Endpoint records using the registry's original field names |
| `"RegistryRecord"` | Complete namespace record using the registry's original field names |
| `"Provenance"` | Registry retrieval metadata, source hash, license and transformation description |

- Missing values are represented by `Missing["NotAvailable"]`. Nested registry fields retain their source names.
- Patterns, descriptions and access flags are registry declarations; they do not verify current availability or access terms.
- `"SampleID"` can omit a prefix required by `BioDataURL`. Embedded-prefix namespaces require the complete original identifier.

## Basic Examples

Get the name and sample identifier for PDB:

```wl
KeyTake[BioDataSourceInfo["pdb"], {"Prefix", "Name", "SampleID"}]
```

## Scope

Inspect identifier conventions for Gene Ontology:

```wl
KeyTake[BioDataSourceInfo["go"], {"Prefix", "Pattern", "SampleID", "NamespaceEmbeddedInLUI"}]
```

---

Namespace lookup ignores case:

```wl
KeyTake[BioDataSourceInfo["PDB"], {"Prefix", "Name"}]
```

## Applications

List registered endpoints:

```wl
Dataset[BioDataSourceInfo["pdb"]["Resources"]][All, {"name", "providerCode", "official", "deprecated"}]
```

---

Get the registry snapshot's provenance:

```wl
KeyTake[BioDataSourceInfo["pdb"]["Provenance"], {"Provider", "SourceURL", "SourceSHA256", "RetrievedAt", "License"}]
```

## Possible Issues

Unknown prefixes give `Failure["UnknownSource", ...]`:

```wl
BioDataSourceInfo["no-such-biodatalink-source"]
```
