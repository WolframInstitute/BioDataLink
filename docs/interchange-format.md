# BioDataLink JSON version 1

`BioDatasetLoad[File[path]]` reads a local JSON object with this structure. The
initial format represents one cells-by-genes numerical matrix with ordered
metadata. It does not read H5AD files or preserve every part of an AnnData object.

| Field | Contract |
| --- | --- |
| `SchemaVersion` | Integer `1` |
| `Shape` | Two positive integers: number of cells, number of genes |
| `Entries` | List of `[row, column, value]` triples with one-based coordinates |
| `Cells` | One metadata object per matrix row, each with a unique nonempty `ID` |
| `Genes` | One metadata object per matrix column, each with a unique nonempty `ID` |
| `Normalization` | Nonblank string declaring the measurement scale or processing state |
| `Provenance` | Object including nonblank `Source` and `Citation` strings |

Each sparse coordinate appears at most once and lies within `Shape`. Values
must be finite nonzero numbers. With `Normalization` set to `Counts`, stored
entries must be positive integers; the complete matrix is nonnegative because
unlisted entries are zero. Cell and gene identifiers are unique within their
own axis; an identifier may occur on both axes.

## Zero values and missing measurements

Every unlisted coordinate becomes numerical zero on the declared measurement
scale. Version 1 has no missing-value mask: it cannot distinguish zero from
an unknown value or a gene that was not measured. Do not export such values by
omitting them. Data with unknown entries need a representation that preserves
that distinction, or an explicitly documented selection with no unknown entries.

A zero in a count matrix means no count was recorded at that position, not that
the transcript was necessarily absent from the cell. Sparse storage describes
how numbers are stored; it does not explain why zeros occur. The distinction
also matters when combining studies: for example, CELLxGENE Census keeps a
separate record of which genes were measured in each dataset. See the
[Census schema](https://chanzuckerberg.github.io/cellxgene-census/cellxgene_census_docsite_schema.html).

## Measurement scale and identifiers

`Counts` is a declaration from the file's author. The reader checks integer
values but cannot establish whether they count sequencing reads or molecules,
or whether preprocessing has altered them. Both read and molecule counts occur
in single-cell repositories, including
[CELLxGENE Census](https://chanzuckerberg.github.io/cellxgene-census/cellxgene_census_docsite_schema.html).
Other `Normalization` labels are retained without interpreting or verifying
the claimed transformation. The reader never normalizes values.

Record the assay, counting method, selected source layer and transformations
alongside the source accession and release. For gene identifiers, include the
identifier namespace, organism and reference version when known. Cell labels
must retain the relationship to their samples and experimental conditions.
Unique labels allow alignment; they do not verify gene identity, cell type,
biological replication or comparability of measurements.

## Synthetic example

This minimal file contains invented values and labels:

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

The reader returns an association containing `ExpressionMatrix` as a
`SparseArray`, `CellMetadata` and `GeneMetadata` as ordered `Dataset` objects,
and `SchemaVersion`, `Normalization` and `Provenance`. It also records
`SourceFile` and a SHA-256 `ContentHash` calculated from the same bytes that
were parsed. This records local content identity, not agreement with an
independently supplied source checksum.

The default `MaxFileBytes` limit is 10,000,000 bytes. File size, JSON structure,
metadata alignment and sparse entries are checked before a result is returned.
A malformed file produces a structured failure rather than a partial matrix.

Files must use UTF-8 JSON. To bound numeric parsing, exponents in numerical
values must lie between -10000 and 10000, inclusive. Larger exponent magnitudes
give `Failure["UnsupportedNumericRange", ...]` before JSON parsing. This limit
does not apply to text inside quoted strings.

The required `Source` and `Citation` strings record declared provenance. Their
presence does not establish correct attribution, data quality or scientific
validity. The reader does not infer a reference genome or recover a missing
citation. Check the original source and processing history before analysis.
