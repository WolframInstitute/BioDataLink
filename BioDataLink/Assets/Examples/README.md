# Example data

Data licenses are separate from the code's MIT license. Cite the original
sources. Provenance records retain URLs, retrieval times, citations, licenses,
hashes and transformations. Hashes identify files retrieved on 2026-11-04;
they were computed locally, not supplied by publishers.

## Iris

`iris.csv` preserves the exact bytes of
[UCI's iris.data](https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data),
renamed without changing values or blank lines. Its 150 records contain sepal
length, sepal width, petal length and petal width in centimetres, then species.
There is no header. UCI's documented differences from Fisher's article remain.

Citation: Fisher, R. (1936). [Iris](https://doi.org/10.24432/C56C76).
UCI Machine Learning Repository. License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/),
as stated by [UCI](https://archive.ics.uci.edu/dataset/53/iris).

Size: 4551 bytes. SHA-256:
`6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0`.
See `iris.provenance.json` for retrieval and column definitions.

## Real-data case studies

| Folder | Contents | Source and license | Tutorial |
| --- | --- | --- | --- |
| `PBMC3k` | Single-cell UMI counts, 2,700 cells × 513 genes | 10x Genomics, CC BY 4.0 | Analyzing Single-Cell Expression in Human Blood |
| `AdenylateKinase` | PDB entries 4AKE and 1AKE | wwPDB, CC0 1.0 | Comparing Protein Conformations |
| `BorreliaB31` | Chromosome sequence and gene annotation, NC_001318.1 | NCBI RefSeq | Reading the Composition of a Bacterial Genome |
| `Coronaviruses` | Genomes and gene annotations, NC_045512.2, MN996532.2, NC_004718.3 | NCBI RefSeq and GenBank | Comparing Coronavirus Genomes |
| `LiverCircadian` | Hourly mouse liver expression, 2,046 probes × 48 times | NCBI GEO GSE11923 | Finding Circadian Rhythms in Gene Expression |

Each folder has `provenance.json`; PBMC3k instead uses the JSON file's
`Provenance` field. PDB and sequence files are unchanged gzip-compressed copies;
recorded hashes apply to the decompressed bytes. Wolfram imports gzip directly.

[NCBI policies](https://www.ncbi.nlm.nih.gov/home/about/policies/) place no
restrictions on use or distribution of these data; submitters may claim rights.
Retain the original-study citations in the provenance records.

### PBMC3k selection

The [10x Genomics PBMC3k](https://www.10xgenomics.com/datasets/3-k-pbm-cs-from-a-healthy-donor-1-standard-1-1-0)
subset preserves Cell Ranger 1.1.0 filtered UMI counts for all 2,700 barcodes
and the union of:

- 300 genes with highest Pearson-residual variance after filtering cells to
  200–2,500 detected genes and <5% mitochondrial counts; overdispersion 100,
  clipping at ±√(retained cells).
- 15 marker genes and 13 `MT-` genes.
- 200 genes sampled with seed 20261104 from genes detected in at least three barcodes.

Metadata retain selection flags and source positions. Cell totals refer to
all 32,738 source genes. The source archive hash is retained in `Provenance`.

### Liver selection

`GSE11923-liver-subset.tsv.gz` retains all GPL1261 probes for 19 clock genes
plus 2,000 other probes sampled with seed 20261104, excluding Affymetrix controls.
Values are deposited MAS5 signals copied as text; blank symbols mean no
platform annotation. The paper's GCRMA preprocessing and rhythm-detection
pipeline are not reproduced.

### Regeneration

Run `make example-data` with internet access and curl 8.4 or later;
`BIODATALINK_CURL` selects an executable. Pinned hashes reject changed upstream
files. Rebuilds record a fresh retrieval time. The PBMC content test excludes
only `Provenance.RetrievedAt`; `BioDatasetLoad` still hashes actual file bytes.

## Synthetic expression examples

- `toy-expression.json`: invented counts, cell/gene IDs and condition labels.
- `toy-anndata.h5ad`: generated with AnnData 0.13.4; three observations, four
  variables, duplicate IDs, integer CSR `X`, a floating-point CSC `normalized`
  layer, and a five-variable `raw` matrix. Missing annotations and a nested `ID`
  test metadata preservation. Layer names make no scientific claims.

These fixtures describe no biological study; tests specify their expected values.
