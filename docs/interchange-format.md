# BioDataLink JSON version 1

`BioDatasetLoad[File[path]]` reads one cells-by-genes matrix with ordered
metadata. This JSON format is separate from the optional H5AD reader.

| Field | Contract |
| --- | --- |
| `SchemaVersion` | Integer `1` |
| `Shape` | Two positive integers: number of cells, number of genes |
| `Entries` | List of `[row, column, value]` triples with one-based coordinates |
| `Cells` | One metadata object per matrix row, each with a unique nonempty `ID` |
| `Genes` | One metadata object per matrix column, each with a unique nonempty `ID` |
| `Normalization` | Nonblank string declaring the measurement scale or processing state |
| `Provenance` | Object including nonblank `Source` and `Citation` strings |

Coordinates must be unique and within `Shape`; values must be finite and
nonzero. `Counts` requires positive stored integers. Metadata lengths must
match the axes. IDs are unique within each axis but may occur on both axes.

## Zero values and missing measurements

Every omitted coordinate becomes zero. Version 1 has no missing-measurement
mask: do not omit unknown or unmeasured entries as though they were zeros.
Use another representation or an explicitly documented complete selection.

A recorded zero does not prove transcript absence. When combining studies,
retain assay coverage; for example, the
[Census schema](https://chanzuckerberg.github.io/cellxgene-census/cellxgene_census_docsite_schema.html)
stores gene measurement presence separately.

## Measurement scale and identifiers

`Normalization` and provenance are declarations. Integer validation does not
establish reads versus molecules or unprocessed counts. Other scale labels
are retained without checking the transformation; import never normalizes.

Record assay, counting method, layer, processing, accession and release.
Retain gene namespace, organism and reference version when known, and link
cells to samples and conditions. Unique labels establish alignment, not
annotation accuracy, biological replication or comparability.

## Synthetic example

```json
{
  "SchemaVersion": 1,
  "Shape": [2, 2],
  "Entries": [[1, 1, 3], [2, 2, 5]],
  "Cells": [{"ID": "cell-1"}, {"ID": "cell-2"}],
  "Genes": [{"ID": "gene-1"}, {"ID": "gene-2"}],
  "Normalization": "Counts",
  "Provenance": {
    "Source": "Synthetic example",
    "Citation": "BioDataLink documentation; not experimental data"
  }
}
```

The result contains a sparse `ExpressionMatrix`, ordered `CellMetadata` and
`GeneMetadata` datasets, schema version, declared scale and provenance.
`SourceFile` and SHA-256 `ContentHash` identify the exact bytes parsed; the
hash is not an independent upstream verification.

The whole-file limit defaults to 10,000,000 bytes. Malformed structure,
misaligned metadata and invalid sparse entries return a structured failure.
UTF-8 is required. Numeric exponents outside −10000 to 10000 give
`Failure["UnsupportedNumericRange", ...]` before parsing; strings are unaffected.
Required `Source` and `Citation` strings do not validate attribution or biology.
