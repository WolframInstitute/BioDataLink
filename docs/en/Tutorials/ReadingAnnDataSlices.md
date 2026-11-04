---
Template: TechNote
Name: ReadingAnnDataSlices
Title: Reading Selected AnnData Measurements
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/tutorial/ReadingAnnDataSlices
Keywords: [application, AnnData, H5AD, sparse arrays, metadata, selection]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
---

Read a selected H5AD matrix with its row and column metadata. Other AnnData
structures are listed as omitted. The bundled file is **synthetic**.

These examples require the optional Python reader and are not evaluated during
ordinary documentation builds. Run them in order after setup; stop on `Failure`.

## Configure Python

Tested versions are Python 3.13, h5py 3.16.0 and NumPy 2.5.4. Replace the paths
and install the paclet's pinned requirements into a separate environment:

```sh
python3.13 -m venv /path/to/biodatalink-h5ad
/path/to/biodatalink-h5ad/bin/python -m pip install -r /path/to/paclet/Assets/Python/requirements-h5ad.txt
```

Select the configured interpreter:

```wl
#| eval: false
python = "/path/to/biodatalink-h5ad/bin/python";
```

Alternatively, set `BIODATALINK_PYTHON` to the interpreter's absolute path before
starting the kernel. Loading BioDataLink does not install dependencies.

## Select rows and columns

Read two observations and three variables from `X`:

```wl
#| eval: false
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}];
slice = BioDatasetLoad[File[file], "Format" -> "AnnData",
    "PythonExecutable" -> python, "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]
```

Plot the selected matrix:

```wl
#| eval: false
MatrixPlot[slice["ExpressionMatrix"], PlotLegends -> Automatic, FrameLabel -> {"observation", "variable"}]
```

The selected values are `{{0, 2, 0}, {7, 0, 11}}`. Positions are one-based and
requested order is preserved. Integer values stay exact; floating-point values
remain approximate. AnnData observations and variables need not mean cells and
genes, despite the interface names `CellMetadata` and `GeneMetadata`.

## Preserve labels and missing annotations

```wl
#| eval: false
slice["GeneMetadata"][All, {"SourceIndex", "ID"}]
```

The first two variables both have ID `g1`. Use `SourceIndex` to distinguish
them; joining solely on a repeated ID loses columns.

```wl
#| eval: false
slice["CellMetadata"][All, {"SourceIndex", "ID", "Annotations"}]
```

Missing annotations stay missing. Annotation fields, including a field named
`ID`, are nested under `Annotations` separately from the axis ID.

```wl
#| eval: false
slice["CellMetadataEncoding"]["kind"]
```

Categorical metadata retain ordering, source category count and selected
labels at their source positions. Unused labels are omitted. Selected NaN or
infinite measurements are rejected; omitted structures are not inferred as
missing-measurement masks.

## Choose the layer

Read a named layer with reversed row order:

```wl
#| eval: false
KeyTake[BioDatasetLoad[File[file], "Format" -> "AnnData", "PythonExecutable" -> python,
        "Cells" -> {2, 1}, "Genes" -> {3, 2}, "Layer" -> {"Layers", "normalized"}],
    {"SourceLayer", "SelectedCells", "SelectedGenes", "Normalization"}]
```

Its selected values are `{{1.1, 0}, {0, 0.2}}`. A name such as `normalized`
does not verify processing; `Normalization` remains `Missing["NotSpecified"]`.

The `raw` location can have its own variable axis:

```wl
#| eval: false
BioDatasetLoad[File[file], "Format" -> "AnnData", "PythonExecutable" -> python,
    "Cells" -> {1, 2}, "Genes" -> {5, 2}, "Layer" -> {"Raw", "X"}]["GeneMetadata"][All, {"SourceIndex", "ID"}]
```

Here `raw` has five variables, versus four in `X`. Its name does not establish
that values are unprocessed counts.

## Keep the selection record

```wl
#| eval: false
KeyTake[slice, {"SourceShape", "SourceLayer", "MatrixValueType", "SelectedCells", "SelectedGenes",
    "OmittedStructures", "BackendVersion", "ContentHash"}]
```

Retain the layer, positions, source shape, omitted structures and backend
versions. No whole-file hash is computed; keep a verified download record or
compute a hash separately when needed.

The default whole-file limit is 10,000,000 bytes. Raise `MaxFileBytes`
explicitly for larger files. `MaxSelectedElements` bounds selected rows ×
columns, including zeros; `MaxTransferBytes` bounds the serialized result.
Neither bounds all HDF5 disk reads or interpreter memory.
