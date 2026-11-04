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

Evaluate the Initialization section before the examples.

A biological dataset needs both values and their meaning: which cells and genes
the values describe, how the measurements were transformed, and where the data
came from. The bundled catalog supports offline discovery. A small synthetic
file shows the supported local format without downloading a study's expression
matrix. The synthetic values do not represent an experiment or a biological result.

## Initialization

```wl
exampleFile[] := FileNameJoin[{
    PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}];
```

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
`"NativeImportSupported"` reports whether the paclet can load a linked source
file. It is currently `False` for all Pertpy records.

## Inspect local expression data

Load the synthetic file and inspect the returned matrix, metadata and provenance:

```wl
BioDatasetLoad[File[exampleFile[]]]
```

The bundled synthetic file has three example cells on rows and two example
genes on columns. Its integer values are labeled `"Counts"`. Show the matrix
with a color key for these synthetic values:

```wl
With[{data = BioDatasetLoad[File[exampleFile[]]]},
    MatrixPlot[data["ExpressionMatrix"], PlotLegends -> Automatic,
        FrameLabel -> {"cell", "gene"}]]
```

The displayed zeros are numerical zeros. In this file format, every omitted
matrix entry becomes zero; missing or unmeasured values cannot be represented
separately. In experimental count data, a zero means no count was recorded,
which does not establish that the transcript was biologically absent.

Cell metadata remain in matrix row order:

```wl
BioDatasetLoad[File[exampleFile[]]]["CellMetadata"]
```

Gene metadata remain in matrix column order:

```wl
BioDatasetLoad[File[exampleFile[]]]["GeneMetadata"]
```

Here `"cell-1"` and `"gene-A"` are invented labels. The `"control"` and
`"treated"` annotations are also examples, with no underlying experiment.
For real data, identifiers need a source and gene namespace, and condition
labels need the accompanying experimental design. Unique labels alone do not
establish cell type, gene identity or biological replication.

## Compute a small summary

Sum each gene's synthetic counts across the example cells, using the gene
identifiers as chart labels:

```wl
With[{data = BioDatasetLoad[File[exampleFile[]]]},
    BarChart[Normal[Total[data["ExpressionMatrix"]]],
        ChartLabels -> Normal[data["GeneMetadata"][All, "ID"]],
        AxesLabel -> {None, "synthetic counts"}]]
```

The column totals are 5 and 6. They demonstrate arithmetic on the imported
matrix; their difference has no biological interpretation. For experimental
data, first establish whether counts represent reads or molecules, which
processing was applied and what the biological sampling units are. Summing
counts alone does not measure differential expression or a treatment effect.

## Keep source evidence

Inspect the declared source and the hash of the file that was read:

```wl
KeyTake[BioDatasetLoad[File[exampleFile[]]], {"ContentHash", "Normalization", "Provenance"}]
```

The provenance records the source information declared by the file's author.
The reader requires this information but does not establish that it is correct.
Likewise, `"Normalization"` records a declared measurement scale; it does not
perform or verify a normalization procedure. The content hash identifies the
exact bytes read, not agreement with an independently supplied source checksum
or the validity of a biological claim.
