---
Template: TechNote
Name: DownloadingBiologicalData
Title: Downloading and Inspecting Biological Data
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/DownloadingBiologicalData
Keywords: [application, download, checksum, CSV, iris, provenance]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
---

A verified transfer answers which bytes were retrieved. Scientific analysis
also requires the source's definitions of rows, variables, units and labels.
This tutorial uses UCI's small Iris file to connect those steps. The optional
download inputs are online and unevaluated during documentation generation;
the table and plot use an attributed bundled copy with the same checked bytes.

The [UCI dataset description](https://archive.ics.uci.edu/dataset/53/iris)
identifies plant records with four floral measurements in centimetres and a
species label. UCI also documents differences from Fisher's historical article.
The example retains UCI's distributed values without applying corrections; it
is not a reproduction of every measurement in that article.

## Retrieve a specific file

Download into a newly created directory, supplying a byte limit and the size
and SHA-256 recorded for the example file. This requires curl 8.4 or later and
an internet connection:

```wl
#| eval: false
download = BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000, "ExpectedByteCount" -> 4551,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]
```

The expected hash was computed from the checked UCI file used here, rather
than supplied by the publisher. It pins this particular content. A mismatch
requires checking the source version and expectations before replacing them.

After a successful download, inspect the retrieval evidence. Stop if the
operation returned a `Failure`:

```wl
#| eval: false
KeyTake[download, {"File", "SourceURL", "ResolvedURL", "ByteCount", "ContentHash", "Verification", "RetrievedAt"}]
```

The function leaves a failed transfer out of the destination and preserves any
old file. A successful checksum comparison confirms agreement with the supplied
digest; it does not establish a biological conclusion or permission to reuse
the data.

## Inspect the bundled copy offline

Locate the bundled Iris file and read its source record:

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
provenance = Import[FileNameJoin[{DirectoryName[irisFile], "iris.provenance.json"}], "RawJSON"];
KeyTake[provenance, {"Title", "DOI", "License", "ByteCount", "SHA256"}]
```

The dataset is provided under CC BY 4.0. Its attribution and source information
remain alongside the data, independently of the paclet's software license.
The bundled file was renamed from `iris.data` to `iris.csv` without altering
its contents.

For a successful online download, `First[download["File"]]` gives the local
path to use in the same inspection steps instead of the bundled copy.

Compare the local file with the recorded expected content:

```wl
<|"BytesMatch" -> (FileByteCount[irisFile] === provenance["ByteCount"]),
    "SHA256Matches" -> (FileHash[irisFile, "SHA256", "HexString"] === provenance["SHA256"])|>
```

## Assign variables and retain row positions

Read the CSV, removing only completely blank records, and assign column names
using UCI's variable definitions. Retain the original nonblank record position
as `"SourceRow"`:

```wl
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
iris = With[{columns = {"SepalLengthCm", "SepalWidthCm", "PetalLengthCm", "PetalWidthCm", "Species"}},
    Dataset[MapIndexed[Append[AssociationThread[columns, #1], "SourceRow" -> First[#2]] &, rows]]];
```

Show the first five records:

```wl
iris[1 ;; 5, {"SourceRow", "Species", "PetalLengthCm", "PetalWidthCm"}]
```

These labels are an interpretation documented by the source, not information
that a generic CSV reader inferred. `"SourceRow"` is a local record position,
not a biological accession or an assertion of independent sampling.

Count the source species labels in this file:

```wl
Counts[Normal[iris[All, "Species"]]]
```

The file contains 150 plant records, with 50 records for each of its three
species labels. These are counts of the supplied records, not population
frequencies or evidence of a sampling design beyond the source documentation.

## Plot measurements with their units

Plot petal length against petal width, keeping species labels distinct:

```wl
ListPlot[GroupBy[rows, Last -> (#[[{3, 4}]] &)], AxesLabel -> {"petal length (cm)", "petal width (cm)"}, PlotLegends -> Automatic]
```

The plot describes measurements in this specific file. It does not establish
classification accuracy on new plants or explain the causes of differences
between species. Keep the source version, variable definitions and selection
with any analysis built from these values.
