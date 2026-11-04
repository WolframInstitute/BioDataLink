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

An H5AD file can contain a measurement matrix, alternative layers, axis
annotations, embeddings and other analysis results. Reading one selected
matrix is not a complete import of that object. This tutorial makes the
selected layer and axis positions explicit, preserves missing annotations and
duplicate labels, and records what was omitted.

The bundled file is synthetic. Its labels and values test data handling rather
than describe biological observations. The examples require an explicitly
configured Python interpreter and are not evaluated during ordinary
documentation builds. After configuring the interpreter, work through the
examples in order. Stop if a call returns a `Failure`.

## Configure the optional local reader

The tested requirements are Python 3.13 with h5py 3.16.0 and NumPy 2.5.4.
Create a separate environment and install the pinned requirements from
`Assets/Python/requirements-h5ad.txt` in the paclet directory. For example,
after replacing these paths on a system using a `bin/python` environment:

```sh
python3.13 -m venv /path/to/biodatalink-h5ad
/path/to/biodatalink-h5ad/bin/python -m pip install -r /path/to/paclet/Assets/Python/requirements-h5ad.txt
```

Installation is an explicit setup step. Loading BioDataLink does not install
Python packages. The reader uses h5py and NumPy to read supported H5AD
encodings; it does not create a complete Python AnnData object. Alternatively,
set `BIODATALINK_PYTHON` to the interpreter's absolute path before starting
the Wolfram kernel.

For the calls below, set the interpreter explicitly:

```wl
#| eval: false
python = "/path/to/biodatalink-h5ad/bin/python";
```

## Read a small, explicit selection

Read the first two observations and first three variables from `X`:

```wl
#| eval: false
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}];
slice = BioDatasetLoad[File[file], "Format" -> "AnnData",
    "PythonExecutable" -> python, "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]
```

The checked fixture selection has values `{{0, 2, 0}, {7, 0, 11}}`.
Inspect its sparse matrix with a labeled color scale:

```wl
#| eval: false
MatrixPlot[slice["ExpressionMatrix"], PlotLegends -> Automatic, FrameLabel -> {"observation", "variable"}]
```

The result records `"MatrixValueType"` (here `"int64"`). Integer measurements
remain exact, including integers larger than a machine real can represent
exactly. Floating-point layers remain approximate real measurements.

Positions are one-based source positions, and a requested order is preserved.
In general AnnData, observations need not be cells and variables need not be
genes. BioDataLink retains the property names `"CellMetadata"` and
`"GeneMetadata"` for this interface; check the source assay before interpreting
those axes biologically.

## Preserve labels and missing annotations

Inspect the variable labels beside their original positions:

```wl
#| eval: false
slice["GeneMetadata"][All, {"SourceIndex", "ID"}]
```

The first two variables both have ID `"g1"`, at positions 1 and 2. They remain
separate columns. Building an association keyed only by this ID would lose that
distinction; retain the source position when labels are not unique.

Show selected observation annotations without overwriting the axis ID:

```wl
#| eval: false
slice["CellMetadata"][All, {"SourceIndex", "ID", "Annotations"}]
```

The second observation's `"kind"` is missing; the reader preserves that absence.
The source also has an annotation column named `"ID"`, kept inside
`"Annotations"` separately from the axis label. The labels `"T"` and `"B"`
in this fixture are invented categories, not inferred cell types.

Inspect the source encoding information for the categorical column:

```wl
#| eval: false
slice["CellMetadataEncoding"]["kind"]
```

This records whether categories are ordered, their total source count and the
selected labels at their original category positions. Unused category labels
are not imported. Missing annotations differ from missing numerical
measurements: selected NaN or infinite matrix values are rejected instead of
being converted to zero. Other missing-measurement information elsewhere in a
file is not inferred as a mask for this matrix.

## Choose a different layer deliberately

Select the floating-point layer named `normalized`, reversing the row order:

```wl
#| eval: false
KeyTake[BioDatasetLoad[File[file], "Format" -> "AnnData", "PythonExecutable" -> python,
        "Cells" -> {2, 1}, "Genes" -> {3, 2}, "Layer" -> {"Layers", "normalized"}],
    {"SourceLayer", "SelectedCells", "SelectedGenes", "Normalization"}]
```

The selected values are `{{1.1, 0}, {0, 0.2}}`. The name `normalized` does not
verify a transformation or measurement scale, so `"Normalization"` remains
`Missing["NotSpecified"]`. Consult source processing information before
comparing this layer with `X` or another study.

The raw storage location can have a different variable axis:

```wl
#| eval: false
BioDatasetLoad[File[file], "Format" -> "AnnData", "PythonExecutable" -> python,
    "Cells" -> {1, 2}, "Genes" -> {5, 2}, "Layer" -> {"Raw", "X"}]["GeneMetadata"][All, {"SourceIndex", "ID"}]
```

This file's raw matrix has five variables, compared with four in `X`.
The requested raw positions refer to `"r5"` and `"r2"`. A storage location
named `raw` is not evidence that values are unprocessed counts.

## Record the selection and its limits

Keep source dimensions, selected positions, omitted structures and interpreter
versions with the result:

```wl
#| eval: false
KeyTake[slice, {"SourceShape", "SourceLayer", "MatrixValueType", "SelectedCells", "SelectedGenes",
    "OmittedStructures", "BackendVersion", "ContentHash"}]
```

The result omits unselected layers and other AnnData structures, including
embeddings and unstructured annotations. It does not import a citation or infer
scientific provenance from those omitted structures. The source file's size and
modification time are recorded, but no full-file hash is computed: hashing a
large local file would require reading it in full. Retain a separate verified
download record or compute a file hash explicitly when the workflow requires it.

The default `"MaxFileBytes"` is 10,000,000 bytes for the entire file. For a
larger local file, explicitly choose a suitable larger limit or `Infinity`.
`"MaxSelectedElements"` limits selected rows times columns, including zeros;
`"MaxTransferBytes"` limits the serialized result and metadata returned to
Wolfram Language. These are not limits on all disk reads, decompressed HDF5
chunks or interpreter memory. Select the needed rows, columns and layer rather
than assuming that a small number of nonzero values makes every full-file
operation inexpensive.
