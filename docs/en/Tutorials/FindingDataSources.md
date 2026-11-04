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

Find a source offline, interpret its identifiers, then search public studies
online. Discovery returns metadata and links; downloading a data file is a
separate step.

## Find a source and its identifier format

Find protein-related namespaces:

```wl
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
```

The bundled Identifiers.org snapshot includes 774 active namespaces. A
namespace identifies a naming system, not necessarily a repository or a
supported BioDataLink connection. For a known prefix, look it up directly:

```wl
KeyTake[BioDataSourceInfo["pdb"], {"Prefix", "Name", "Description", "SampleID", "Deprecated"}]
```

Registered endpoints and their flags are available in `Resources`:

```wl
Dataset[BioDataSourceInfo["pdb"]["Resources"]][All, {"name", "providerCode", "official", "deprecated"}]
```

Check the directory's source, retrieval time and checksum:

```wl
KeyTake[BioDataSourceInfo["pdb"]["Provenance"], {"SourceURL", "SourceSHA256", "RetrievedAt", "License"}]
```

This provenance describes the registry snapshot, not a downloaded study file.

## Construct a link

Construct a PDB accession link:

```wl
BioDataURL[{"pdb", "1CRN"}]
```

For identifiers that include a namespace prefix, preserve the complete ID
and capitalization:

```wl
BioDataURL[{"go", "GO:0006915"}]
```

Link construction is offline. It does not check accession existence,
availability or access terms.

## Search studies online

The following inputs need internet access and are not run during documentation
builds. Stop if a query returns `Failure`:

```wl
#| eval: false
page = BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]
```

Inspect the returned records:

```wl
#| eval: false
page["Records"][All, {"ID", "Title", "Organism"}]
```

BioStudies search does not supply a structured organism field, so it remains
`Missing["NotAvailable"]`. Keep the query and retrieval record:

```wl
#| eval: false
KeyTake[page, {"Provider", "Query", "SourceURL", "RetrievedAt", "Total", "TotalIsExact"}]
```

Get the continuation cursor:

```wl
#| eval: false
page["NextCursor"]
```

If `NextCursor` is not `None`, request another page with the same query and size:

```wl
#| eval: false
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3, "Cursor" -> page["NextCursor"]]
```

For GEO Series, use GEO search syntax:

```wl
#| eval: false
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

Stop at `NextCursor -> None`, not at an estimated total. Live results can
change or overlap; counts are not independent experiments. Page size limits
records, not associated file sizes.

## Choose a file for analysis

Check the original study's organism, assay, replicates, processing, citation
and access terms. Then use `BioDatasetDownload` for a chosen HTTPS file and
`BioDatasetLoad` for a supported local JSON or H5AD representation. A discovered
record does not guarantee that its files have a supported reader.
