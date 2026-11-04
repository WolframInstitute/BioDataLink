---
Template: Symbol
Name: BioDatasetLoad
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetLoad
Keywords: [JSON, H5AD, AnnData, expression matrix, sparse arrays, local import]
SeeAlso: [BioDatasetDownload, BioDatasetInfo, BioDatasetSearch, Dataset, File, SparseArray]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
RelatedTutorials: [ExploringBiologicalData, ReadingAnnDataSlices, UnderstandingSparseMeasurements]
---

## Usage

<code>[BioDatasetLoad]()[File[*path*]]</code> validates a local BioDataLink JSON version 1 file and returns its expression data and provenance.

<code>[BioDatasetLoad]()[File[*path*], "Format" -> "AnnData"]</code> reads a selected matrix and its axis metadata from a supported local H5AD file using an explicitly configured Python interpreter.

## Details & Options

- The format defaults to `"BioDataLinkJSON"`. H5AD files require explicit `"Format" -> "AnnData"`; the format is not guessed from a filename.
- Both formats return ordinary Wolfram expressions. Neither performs normalization, assigns a cell type or establishes scientific validity.
- `"MaxFileBytes"` applies to the entire local file for both formats, even when only a small H5AD selection is requested.

The following file requirements apply to `"BioDataLinkJSON"`:

- The file contains `"SchemaVersion"`, `"Shape"`, `"Entries"`, `"Cells"`, `"Genes"`, `"Normalization"` and `"Provenance"` fields.
- `"Shape"` is `{cells, genes}` with positive integer dimensions. Metadata lengths must match those dimensions.
- `"Entries"` contains `{row, column, value}` triples with one-based coordinates, unique positions and finite nonzero numeric values. Unlisted entries are zero.
- The format has no separate representation for missing or unmeasured matrix values. Do not encode them by omitting entries.
- Each cell and gene metadata record has a nonempty `"ID"`; identifiers are unique within each axis.
- Identifier checks establish label uniqueness and alignment, not cell type or gene annotation accuracy.
- `"Normalization"` is a nonblank string declaring the measurement scale. `"Counts"` requires nonnegative integer matrix values; zero entries must be omitted.
- Integer validation does not establish whether counts represent reads or molecules, or whether they are unprocessed. Other normalization labels are retained without verifying the declared transformation.
- `"Provenance"` includes nonblank `"Source"` and `"Citation"` strings. These are source declarations; their scientific accuracy is not checked.
- The file is read as JSON data. It is not evaluated as Wolfram Language code.
- Input must be UTF-8 JSON. Numeric exponents must lie between -10000 and 10000; larger magnitudes give `Failure["UnsupportedNumericRange", ...]` before JSON parsing. Text inside strings is unaffected.
- The result is an `Association` with these properties:

| | |
| --- | --- |
| `"ExpressionMatrix"` | `SparseArray` with rows and columns aligned to the returned metadata |
| `"CellMetadata"`, `"GeneMetadata"` | `Dataset` objects ordered to match the corresponding matrix axes |
| `"SchemaVersion"` | JSON schema version; present for the BioDataLink JSON result |
| `"Normalization"` | Declared scale for JSON; `Missing["NotSpecified"]` for AnnData |
| `"Provenance"` | Declared JSON source information, or H5AD file, selection and interpreter information |
| `"SourceFile"` | Local input file location |
| `"ContentHash"` | SHA-256 of the JSON bytes read; `Missing["NotComputed"]` for AnnData |

- For JSON, `"ContentHash"` identifies the exact bytes parsed. It is not an independently supplied upstream checksum.
- Unsupported schema versions, malformed files and invalid matrix/metadata structures give a `Failure`. Catalog identifiers and URLs are not local file inputs.

The AnnData format reads one matrix selection and aligned axis metadata:

- Supported matrix encodings are dense array 0.2.0 and CSR/CSC sparse matrix 0.1.0 in an AnnData 0.1.0 H5AD file. Axis metadata must use dataframe encoding 0.2.0.
- Selected data using HDF5 soft or external links, virtual datasets or external raw storage are unsupported.
- Rows are AnnData observations and columns are variables. The result retains the names `"CellMetadata"` and `"GeneMetadata"`; those property names do not establish that every observation is a cell or every variable is a gene.
- `"Cells"` and `"Genes"` are `All` or nonempty lists of unique, positive, one-based source positions. The requested order is preserved.
- `"Layer"` selects `"X"`, `{"Layers", name}` or `{"Raw", "X"}`. Raw selections use the raw variable axis, which can differ from the main variable axis. A layer name is not a verified measurement scale.
- Metadata rows contain the original `"ID"`, a one-based `"SourceIndex"` and an `"Annotations"` association. Duplicate original IDs are preserved; source annotations named `"ID"` remain nested and cannot replace the axis label.
- Supported scalar, string, categorical and nullable annotations are retained, with missing annotations represented by `Missing["NotAvailable"]`. Encoding records retain column encodings, categorical ordering, total category counts and selected category labels at their original positions. Unused category labels are not imported.
- Matrix values must be real integer or floating-point types of at most 64 bits. Integer values remain exact; floating-point values become approximate Wolfram real numbers. The source type is recorded as `"MatrixValueType"`.
- Selected numerical values must be finite. NaN or infinite measurements give `Failure["MissingMeasurement", ...]`; they are not replaced with zeros. The reader does not infer a missing-measurement mask from other file structures.
- `"Normalization"` is `Missing["NotSpecified"]` and provenance citation is `Missing["NotImported"]`. Other layers, embeddings, graphs and unstructured annotations are not imported as a complete AnnData object.
- The reader does not hash the entire H5AD file. File size and modification time are recorded and checked for a change during reading, but they are not content checksums.
- Python must be configured explicitly, with the optional pinned h5py and NumPy requirements. `Automatic` uses only the `BIODATALINK_PYTHON` environment variable. No environment or package is installed automatically.
- AnnData results also contain these fields:

| | |
| --- | --- |
| `"Format"`, `"Shape"` | `"AnnData"` and selected matrix dimensions |
| `"MatrixValueType"` | Source matrix numeric type, also retained in provenance |
| `"SourceShape"`, `"SourceLayer"` | Selected layer's dimensions before slicing and the layer used |
| `"SelectedCells"`, `"SelectedGenes"` | Original one-based axis positions in the requested order |
| `"CellMetadataEncoding"`, `"GeneMetadataEncoding"` | Source metadata-column encoding information |
| `"OmittedStructures"` | File structures not included in this result |
| `"BackendVersion"` | Python, h5py and NumPy versions used |
| `"SourceFileBytes"`, `"SourceFileModifiedUnixNanoseconds"` | Source file size and modification-time information |

- Options are listed with defaults in the middle column:

| | | |
| --- | --- | --- |
| `"Cells"` | `All` | AnnData observation positions, preserving the supplied order |
| `"Format"` | `"BioDataLinkJSON"` | `"BioDataLinkJSON"` or `"AnnData"` |
| `"Genes"` | `All` | AnnData variable positions in the selected layer, preserving the supplied order |
| `"Layer"` | `"X"` | AnnData matrix: `"X"`, `{"Layers", name}` or `{"Raw", "X"}` |
| `"MaxFileBytes"` | `10000000` | Entire input-file length in bytes; a positive integer or `Infinity` |
| `"MaxSelectedElements"` | `10000000` | AnnData row count times column count; a positive integer |
| `"MaxTransferBytes"` | `67108864` | Maximum serialized AnnData result size, including metadata; a positive integer |
| `"PythonExecutable"` | `Automatic` | AnnData interpreter's absolute path, or the path in `BIODATALINK_PYTHON` |
| `"TimeConstraint"` | `60` | AnnData reading time in seconds; positive and at most 3600 |

- `"Cells"`, `"Genes"` and `"Layer"` selections require AnnData; nondefault selections with JSON give `Failure["UnsupportedOption", ...]`.
- `"MaxSelectedElements"` counts logical matrix positions, not stored nonzero entries. The transfer limit bounds the serialized result, not total disk reads or all interpreter memory.

## Basic Examples

Load the bundled synthetic expression example:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]]]
```

---

Inspect its synthetic sparse matrix; these values are not experimental measurements:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    MatrixPlot[BioDatasetLoad[File[file]]["ExpressionMatrix"], PlotLegends -> Automatic,
        FrameLabel -> {"cell", "gene"}]]
```

## Scope

Inspect the cell metadata in matrix row order:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    BioDatasetLoad[File[file]]["CellMetadata"]]
```

Read a small AnnData selection after configuring the optional Python interpreter.
This local, optional-dependency input is not evaluated during ordinary documentation builds:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-anndata.h5ad"}]],
    "Format" -> "AnnData", "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]
```

The bundled H5AD file is synthetic. Its repeated `"g1"` variable labels and
missing cell annotations demonstrate preservation of source metadata, not
biological identity or an experimental result.

## Options

### Layer

Select an explicitly named layer from the synthetic H5AD file. This requires
the optional interpreter and is not evaluated during documentation generation:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-anndata.h5ad"}]],
    "Format" -> "AnnData", "Cells" -> {2, 1}, "Genes" -> {3, 2},
    "Layer" -> {"Layers", "normalized"}]
```

The requested matrix is `{{1.1, 0}, {0, 0.2}}`. The layer name is copied from
the file; `"Normalization"` still remains unspecified.

### MaxFileBytes

Reject an input exceeding a deliberately small byte limit:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    BioDatasetLoad[File[file], "MaxFileBytes" -> 1]]
```

## Applications

Select example rows by a metadata label and locate a column by its gene ID:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    Module[{data = BioDatasetLoad[File[file]], cells, genes, rows, column},
        cells = Normal[data["CellMetadata"]];
        genes = Normal[data["GeneMetadata"]];
        rows = Pick[Range[Length[cells]], Lookup[cells, "Condition"], "treated"];
        column = First[FirstPosition[Lookup[genes, "ID"], "gene-A"]];
        Dataset[MapThread[<|"CellID" -> #1, "gene-A" -> #2|> &,
            {Lookup[cells[[rows]], "ID"],
                Normal[data["ExpressionMatrix"][[rows, column]]]}]]]]
```

The two selected values are 0 and 2 for `"cell-2"` and `"cell-3"`.
Only the selected column is converted to an ordinary list; the full matrix
remains sparse. The condition and gene labels are invented for this example,
so this selection is not evidence of a treatment response.

Record the local file hash with its declared provenance:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    KeyTake[BioDatasetLoad[File[file]], {"ContentHash", "Normalization", "Provenance"}]]
```

## Possible Issues

Catalog discovery and local import have different inputs. A generic supported
format does not establish a verified import route for every catalog entry.
Use a supported local file and choose its format explicitly.

An unavailable Python interpreter gives `Failure["PythonUnavailable", ...]`.
Unsupported H5AD encodings, selected external links and virtual datasets are
rejected. The returned `"OmittedStructures"` should be reviewed before treating
a selection as sufficient for a scientific analysis.

A zero count is a recorded numerical value, not evidence that a transcript is
biologically absent. BioDataLink JSON cannot represent missing measurements;
the AnnData reader rejects selected nonfinite measurements instead of zero-filling them.
The reader does not normalize data or establish that values from different
cells, genes or studies are directly comparable.
