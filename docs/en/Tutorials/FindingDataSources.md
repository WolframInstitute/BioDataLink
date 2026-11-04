---
Template: TechNote
Name: FindingDataSources
Title: Finding Biological Data Sources
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/FindingDataSources
Keywords: [application, sources, repositories, identifiers, study discovery]
RelatedGuides: [BioDataLink, Catalog, Providers, Sources]
---

Finding a suitable dataset begins with its source and identifiers. A repository
can contain many studies and data types, and one study can appear in several
repositories. This tutorial first explores a bundled source directory without
network access, then shows an optional online search for public study records.
Finding a record or making a link does not download experimental data.

## Find a source

Search the registered source descriptions for proteins and show compact columns:

```wl
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
```

The directory comes from Identifiers.org. Its 867 namespaces span biological
and other domains; 774 are active in this bundled version. A namespace groups
identifiers from a named system, such as PDB structure identifiers. It is not
necessarily a distinct repository, and the directory is not an exhaustive list
of biological data sources. Descriptions are taken from the registry.

Text search can match a description even when the namespace prefix is
different. Use `BioDataSourceInfo["pdb"]` when the intended prefix is already
known. A directory entry does not automatically make that source a supported
provider for online `BioDatasetQuery` calls.

## Inspect identifier conventions

Examine the source description and example identifier for the PDB namespace:

```wl
KeyTake[BioDataSourceInfo["pdb"], {"Prefix", "Name", "Description", "SampleID", "Deprecated"}]
```

The registry can list several access endpoints for one namespace. Its original
endpoint records and complete namespace record remain available through
`"Resources"` and `"RegistryRecord"`. These describe registered services;
they do not verify current availability, open-access status or a supported
BioDataLink data reader.

Inspect PDB's registered endpoints in a compact table:

```wl
Dataset[BioDataSourceInfo["pdb"]["Resources"]][All, {"name", "providerCode", "official", "deprecated"}]
```

These flags are the registry's metadata. Two endpoints may serve the same
underlying records, so they are not independent sources of biological evidence.

Inspect the registry version evidence used by this lookup:

```wl
KeyTake[BioDataSourceInfo["pdb"]["Provenance"], {"SourceURL", "SourceSHA256", "RetrievedAt", "License"}]
```

`"RetrievedAt"` records when this copy of the registry was collected.
`"SourceSHA256"` identifies the collected source bytes. These fields concern
the directory itself, not a subsequently downloaded structure or study file.

## Make a source link

Construct a resolver link for a PDB accession:

```wl
BioDataURL[{"pdb", "1CRN"}]
```

The function returns a string without opening the link. Following an
Identifiers.org link directs the user toward a source record. BioDataLink has
not checked that the record exists, that the source is reachable, or that a
particular file is available for reuse.

Some identifier systems conventionally include their namespace in the local
identifier. For those systems, supply the complete identifier with its original
capitalization. The function preserves it without repeating the prefix:

```wl
BioDataURL[{"go", "GO:0006915"}]
```

## Search public study records online

`BioDatasetQuery` contacts a supported source to search its public metadata.
The following input makes a network request when evaluated by the reader. It
is not evaluated while building this documentation, and no saved search result
is implied:

```wl
#| eval: false
page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]
```

The result contains a `"Records"` dataset, the source's reported `"Total"`,
`"TotalIsExact"`, a `"NextCursor"`, the provider, query and retrieval time.
Study descriptions remain source declarations. Search results can overlap
across providers and do not count independent experiments or biological
replicates. A textual match alone does not establish that an assay, organism
or experimental design suits the research question.

After a successful query, inspect the accessions, titles and organism
annotations. Stop if the query returned a `Failure`:

```wl
#| eval: false
page["Records"][All, {"ID", "Title", "Organism"}]
```

The BioStudies search response used here does not supply structured organism
annotations, so that field remains `Missing["NotAvailable"]`. It is not filled
from a title that happens to mention a species. Study metadata with different
levels of detail should not be treated as equivalent evidence.

Keep the original query, source endpoint and retrieval time with the selection:

```wl
#| eval: false
KeyTake[page, {"Provider", "Query", "SourceURL", "RetrievedAt", "Total", "TotalIsExact"}]
```

Check whether a continuation is available:

```wl
#| eval: false
page["NextCursor"]
```

If that value is not `None`, request the next page with the same search:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3, "Cursor" -> page["NextCursor"]]
```

A `None` cursor means the search has no next page. A `Failure` from the query
is distinct from that successful end condition. Live records and estimated totals can
change between requests. Retain the returned accessions when documenting a
selection used for analysis.

An online GEO query returns Series records. Its provider-specific syntax can
restrict the search before results are returned:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

Use the returned cursor to request another page with the same provider, query
and page size. Stop when `"NextCursor"` is `None`; an estimated total is not a
reliable stopping condition. The page size limits returned records, not the
size of associated scientific data files. These searches do not retrieve those
files or grant access to restricted data.

## Choose data for analysis

Inspect the original study record for its sampling design, assay, organism,
processing history, citation and access terms before selecting a file. Missing
metadata remains unknown. The Pertpy catalog provides a separate offline list
of loader records through `BioDatasetSearch`. Download an explicitly selected
HTTPS data file with `BioDatasetDownload`, retaining its retrieval record.
`BioDatasetLoad` reads local BioDataLink JSON expression matrices or selected
supported H5AD measurements with an explicit optional interpreter. These
capabilities do not imply support for every file listed by a discovered source.
