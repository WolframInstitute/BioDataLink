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

Download a file, check its identity and interpret its columns using the
[UCI Iris dataset](https://archive.ics.uci.edu/dataset/53/iris) (CC BY 4.0).
The file contains 150 plant records, four floral measurements in centimetres
and a species label. It preserves UCI's values, including the documented
differences from Fisher's original article.

## Download and verify

This optional online step requires curl 8.4 or later. It is not run during
documentation builds:

```wl
#| eval: false
download = BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000, "ExpectedByteCount" -> 4551,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]
```

The expected hash pins the checked UCI copy; UCI did not supply that digest.
Investigate a mismatch before changing it. After success, retain the download
record; stop if the call returns `Failure`:

```wl
#| eval: false
KeyTake[download, {"File", "SourceURL", "ResolvedURL", "ByteCount", "ContentHash", "Verification", "RetrievedAt"}]
```

Failed transfers preserve any existing destination. A matching hash verifies
the bytes, not their scientific interpretation or reuse terms.

## Read the bundled copy

The remaining examples run offline on the same bytes, renamed `iris.csv`:

```wl
irisFile = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "iris.csv"}];
provenance = Import[FileNameJoin[{DirectoryName[irisFile], "iris.provenance.json"}], "RawJSON"];
KeyTake[provenance, {"Title", "DOI", "License", "ByteCount", "SHA256"}]
```

Check the bundled file's size and hash:

```wl
<|"BytesMatch" -> (FileByteCount[irisFile] === provenance["ByteCount"]),
    "SHA256Matches" -> (FileHash[irisFile, "SHA256", "HexString"] === provenance["SHA256"])|>
```

To use a successful download instead, set `irisFile` to
`First[download["File"]]`.

## Label and plot the measurements

Remove blank records and name the columns from UCI's definitions.
`SourceRow` retains the nonblank record position; it is not an accession.

```wl
rows = DeleteCases[Import[irisFile, "CSV"], {} | {""}];
iris = With[{columns = {"SepalLengthCm", "SepalWidthCm", "PetalLengthCm", "PetalWidthCm", "Species"}},
    Dataset[MapIndexed[Append[AssociationThread[columns, #1], "SourceRow" -> First[#2]] &, rows]]];
```

Inspect the labeled measurements:

```wl
iris[1 ;; 5, {"SourceRow", "Species", "PetalLengthCm", "PetalWidthCm"}]
```

Count records for each species:

```wl
Counts[Normal[iris[All, "Species"]]]
```

There are 50 records for each species label. These are file counts, not
population frequencies.

Plot petal length against width:

```wl
ListPlot[GroupBy[rows, Last -> (#[[{3, 4}]] &)], AxesLabel -> {"petal length (cm)", "petal width (cm)"}, PlotLegends -> Automatic]
```

Petal measurements differ between the labeled groups. This descriptive plot
does not measure prediction accuracy on new plants. Keep the source version,
units and row selection with further analyses.
