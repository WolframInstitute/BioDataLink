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

Find a catalog record, load a local expression matrix and select values by
their identifiers. This introductory example uses a **synthetic** file with
three cells and two genes; it demonstrates data handling, not an experiment.

## Inspect a catalog record

Find catalog records:

```wl
BioDatasetSearch["CRISPR", "Limit" -> 3][All, {"Provider", "ID"}]
```

Inspect one record:

```wl
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

`norman_2019` is a Pertpy loader name, not a repository accession. The record
retains Pertpy's description and source revision. `NativeImportSupported` is
`False`: catalog inclusion does not verify an import of the linked files.

## Load values and labels

Read the synthetic expression file:

```wl
data = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]
```

Plot the expression matrix:

```wl
MatrixPlot[data["ExpressionMatrix"], PlotLegends -> Automatic, FrameLabel -> {"cell", "gene"}]
```

Rows are cells and columns are genes. `Counts` is the file's declared scale.
Unlisted entries become zero; this format cannot separately represent missing
measurements. Experimental zero counts do not prove transcript absence.

Metadata follow matrix order:

```wl
data["CellMetadata"]
```

Get gene metadata:

```wl
data["GeneMetadata"]
```

All IDs and condition labels here are invented. In real data, check the
identifier namespace, assay and sampling design.

## Select by metadata

Find treated rows and the `gene-A` column, then retain cell IDs with the values:

```wl
cells = Normal[data["CellMetadata"]];
genes = Normal[data["GeneMetadata"]];
rows = Flatten[Position[Lookup[cells, "Condition"], "treated"]];
column = First[FirstPosition[Lookup[genes, "ID"], "gene-A"]];
```

Associate selected values with their cell IDs:

```wl
AssociationThread[Lookup[cells[[rows]], "ID"], Normal[data["ExpressionMatrix"][[rows, column]]]]
```

The selected values are 0 and 2. Check that requested IDs exist before applying
this pattern to another file. Record the selection beside the source hash:

```wl
<|"SourceContentHash" -> data["ContentHash"],
    "CellIDs" -> Lookup[cells[[rows]], "ID"],
    "GeneIDs" -> {genes[[column]]["ID"]},
    "Normalization" -> data["Normalization"]|>
```

The hash identifies the source file, not a new hash of this selected matrix.

## Summarize counts and retain provenance

Calculate total counts and detected genes per cell:

```wl
AssociationThread[Lookup[cells, "ID"], Normal[Total[data["ExpressionMatrix"], {2}]]]
```

Count detected genes per cell:

```wl
AssociationThread[Lookup[cells, "ID"], Normal[Total[Unitize[data["ExpressionMatrix"]], {2}]]]
```

Totals are 3, 5 and 3; detected-gene counts are 1, 1 and 2. These synthetic
values illustrate summaries, not quality thresholds or treatment effects.

Inspect the file's scale and provenance:

```wl
KeyTake[data, {"ContentHash", "Normalization", "Provenance"}]
```

The reader validates structure and hashes the bytes. Source provenance and
normalization remain declarations; it neither verifies their scientific
meaning nor normalizes the values.
