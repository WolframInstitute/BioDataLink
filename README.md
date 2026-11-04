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

Install the latest release, then load the paclet:

```wl
PacletInstall["https://github.com/WolframInstitute/BioDataLink/releases/latest/download/WolframInstitute__BioDataLink.paclet"]
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

Explore **eleven worked tutorials**, seven guides and the function reference.
Each tutorial includes executable Wolfram Language examples; the computational
explorations use figures to explain the results.

[Function guide](docs/en/Guides/BioDataLink.md) ·
[Computational Explorations](docs/en/Guides/ComputationalExplorations/ComputationalExplorations.md)

### 1. Find and load data

- [Explore biological data](docs/en/Tutorials/ExploringBiologicalData.md) — Start with catalog records, measurements and provenance.
- [Find data sources](docs/en/Tutorials/FindingDataSources.md) — Discover repositories, resolve identifiers and search public studies.
- [Download biological data](docs/en/Tutorials/DownloadingBiologicalData.md) — Verify a file, inspect its variables and plot measurements.
- [Read AnnData selections](docs/en/Tutorials/ReadingAnnDataSlices.md) — Select cells, genes and layers while preserving aligned metadata.

### 2. Understand the measurements

- [Explore measurement geometry](docs/en/Tutorials/ExploringBiologicalDataGeometry.md) — Compare distances, projections and clusters as measurement scales change.
- [Understand sparse measurements](docs/en/Tutorials/UnderstandingSparseMeasurements.md) — Distinguish numerical zeros, missing observations and processing scales.
- [Build finite-state encodings](docs/en/Tutorials/DiscretizingBiologicalMeasurements.md) — Compare thresholds and rank bins, and examine the information lost.

### 3. Explore rules and choose experiments

- [Compare predictive rules](docs/en/Tutorials/ExploringSimplePredictiveRules.md) — Progress from constants to thresholds and AND/OR combinations; test held-out predictions.
- [Construct similarity networks](docs/en/Tutorials/ConstructingBiologicalSimilarityNetworks.md) — Build graphs and identify connections that survive changes in analysis choices.
- [Explore cellular-automaton hypotheses](docs/en/Tutorials/ExploringCellularAutomatonHypotheses.md) — Enumerate rules, enlarge neighborhoods and compare observable predictions.
- [Choose measurements to distinguish models](docs/en/Tutorials/ChoosingMeasurementsToDistinguishModels.md) — Move from one observable to measurement panels, then vary assumed error bounds.

Examples use attributed Iris measurements or clearly labeled synthetic data.
The rule explorations increase complexity step by step using built-in Wolfram
Language. Agreement with measurements alone does not establish a biological
mechanism.

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
