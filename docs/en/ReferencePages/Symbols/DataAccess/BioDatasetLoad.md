---
Template: Symbol
Name: BioDatasetLoad
Context: WolframInstitute`BioDataLink`
Paclet: WolframInstitute/BioDataLink
URI: WolframInstitute/BioDataLink/ref/BioDatasetLoad
Keywords: [JSON, expression matrix, sparse arrays, local import]
SeeAlso: [BioDatasetInfo, BioDatasetSearch, Dataset, File, SparseArray]
RelatedGuides: [BioDataLink, DataAccess]
RelatedTutorials: [ExploringBiologicalData]
---

## Usage

<code>[BioDatasetLoad]()[File[*path*]]</code> validates a local BioDataLink JSON version 1 file and returns its expression data and provenance.

## Details & Options

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
| `"ExpressionMatrix"` | `SparseArray` with cells on rows and genes on columns |
| `"CellMetadata"`, `"GeneMetadata"` | `Dataset` objects ordered to match the corresponding matrix axes |
| `"SchemaVersion"`, `"Normalization"` | Schema version and declared measurement scale from the source file |
| `"Provenance"` | Declared source information |
| `"SourceFile"` | Local input file location |
| `"ContentHash"` | SHA-256 digest of the local input file |

- `"ContentHash"` identifies the exact bytes parsed. It is not an independently supplied upstream checksum.
- Unsupported schema versions, malformed files and invalid matrix/metadata structures give a `Failure`.
- The current reader accepts local BioDataLink JSON only. Catalog identifiers, URLs and H5AD files are not supported input forms.
- Options are listed with defaults in the middle column:

| | | |
| --- | --- | --- |
| `"MaxFileBytes"` | `10000000` | Maximum input-file length in bytes; a positive integer or `Infinity` |

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

## Options

### MaxFileBytes

Reject an input exceeding a deliberately small byte limit:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    BioDatasetLoad[File[file], "MaxFileBytes" -> 1]]
```

## Applications

Record the local file hash with its declared provenance:

```wl
With[{file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}]},
    KeyTake[BioDatasetLoad[File[file]], {"ContentHash", "Normalization", "Provenance"}]]
```

## Possible Issues

Catalog discovery and local import have different inputs. An entry in the
catalog may link to a source H5AD file that this reader cannot load.
A local file must use the documented JSON schema before this reader can load it.

A zero count is a recorded numerical value, not evidence that a transcript is
biologically absent. Missing measurements cannot be represented by this format.
The reader does not normalize data or establish that values from different
cells, genes or studies are directly comparable.
