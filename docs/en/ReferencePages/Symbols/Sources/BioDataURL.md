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

<code>[BioDataURL]()[{*prefix*, *id*}]</code> constructs an Identifiers.org resolver URL for an identifier in a registered namespace.

## Details & Options

- The result is a URL string. Constructing it does not contact Identifiers.org or the source repository.
- *prefix* and *id* must be strings. Namespace lookup is case-insensitive; the identifier's case is preserved.
- The identifier must be nonblank, contain at most 4096 characters and contain no ASCII control characters.
- For ordinary namespaces, the URL combines the canonical namespace prefix with the local identifier. Colons and slashes are preserved; other characters that require encoding are percent-encoded.
- When `"NamespaceEmbeddedInLUI"` is `True`, *id* must contain its full original prefix and accession, as in `"GO:0006915"`. The URL uses `https://identifiers.org/namespace/full-identifier`, preserving the selected namespace and the original identifier's case.
- The embedded identifier's prefix need not equal the registered namespace; some sources use an alternative prefix. No prefix is inferred or substituted.
- A bare local identifier for an embedded-prefix namespace gives `Failure["EmbeddedIdentifierRequired", ...]`. Prefix capitalization is not guessed from the registry's identifier pattern.
- Unknown namespaces give `Failure["UnknownSource", ...]`; invalid identifier forms give `Failure["InvalidIdentifier", ...]`.
- Deprecated namespaces remain available for link construction.
- The function does not validate the source's identifier pattern, check record existence or availability, establish a license, or download data. A resolver link is not necessarily a direct data-file URL.

## Basic Examples

Construct a link for a PDB identifier:

```wl
BioDataURL[{"pdb", "1CRN"}]
```

## Scope

Use a Gene Ontology identifier that already includes its namespace:

```wl
BioDataURL[{"go", "GO:0006915"}]
```

Construct a link using the registry's example DOI:

```wl
BioDataURL[{"doi", BioDataSourceInfo["doi"]["SampleID"]}]
```

## Applications

Use a source's supplied sample identifier to construct a link:

```wl
BioDataURL[Lookup[BioDataSourceInfo["pdb"], {"Prefix", "SampleID"}]]
```

This example uses PDB's unprefixed sample identifier. For an embedded-prefix
namespace, supply the complete original identifier instead of assuming that
the registry's `"SampleID"` contains the required prefix.

## Possible Issues

An empty identifier is rejected:

```wl
BioDataURL[{"pdb", ""}]
```

An embedded-prefix namespace requires the full identifier:

```wl
BioDataURL[{"go", "0006915"}]
```

Constructing a URL does not establish that its identifier is valid at the source:

```wl
BioDataURL[{"pdb", "not-a-pdb-accession"}]
```
