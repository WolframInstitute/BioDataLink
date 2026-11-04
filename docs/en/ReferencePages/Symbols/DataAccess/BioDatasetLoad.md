---
Template: Symbol
Name: BioDatasetLoad
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetLoad
Keywords: [JSON, H5AD, AnnData, expression matrix, sparse arrays, local import]
SeeAlso: [BioDatasetDownload, BioDatasetInfo, BioDatasetSearch, Dataset, File, FileHash, SparseArray]
RelatedGuides: [BioDataLink, DataAccess, Downloads]
RelatedTutorials: [ExploringBiologicalData, ReadingAnnDataSlices, UnderstandingSparseMeasurements]
---

## Usage

<code>[BioDatasetLoad]()[File[*path*]]</code> imports a local BioDataLink JSON expression file.

<code>[BioDatasetLoad]()[File[*path*], "Format" -> "AnnData"]</code> imports a selected matrix and axis metadata from a local H5AD file.

## Details & Options

- *path* is a local file path string. URLs and catalog identifiers are not accepted.
- The result is an `Association`. Values are imported without normalization.
- Returned properties include:

| | |
| --- | --- |
| `"ExpressionMatrix"` | `SparseArray` with rows and columns aligned to the returned metadata |
| `"CellMetadata"`, `"GeneMetadata"` | `Dataset` objects ordered to match the corresponding matrix axes |
| `"SchemaVersion"` | JSON schema version; present for the BioDataLink JSON result |
| `"Normalization"` | Declared scale for JSON; `Missing["NotSpecified"]` for AnnData |
| `"Provenance"` | Declared JSON source information, or H5AD file, selection and interpreter information |
| `"SourceFile"` | Local input file location |
| `"ContentHash"` | SHA-256 of the JSON bytes read; `Missing["NotComputed"]` for AnnData |

- JSON version 1 represents a cells-by-genes matrix. Shape dimensions are positive; metadata lengths must match, with nonempty IDs unique within each axis.
- JSON fields are `"SchemaVersion"`, `"Shape"`, `"Entries"`, `"Cells"`, `"Genes"`, `"Normalization"` and `"Provenance"`.
- Entries are unique, one-based `{row, column, value}` triples with finite nonzero values. Omitted entries are zero; missing measurements cannot be represented.
- `"Counts"` requires nonnegative integers. It does not establish reads versus molecules or preprocessing; other nonblank scale labels are retained as declarations.
- JSON provenance requires nonblank `"Source"` and `"Citation"` strings. Declared provenance is not independently verified.
- JSON must be UTF-8. Numeric exponents outside −10000 to 10000 are rejected; text in strings is unaffected. JSON is parsed as data, not evaluated as code.
- H5AD reading requires `"Format" -> "AnnData"` and a configured Python interpreter. Its axes are observations and variables, which need not mean cells and genes.
- Supported H5AD encodings are AnnData 0.1.0, dataframe 0.2.0, dense array 0.2.0 and CSR/CSC 0.1.0.
- AnnData selections use `All` or unique positive one-based positions, in the requested order. `{"Raw", "X"}` uses its own variable axis.
- Metadata retain `"ID"`, `"SourceIndex"` and nested `"Annotations"`. Duplicate IDs and missing annotations are preserved.
- Categorical metadata retain ordering, category count and selected labels at source positions.
- Matrix values must be real integer or floating-point types of at most 64 bits. Integers remain exact; floats remain approximate.
- Selected nonfinite values give `Failure["MissingMeasurement", ...]`. No missing-measurement mask is inferred.
- Selected soft/external links, virtual datasets and external raw storage are unsupported. Other layers, embeddings, graphs and unstructured annotations are omitted.
- AnnData normalization is unspecified and citation is `Missing["NotImported"]`. File size and modification time detect changes during reading; no whole-file hash is computed.
- AnnData results also include:

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

- `"Cells"`, `"Genes"` and `"Layer"` selections require AnnData.
- `"MaxFileBytes"` applies to the entire file. `"MaxSelectedElements"` counts selected rows times columns, including zeros.
- `"MaxTransferBytes"` bounds the serialized result, not all disk reads or interpreter memory.
- Install the pinned h5py/NumPy requirements separately. `"PythonExecutable" -> Automatic` uses only `BIODATALINK_PYTHON`; no environment is installed or discovered.

## Basic Examples

Import the bundled synthetic expression matrix:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
data = BioDatasetLoad[File[file]];
data["ExpressionMatrix"]
```

Plot the matrix:

```wl
MatrixPlot[data["ExpressionMatrix"], PlotLegends -> Automatic, FrameLabel -> {"cell", "gene"}]
```

## Scope

### Metadata

Get metadata in row order:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
data = BioDatasetLoad[File[file]];
data["CellMetadata"]
```

Get metadata in column order:

```wl
data["GeneMetadata"]
```

### AnnData

Select observations and variables from a synthetic H5AD file:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]], "Format" -> "AnnData", "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}]
```

AnnData examples require the Python setup in
[Reading Selected AnnData Measurements](paclet:WolframInstitute/BioDataLink/tutorial/ReadingAnnDataSlices)
and have no saved results.

## Options

### Layer

Select a named H5AD layer:

```wl
#| eval: false
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-anndata.h5ad"}]], "Format" -> "AnnData", "Layer" -> {"Layers", "normalized"}]
```

A layer name does not establish its normalization.

### MaxFileBytes

Reject a file larger than the specified limit:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
BioDatasetLoad[File[file], "MaxFileBytes" -> 1]
```

## Applications

Calculate total counts for each synthetic cell:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
data = BioDatasetLoad[File[file]];
AssociationThread[Normal[data["CellMetadata"][All, "ID"]], Normal[Total[data["ExpressionMatrix"], {2}]]]
```

## Properties & Relations

The JSON content hash matches the imported file's SHA-256:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
data = BioDatasetLoad[File[file]];
data["ContentHash"] === FileHash[file, "SHA256", "HexString"]
```

Inspect the declared scale and provenance:

```wl
KeyTake[data, {"Normalization", "Provenance"}]
```

## Possible Issues

Positional selections require the AnnData format:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "toy-expression.json"}];
BioDatasetLoad[File[file], "Genes" -> {1}]
```

Malformed files and unsupported structures give `Failure`. Missing Python gives
`Failure["PythonUnavailable", ...]`. Review `"OmittedStructures"` before analysis.
