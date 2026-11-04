# Example data

## Iris

`iris.csv` contains the exact bytes of UCI's `iris.data`, downloaded on
2026-11-04 from
<https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data>.
Only the local filename was changed. No measurements, labels or blank lines
were altered.

Citation: Fisher, R. (1936). Iris [Dataset]. UCI Machine Learning Repository.
<https://doi.org/10.24432/C56C76>.

The dataset is distributed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/),
as stated on the [UCI dataset page](https://archive.ics.uci.edu/dataset/53/iris).
This dataset's license is separate from the paclet code's MIT license.

The source describes 150 plant records, each with sepal length, sepal width,
petal length and petal width in centimetres, plus a species label. The file has
no header; the documentation assigns column names from UCI's variable table.
UCI records differences between this distributed file and Fisher's historical
article. This copy deliberately retains the source values rather than making
undocumented corrections.

The file has 4551 bytes and SHA-256
`6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0`.
This hash was computed from the retrieved file, not supplied by the publisher.
`iris.provenance.json` retains the retrieval time, source, citation, license
and column interpretation.

## Synthetic expression examples

`toy-expression.json` contains invented integer values and cell/gene labels for
testing the BioDataLink JSON reader. Its condition labels do not describe an
experiment.

`toy-anndata.h5ad` is an invented AnnData file generated with AnnData 0.13.4.
It has three observations and four variables, deliberately repeated variable
IDs, integer-valued CSR `X`, a floating-point CSC layer named `normalized`,
and a five-variable `raw` matrix. Cell annotations include missing values and
an annotation named `ID` to test preservation of source field names. The
`normalized` layer name is a test label, not a claim about a scientific
normalization procedure. The synthetic data have no associated biological
study; their generator and exact expected values are part of the tests.
