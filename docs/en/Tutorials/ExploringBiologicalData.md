---
Template: TechNote
Name: ExploringBiologicalData
Title: Exploring Biological Data
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ExploringBiologicalData
Keywords: [application, biology, catalog, expression, provenance, synthetic data]
RelatedGuides: [BioDataLink, Catalog, DataAccess]
---

A biological dataset needs both values and their meaning: which cells and genes
the values describe, how the measurements were transformed, and where the data
came from. The bundled catalog supports offline discovery. A small synthetic
file shows the supported local format without downloading a study's expression
matrix. The synthetic values do not represent an experiment or a biological result.

## Find a data source

Search descriptions and identifiers for CRISPR, showing compact provider and
identifier columns:

```wl
BioDatasetSearch["CRISPR", "Limit" -> 3][All, {"Provider", "ID"}]
```

Inspect source and access information for one Pertpy loader:

```wl
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

The record identifies the revision of Pertpy used to build this catalog. Its
description is taken from that source, not independently reviewed scientific
annotation. A loader name such as `"norman_2019"` is not a repository accession;
one study may have several files or processed versions in the catalog.
`"NativeImportSupported"` reports whether the catalog advertises a verified
import route for that entry. It is currently `False` for all Pertpy records;
general H5AD reader support does not independently validate those files.

## Inspect local expression data

Load the synthetic file and inspect the returned matrix, metadata and provenance:

```wl
data = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]
```

The bundled synthetic file has three example cells on rows and two example
genes on columns. Its integer values are labeled `"Counts"`. Show the matrix
with a color key for these synthetic values:

```wl
MatrixPlot[data["ExpressionMatrix"], PlotLegends -> Automatic, FrameLabel -> {"cell", "gene"}]
```

The displayed zeros are numerical zeros. In this file format, every omitted
matrix entry becomes zero; missing or unmeasured values cannot be represented
separately. In experimental count data, a zero means no count was recorded,
which does not establish that the transcript was biologically absent.

Cell metadata remain in matrix row order:

```wl
data["CellMetadata"]
```

Gene metadata remain in matrix column order:

```wl
data["GeneMetadata"]
```

Here `"cell-1"` and `"gene-A"` are invented labels. The `"control"` and
`"treated"` annotations are also examples, with no underlying experiment.
For real data, identifiers need a source and gene namespace, and condition
labels need the accompanying experimental design. Unique labels alone do not
establish cell type, gene identity or biological replication.

## Select cells and genes by their labels

Select the rows labeled `"treated"` and find the column named `"gene-A"`:

```wl
cells = Normal[data["CellMetadata"]];
genes = Normal[data["GeneMetadata"]];
rows = Flatten[Position[Lookup[cells, "Condition"], "treated"]];
column = First[FirstPosition[Lookup[genes, "ID"], "gene-A"]];
```

Associate each selected cell identifier with its value:

```wl
AssociationThread[Lookup[cells[[rows]], "ID"], Normal[data["ExpressionMatrix"][[rows, column]]]]
```

The result retains the row identifiers beside values 0 and 2. The positions
come from the metadata rather than an assumed row or column order. A real
workflow should also check that its requested identifiers and annotations
exist. This example selects from a small, known synthetic file.

Keep the source-file hash and the selected identifiers together:

```wl
<|"SourceContentHash" -> data["ContentHash"],
    "CellIDs" -> Lookup[cells[[rows]], "ID"],
    "GeneIDs" -> {genes[[column]]["ID"]},
    "Normalization" -> data["Normalization"]|>
```

The source hash identifies the original file; it is not a separately computed
hash of the selected matrix. Recording the selected identifiers makes this
particular selection explicit.

## Summarize recorded values

Associate each example cell with its total recorded counts:

```wl
AssociationThread[Lookup[cells, "ID"], Normal[Total[data["ExpressionMatrix"], {2}]]]
```

Count genes with nonzero values in each cell:

```wl
AssociationThread[Lookup[cells, "ID"], Normal[Total[Unitize[data["ExpressionMatrix"]], {2}]]]
```

The totals are 3, 5 and 3, and the nonzero-gene counts are 1, 1 and 2.
Such summaries can help inspect a file before analysis, but these invented
values do not establish quality thresholds or cell states. In experimental
data, recorded counts depend on the assay, sampling and processing; they are
not a direct measure of total cellular RNA abundance.

Sum each gene's synthetic counts across the example cells, using the gene
identifiers as chart labels:

```wl
BarChart[Normal[Total[data["ExpressionMatrix"]]],
    ChartLabels -> Normal[data["GeneMetadata"][All, "ID"]],
    AxesLabel -> {None, "synthetic counts"}]
```

The column totals are 5 and 6. They demonstrate arithmetic on the imported
matrix; their difference has no biological interpretation. For experimental
data, first establish whether counts represent reads or molecules, which
processing was applied and what the biological sampling units are. Summing
counts alone does not measure differential expression or a treatment effect.

## Keep source evidence

Inspect the declared source and the hash of the file that was read:

```wl
KeyTake[data, {"ContentHash", "Normalization", "Provenance"}]
```

The provenance records the source information declared by the file's author.
The reader requires this information but does not establish that it is correct.
Likewise, `"Normalization"` records a declared measurement scale; it does not
perform or verify a normalization procedure. The content hash identifies the
exact bytes read, not agreement with an independently supplied source checksum
or the validity of a biological claim.
