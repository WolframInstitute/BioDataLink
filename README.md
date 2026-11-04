# BioDataLink

[![CI](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml)

BioDataLink connects biological data to Wolfram Language. Find data sources,
search public studies, download selected files and read supported measurements
with their identifiers and provenance.

Requires Wolfram Language 15.0 or later.

[Documentation](docs/en/Guides/BioDataLink.md) ·
[Releases](https://github.com/WolframInstitute/BioDataLink/releases) ·
[Changelog](CHANGELOG.md)

## Get started

Install version 0.3.0 from its GitHub release, then load the paclet:

```wl
PacletInstall["https://github.com/WolframInstitute/BioDataLink/releases/download/v0.3.0/WolframInstitute__BioDataLink-0.3.0.paclet"]
Needs["WolframInstitute`BioDataLink`"]
```

Find registered sources and construct an identifier link. These calls use the
bundled directory and work offline:

```wl
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
BioDataSourceInfo["pdb"]
BioDataURL[{"pdb", "1CRN"}]
```

Browse the separate Pertpy catalog and inspect a loader's source information:

```wl
BioDatasetSearch["CRISPR", "Limit" -> 5][All, {"Provider", "ID", "Title"}]
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

Search public study metadata online, requesting a small page:

```wl
page = BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]",
    "PageSize" -> 3];
page["Records"][All, {"ID", "Title", "Organism"}]
```

Results include a continuation cursor and retrieval information. A study
search returns metadata; downloading its scientific data is a separate step.
The [source-discovery tutorial](docs/en/Tutorials/FindingDataSources.md)
shows pagination, source records and identifier conventions.

## Coverage

| Area | Functions | Available in 0.3.0 |
| --- | --- | --- |
| Sources | `BioDataSourceSearch`, `BioDataSourceInfo`, `BioDataURL` | Offline Identifiers.org directory and resolver links |
| Providers | `BioDatasetQuery` | Live, paginated public BioStudies studies and GEO Series |
| Catalog | `BioDatasetSearch`, `BioDatasetInfo` | Offline Pertpy loader metadata |
| Downloads | `BioDatasetDownload` | Explicit HTTPS downloads with byte limits and optional expected size and SHA-256 |
| DataAccess | `BioDatasetLoad` | Local BioDataLink JSON and optional selected H5AD matrices |

The directory contains 867 identifier namespaces, including 93 deprecated
namespaces, and 1,039 access endpoints. Search shows 774 active namespaces by
default. It spans biological and other domains and is not exhaustive. A source
listing or resolver link does not establish open access, current availability
or a supported data reader.

The 55 Pertpy records are loader entries, including processed variants and
examples, rather than 55 independent studies. Their metadata come from a pinned
source revision and have not been scientifically curated by BioDataLink.

Live queries support public metadata. An optional GEO API key can be supplied
by a named environment variable or system credential; it affects public request
quotas. Authenticated private-data access remains future work.

## Read measurements

Try the bundled synthetic expression example without external dependencies:

```wl
file = FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["Location"],
    "Assets", "Examples", "toy-expression.json"}];
data = BioDatasetLoad[File[file]];
Normal[data["ExpressionMatrix"]]
data["Provenance"]
```

The matrix is `{{3, 0}, {0, 5}, {2, 1}}`, with cells in rows and genes in
columns. Cell and gene metadata preserve that order. This JSON format treats
omitted entries as numerical zero; it cannot represent missing measurements.
Structural checks do not establish the biological meaning of the values.
See the [interchange format](docs/interchange-format.md).

Two capabilities have optional dependencies:

- **HTTPS downloads** require curl 8.4 or later. Choose a destination file and,
  when available, an expected size or SHA-256. The
  [download tutorial](docs/en/Tutorials/DownloadingBiologicalData.md) follows an
  attributed UCI Iris file through verification, units and computed figures.
- **H5AD reading** requires an explicitly configured Python interpreter with
  h5py and NumPy. The [AnnData tutorial](docs/en/Tutorials/ReadingAnnDataSlices.md)
  covers setup, selected rows and columns, layers, duplicate labels and missing
  annotations. It reads a supported matrix and aligned metadata, not a complete
  AnnData object. Normalization is not inferred and no full-file hash is computed.

BioDataLink does not install these dependencies automatically. Download limits,
matrix-selection limits and serialized-result limits serve different purposes;
none should be read as a bound on all process memory or decompressed storage.

## Documentation

The installed paclet includes reference pages, seven guides and eleven worked
tutorials. The [function guide](docs/en/Guides/BioDataLink.md) indexes the API;
the [Computational Explorations guide](docs/en/Guides/ComputationalExplorations/ComputationalExplorations.md)
connects computational choices to scientific questions.

A gradual reading path is:

1. Establish source identity and provenance with
   [exploring biological data](docs/en/Tutorials/ExploringBiologicalData.md),
   [finding sources](docs/en/Tutorials/FindingDataSources.md),
   [downloading files](docs/en/Tutorials/DownloadingBiologicalData.md) and
   [reading AnnData selections](docs/en/Tutorials/ReadingAnnDataSlices.md).
2. Examine [measurement geometry](docs/en/Tutorials/ExploringBiologicalDataGeometry.md),
   [sparse measurements](docs/en/Tutorials/UnderstandingSparseMeasurements.md)
   and [finite-state encodings](docs/en/Tutorials/DiscretizingBiologicalMeasurements.md).
3. Compare [predictive rules](docs/en/Tutorials/ExploringSimplePredictiveRules.md)
   from constants to individual thresholds and AND/OR combinations.
4. Build [similarity networks](docs/en/Tutorials/ConstructingBiologicalSimilarityNetworks.md)
   and test which connections survive analysis choices.
5. Compare [cellular-automaton hypotheses](docs/en/Tutorials/ExploringCellularAutomatonHypotheses.md)
   while increasing the specified neighborhood.
6. [Choose measurements to distinguish models](docs/en/Tutorials/ChoosingMeasurementsToDistinguishModels.md),
   progressing from one observable to panels and sensitivity to error bounds.

Figures are computed from attributed Iris measurements or clearly labeled
synthetic inputs. The progression adds explicit comparisons, neighborhood sites,
states and observation assumptions; it does not infer biological complexity
from rule numbers or graphs. These examples use built-in Wolfram Language and
do not require sibling modeling paclets.

## Development

From the repository root, load the source paclet:

```wl
PacletDirectoryLoad[FileNameJoin[{Directory[], "BioDataLink"}]]
Needs["WolframInstitute`BioDataLink`"]
```

| Command | Purpose |
| --- | --- |
| `make check` | Check metadata, sources and documentation |
| `make test` | Run offline Wolfram Language tests |
| `make python-tests` | Test repository automation |
| `make h5ad-tests` | Check the explicitly configured optional H5AD backend |
| `make download-tests` | Check downloads against a local HTTPS fixture |
| `make notebooks` | Build documentation with PacletPage |
| `make check-publish` | Build and check the paclet archive without publishing |

`make all` runs the core local checks and build. Optional-backend checks are
separate; ordinary tests and documentation examples do not contact providers.
See [CONTRIBUTING.md](CONTRIBUTING.md) for prerequisites and release procedures,
[GUIDE.md](GUIDE.md) for conventions and the [roadmap](ROADMAP.md) for planned
capabilities. Restart the Wolfram kernel after updating loaded paclet code or
bundled metadata, which are cached within a session.

## License and citation

The paclet code is [MIT licensed](LICENSE). The bundled
[Identifiers.org registry](BioDataLink/Assets/Sources/README.md) and
[UCI Iris measurements](BioDataLink/Assets/Examples/README.md) are CC BY 4.0,
with their attribution and provenance retained. Other datasets keep their own
licenses, citations and access terms.

Cite [BioDataLink](CITATION.cff) and the original data sources used in your work.
