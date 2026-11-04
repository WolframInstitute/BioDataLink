---
Template: Symbol
Name: BioDataURL
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDataURL
Keywords: [identifiers, accession, URL, resolver, sources]
SeeAlso: [BioDataSourceInfo, BioDataSourceSearch, BioDatasetQuery]
RelatedGuides: [BioDataLink, Sources]
RelatedTutorials: [FindingDataSources]
---

## Usage

<code>[BioDataURL]()[{*prefix*, *id*}]</code> constructs an Identifiers.org resolver URL.

## Details

- The result is a string. No network request is made.
- *prefix* and *id* are strings. Namespace lookup is case-insensitive; identifier case is preserved.
- Identifiers must be nonblank, at most 4096 characters and contain no ASCII control characters.
- Colons and slashes remain literal. Other reserved characters are percent-encoded.
- If `"NamespaceEmbeddedInLUI"` is `True`, *id* must include its original prefix, as in `"GO:0006915"`. The URL has the form `https://identifiers.org/namespace/full-identifier`.
- An embedded prefix can differ from the registry namespace. Prefixes are not inferred or replaced.
- Deprecated namespaces remain available. Unknown namespaces give `Failure["UnknownSource", ...]`.
- Resolver links do not verify source identifier patterns, record existence, availability or reuse terms. They need not point directly to data files.

## Basic Examples

Construct a link to a PDB record:

```wl
BioDataURL[{"pdb", "1CRN"}]
```

## Scope

Use a complete Gene Ontology identifier:

```wl
BioDataURL[{"go", "GO:0006915"}]
```

---

Use the registry's example DOI:

```wl
BioDataURL[{"doi", BioDataSourceInfo["doi"]["SampleID"]}]
```

## Applications

Construct a link from source metadata:

```wl
BioDataURL[Lookup[BioDataSourceInfo["pdb"], {"Prefix", "SampleID"}]]
```

For an embedded-prefix namespace, `"SampleID"` must include the complete prefix.

## Possible Issues

An empty identifier gives `Failure["InvalidIdentifier", ...]`:

```wl
BioDataURL[{"pdb", ""}]
```

---

A missing required prefix gives `Failure["EmbeddedIdentifierRequired", ...]`:

```wl
BioDataURL[{"go", "0006915"}]
```

---

An invalid source accession can still produce a URL:

```wl
BioDataURL[{"pdb", "not-a-pdb-accession"}]
```
