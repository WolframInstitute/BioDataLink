# BioDataLink

[![CI](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml)

Find biological datasets, download files and read measurements with their
metadata in Wolfram Language.

[Documentation](https://www.wolframcloud.com/obj/wolframinstitute/BioDataLink/#guide/BioDataLink) ·
[Wolfram resource](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/BioDataLink/) ·
[Releases](https://github.com/WolframInstitute/BioDataLink/releases) ·
[Changelog](CHANGELOG.md)

## Installation

Requires Wolfram Language 15.0 or later:

```wl
PacletInstall[ResourceObject["https://wolfr.am/1IzdEvymT"]]
Needs["WolframInstitute`BioDataLink`"]
```

## Quick start

Find sources and build an accession link offline:

```wl
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
BioDataURL[{"pdb", "1CRN"}]
```

Search GEO studies online:

```wl
BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3]
```

Read the bundled counts for 2,700 human blood cells and 513 selected genes:

```wl
BioDatasetLoad[File[FileNameJoin[{PacletObject["WolframInstitute/BioDataLink"]["AssetLocation", "Examples"], "PBMC3k", "pbmc3k-subset.json"}]]]["ExpressionMatrix"]
```

The [computational essays](https://www.wolframcloud.com/obj/wolframinstitute/BioDataLink/#guide/ComputationalExplorations)
explore expression, structures, genomes, rhythms and measurement uncertainty.
Use the [visualization functions](https://www.wolframcloud.com/obj/wolframinstitute/BioDataLink/#guide/Visualizations)
with your own measurements.

## Development

Run `make all` for local validation. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License and citation

Code: [MIT](LICENSE). [Registry metadata](BioDataLink/Assets/Sources/README.md)
and [example data](BioDataLink/Assets/Examples/README.md) retain their own licenses.
Cite [BioDataLink](CITATION.cff) and the original data sources.
