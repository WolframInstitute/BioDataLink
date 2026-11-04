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

<code>[BioDatasetLoad]()[File[*path*]]</code> imports sparse expression data, metadata and provenance from a local BioDataLink JSON version 1 file.

<code>[BioDatasetLoad]()[File[*path*], "Format" -> "AnnData"]</code> imports a matrix selection and aligned axis metadata from a supported local H5AD file.

## Details & Options

- The format defaults to `"BioDataLinkJSON"`. H5AD files require explicit `"Format" -> "AnnData"`; the format is not guessed from a filename.
- AnnData reading requires an explicitly configured Python interpreter.
- Both formats return ordinary Wolfram expressions. They do not normalize values, assign cell types or establish scientific validity.
- `"MaxFileBytes"` limits the entire input file, including when only a small H5AD selection is requested.

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

- The following options can be given:

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

Load the bundled synthetic expression file:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]
```

---

Plot its sparse matrix. These values are synthetic, not experimental measurements:

```wl
MatrixPlot[BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]["ExpressionMatrix"],
    PlotLegends -> Automatic, FrameLabel -> {"cell", "gene"}]
```

## Scope

Inspect cell metadata in matrix row order:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]]["CellMetadata"]
```

---

Read two observations and three variables from a synthetic H5AD file.
Configure `BIODATALINK_PYTHON` before starting the kernel, as described in
[Reading Selected AnnData Measurements](paclet:WolframInstitute/BioDataLink/tutorial/ReadingAnnDataSlices).
This optional-backend example is not evaluated during documentation builds:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]], "Format" -> "AnnData", "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]
```

The repeated `"g1"` variable labels and missing annotations test preservation
of source metadata. They do not establish biological identity.

## Options

### Layer

Read an alternative matrix from the synthetic H5AD file. This example requires
the configured Python interpreter and is not evaluated during documentation builds:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]], "Format" -> "AnnData", "Layer" -> {"Layers", "normalized"}]
```

The layer name comes from the file. It does not verify a transformation, so
`"Normalization"` remains `Missing["NotSpecified"]`.

### MaxFileBytes

Reject a file exceeding a deliberately small byte limit:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]], "MaxFileBytes" -> 1]
```

## Applications

Load the synthetic matrix, then use its aligned metadata to select rows labeled
`"treated"` and the column labeled `"gene-A"`:

```wl
Module[{data = BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]], rows, column},
    rows = Flatten[Position[Normal[data["CellMetadata"][All, "Condition"]], "treated"]];
    column = First[FirstPosition[Normal[data["GeneMetadata"][All, "ID"]], "gene-A"]];
    AssociationThread[Normal[data["CellMetadata"][rows, "ID"]], Normal[data["ExpressionMatrix"][[rows, column]]]]]
```

The selected values are 0 and 2 for `"cell-2"` and `"cell-3"`.
Only the selected column is converted to an ordinary list. The labels are
invented for this example; the selection is not evidence of a treatment response.

---

Record the local file hash with its declared scale and provenance:

```wl
KeyTake[BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]]], {"ContentHash", "Normalization", "Provenance"}]
```

The hash identifies the imported bytes. The scale and source information are
declarations from the file, not independently verified scientific evidence.

## Possible Issues

Position-selection options require the AnnData format:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}]], "Genes" -> {1}]
```

Catalog identifiers and URLs are not local file inputs. Support for a file
format does not establish a verified import route for every catalog entry.

An unavailable Python interpreter gives `Failure["PythonUnavailable", ...]`.
Unsupported H5AD encodings, selected external links and virtual datasets are
rejected. Review `"OmittedStructures"` before treating a selection as sufficient
for an analysis.

A zero count does not establish that a transcript is biologically absent.
BioDataLink JSON cannot represent missing measurements. The AnnData reader
rejects selected nonfinite measurements instead of replacing them with zeros.
Neither reader establishes that values from different cells, genes or studies
are directly comparable.
