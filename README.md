# BioDataLink

A Wolfram Language paclet for discovering biological datasets and loading
supported data with their identifiers and provenance.

The goal is access across biological domains, from sequences and structures to
expression, pathways, imaging and biodiversity. Version 0.3 adds bounded HTTPS
file downloads and optional selected H5AD reading to source discovery, public
study queries and local JSON expression data.

The local development version is `WolframInstitute/BioDataLink` 0.3.0 and
requires Wolfram Language 15.0 or later. The bundled Identifiers.org directory
contains 867 identifier namespaces, including 93 deprecated namespaces, and
1,039 access endpoints. This is a nonexhaustive directory across biological and
other domains; inclusion does not establish open access or a working data reader.
Source discovery and identifier-link construction run offline. Live public
metadata queries are available for BioStudies studies and GEO Series.

The separate Pertpy catalog contains 55 records extracted from a fixed revision
of its data loaders. These are loader
entries, including processed variants and examples, rather than 55 independent
studies. Their descriptions are taken from the source and have not been
scientifically curated by BioDataLink. Search and metadata inspection run offline.
The first reader accepts local BioDataLink JSON version 1 files and returns
a sparse expression matrix with aligned cell and gene metadata.

An explicit download can verify expected size and SHA-256 before placing a
file at a chosen path. H5AD reading selects one supported matrix and aligned
metadata, using an explicitly configured Python interpreter. It is not a
complete AnnData-object import. Additional source APIs and authenticated
private-data access remain future work. No published release is required for
the checkout workflow below.

## Use a checkout

From a Wolfram kernel, register the inner paclet directory:

```wolfram
PacletDirectoryLoad["/path/to/BioDataLink/BioDataLink"]
Needs["WolframInstitute`BioDataLink`"]
```

Find sources and construct a link without a network request:

```wolfram
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
BioDataSourceInfo["pdb"]
BioDataURL[{"pdb", "1CRN"}]
```

Search public study metadata online, requesting a small page:

```wolfram
BioDatasetQuery["BioStudies", "CRISPR", "PageSize" -> 3]
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

Queries return records, source-reported totals, a continuation cursor and
retrieval information. They do not download the study's scientific data files.
GEO accepts an optional API-key reference to an environment variable or system
credential. That key affects public request limits; private-data access remains
a future source-specific capability.

Browse the bundled Pertpy catalog and inspect a loader record:

```wolfram
BioDatasetSearch["CRISPR", "Limit" -> 5]
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

Download an explicitly chosen HTTPS file online, pinning the checked example's
size and content hash. This requires curl 8.4 or later:

```wolfram
download = BioDatasetDownload[
    "https://archive.ics.uci.edu/ml/machine-learning-databases/iris/iris.data",
    File[FileNameJoin[{CreateDirectory[], "iris.csv"}]],
    "MaxFileBytes" -> 10000, "ExpectedByteCount" -> 4551,
    "ExpectedSHA256" ->
        "6f608b71a7317216319b4d27b4d9bc84e6abd734eda7872b71a458569e2656c0"]
```

The hash pins the UCI file checked for this example; UCI did not publish that
SHA-256 value. The [worked download tutorial](docs/en/Tutorials/DownloadingBiologicalData.md)
retains attribution, assigns measurement units and plots a bundled copy offline.

Load a local interchange file:

```wolfram
data = BioDatasetLoad[File["/path/to/expression.json"]];
data["CellMetadata"]
data["GeneMetadata"]
data["ExpressionMatrix"]
data["Provenance"]
```

Rows of the expression matrix correspond to cells; columns correspond to genes.
Metadata retain the same order. The reader validates dimensions, identifiers
and sparse entries before returning data. The [interchange format](docs/interchange-format.md)
defines the file schema and gives a small synthetic example.

The local format treats every omitted matrix entry as numerical zero; it cannot
represent an unmeasured or unknown value. The declared measurement scale and
source information must therefore be checked before scientific analysis.
Loading a file checks its structure, not its biological interpretation or the
appropriateness of comparing its values.

After [configuring the optional H5AD reader](docs/en/Tutorials/ReadingAnnDataSlices.md),
read a selected local matrix with an explicit interpreter path:

```wolfram
slice = BioDatasetLoad[File["/path/to/data.h5ad"], "Format" -> "AnnData",
    "PythonExecutable" -> "/path/to/environment/bin/python",
    "Cells" -> {1, 2}, "Genes" -> {1, 2, 3}, "MaxFileBytes" -> Infinity]
```

H5AD results preserve source positions, repeated labels, missing annotations
and the chosen layer. They list omitted structures and leave normalization
unspecified. The reader does not compute a full-file checksum, install Python
packages, or silently materialize every AnnData component. Matrix-selection
and serialized-result limits remain in effect when the file-size limit is lifted.

## Organization

The kernel, tests, guides and reference pages share these areas:

| Area | Purpose |
| --- | --- |
| Sources | Registered identifier systems, source descriptions and resolver links |
| Providers | Live public study metadata queries |
| Catalog | Dataset discovery, metadata and source identity |
| Downloads | Explicit HTTPS transfers with size and checksum checks |
| DataAccess | Validated import of supported biological data formats |

The paclet has one context: `` WolframInstitute`BioDataLink` ``. Provider and
format helpers remain private.

## Documentation

- [BioDataLink guide source](docs/en/Guides/BioDataLink.md)
- [Catalog guide source](docs/en/Guides/Catalog/Catalog.md)
- [Computational Explorations guide source](docs/en/Guides/ComputationalExplorations/ComputationalExplorations.md)
- [Data Access guide source](docs/en/Guides/DataAccess/DataAccess.md)
- [Data File Downloads guide source](docs/en/Guides/Downloads/Downloads.md)
- [Data Sources guide source](docs/en/Guides/Sources/Sources.md)
- [Online Study Search guide source](docs/en/Guides/Providers/Providers.md)
- [Constructing Biological Similarity Networks tutorial source](docs/en/Tutorials/ConstructingBiologicalSimilarityNetworks.md)
- [Discretizing Biological Measurements tutorial source](docs/en/Tutorials/DiscretizingBiologicalMeasurements.md)
- [Downloading and Inspecting Biological Data tutorial source](docs/en/Tutorials/DownloadingBiologicalData.md)
- [Exploring Biological Data tutorial source](docs/en/Tutorials/ExploringBiologicalData.md)
- [Exploring the Geometry of Biological Measurements tutorial source](docs/en/Tutorials/ExploringBiologicalDataGeometry.md)
- [Exploring Cellular Automaton Hypotheses tutorial source](docs/en/Tutorials/ExploringCellularAutomatonHypotheses.md)
- [Exploring Simple Predictive Rules tutorial source](docs/en/Tutorials/ExploringSimplePredictiveRules.md)
- [Finding Biological Data Sources tutorial source](docs/en/Tutorials/FindingDataSources.md)
- [Reading Selected AnnData Measurements tutorial source](docs/en/Tutorials/ReadingAnnDataSlices.md)
- [Understanding Sparse Measurements tutorial source](docs/en/Tutorials/UnderstandingSparseMeasurements.md)
- [Design](docs/design.md), [provider contract](docs/provider-contract.md) and
  [build index](docs/build-index.md)

The computational tutorials use actual attributed Iris measurements or clearly
labeled synthetic matrices. They connect access to scaling, clustering, finite
representations, rule search, network sensitivity and explicit observation
models. Figures are computed from the displayed inputs. The examples use
built-in Wolfram Language; sibling Ruliology and Ruliobiology paclets are not
required.

These links lead to Markdown sources. `make notebooks` builds paclet
documentation notebooks; build and visual inspection are separate checks.

## Development

Run `make help` for available commands. The main checks are:

```sh
make check
make test
make lint-docs
make notebooks
make check-publish
```

`make all` runs the local CI checks. Core tests and documentation examples use
bundled metadata and small local fixtures. Live provider tests must be explicit.
See [CONTRIBUTING.md](CONTRIBUTING.md) for scope-based checks and environment setup.

Successful registry and catalog loads are cached within each Wolfram kernel
session. Prefix lookup and search text are prepared once. After explicitly
updating a bundled source file, restart the kernel to read the new copy. Live
queries use pagination, and GEO retrieves summaries in batches per page.

The contributor rules, review playbooks and documentation conventions use
[WolframInstitute/PureMath](https://github.com/WolframInstitute/PureMath/tree/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22)
from its `develop` branch as the preferred source. Initial CI/repository patterns come
from [WolframInstitute/Ruliology](https://github.com/WolframInstitute/Ruliology).
Thin entry points delegate builds, documentation and publishing to PacletPage.
See [AGENTS.md](AGENTS.md) and [GUIDE.md](GUIDE.md) for the biological-data
specialization and [the adaptation record](docs/conventions.md).

## Release status

This repository contains a local development implementation. Release
and publishing workflows are provided for maintainers; no release or cloud
deployment is implied by their presence. Follow the release playbook and the
[roadmap](ROADMAP.md) before publishing.

## License

[MIT](LICENSE) for the paclet code. The bundled Identifiers.org registry is
[CC BY 4.0](https://docs.identifiers.org/pages/terms_of_use.html), with
[attribution and transformation details](BioDataLink/Assets/Sources/README.md).
The bundled [UCI Iris example](BioDataLink/Assets/Examples/README.md) is also
CC BY 4.0 and retains its citation and exact retrieved bytes.
Other source datasets retain their own licenses, citations and terms.
