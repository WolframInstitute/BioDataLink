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

## Real-data case studies

Five folders hold real public data for the worked case-study tutorials. The
`provenance.json` files record source URLs, SHA-256 hashes of downloaded bytes,
retrieval times, citations, license statements and transformations. PBMC3k
keeps this information in the `Provenance` field of `pbmc3k-subset.json`.
The hashes were computed from files retrieved on 2026-11-04, not supplied by the
publishers. Dataset licenses are separate from the paclet code's MIT license.

| Folder | Contents | Source and license | Tutorial |
| --- | --- | --- | --- |
| `PBMC3k` | Single-cell UMI counts, 2,700 cells × 513 genes | 10x Genomics, CC BY 4.0 | Analyzing Single-Cell Expression in Human Blood |
| `AdenylateKinase` | PDB entries 4AKE and 1AKE | wwPDB, CC0 1.0 | Comparing Protein Conformations |
| `BorreliaB31` | Chromosome sequence and gene annotation, NC_001318.1 | NCBI RefSeq | Reading the Composition of a Bacterial Genome |
| `Coronaviruses` | Genomes and gene annotations, NC_045512.2, MN996532.2, NC_004718.3 | NCBI RefSeq and GenBank | Comparing Coronavirus Genomes |
| `LiverCircadian` | Hourly mouse liver expression, 2,046 probes × 48 times | NCBI GEO GSE11923 | Finding Circadian Rhythms in Gene Expression |

NCBI places no restrictions on the use or distribution of GenBank, RefSeq or
GEO data, although submitters may claim rights in submitted data; see the
[NCBI policies](https://www.ncbi.nlm.nih.gov/home/about/policies/). Cite the
original studies listed in each provenance record.

`AdenylateKinase`, `BorreliaB31` and `Coronaviruses` store each downloaded file
unchanged, compressed with gzip. Decompressing a file gives the bytes whose
SHA-256 is recorded. Wolfram Language imports the compressed files directly.

`PBMC3k/pbmc3k-subset.json` is BioDataLink JSON derived from the Cell Ranger
1.1.0 filtered gene-barcode matrices of the
[3k PBMCs from a Healthy Donor](https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0)
dataset. It keeps all 2,700 barcodes and unchanged UMI counts for the union of
four gene sets: the 300 genes with the highest analytic Pearson residual
variance (overdispersion 100, clipped at the square root of the number of
cells) over cells with 200 to 2,500 detected genes and under 5% mitochondrial
counts; 15 marker genes; the 13 `MT-` genes; and 200 genes sampled with seed
20261104 among genes detected in at least 3 barcodes. Gene metadata flag each
set and record the source row; cell metadata record totals over all 32,738
genes. The file's `Provenance` field repeats the source, license and archive
hash.

`LiverCircadian/GSE11923-liver-subset.tsv.gz` keeps every probe annotated to
19 clock genes in the GPL1261 annotation, plus 2,000 other probes sampled with
seed 20261104, excluding Affymetrix control probes. The GEO matrix metadata
identifies the values as MAS5 signals, copied as text; gene symbols come from
the platform annotation, and a blank symbol means none was annotated.

For the liver series, the paper reports GCRMA expression estimates and MAS5
present/absent calls. The bundled subset preserves the deposited MAS5 matrix;
it does not reproduce the paper's preprocessing or rhythm-detection pipeline.

Maintainers can rebuild these folders from the pinned downloads with
`make example-data`, which needs network access and curl 8.4 or later. Set
`BIODATALINK_CURL` to choose a curl executable. A changed upstream file fails
its hash check instead of silently replacing the bundled data.
Each rebuild records its actual retrieval time. The PBMC integrity test hashes
compact JSON after removing only `Provenance.RetrievedAt`, so a fresh retrieval
of identical data passes while counts, axes, selection and fixed provenance
remain pinned. `BioDatasetLoad` still reports a hash of the actual file bytes.

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
