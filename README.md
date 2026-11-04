# BioDataLink

[![CI](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/ci.yml)
[![Release](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml/badge.svg)](https://github.com/WolframInstitute/BioDataLink/actions/workflows/release.yml)

Biological data for Wolfram Language. Discover sources, search public studies,
download selected files and read supported measurements with their metadata.

[Documentation](https://www.wolframcloud.com/obj/wolframinstitute/BioDataLink/#guide/BioDataLink) ·
[Wolfram resource](https://www.wolframcloud.com/obj/wolframinstitute/DeployedResources/Paclet/WolframInstitute/BioDataLink/) ·
[Releases](https://github.com/WolframInstitute/BioDataLink/releases) ·
[Changelog](CHANGELOG.md)

## Installation

Requires Wolfram Language 15.0 or later.

```wl
PacletInstall[ResourceObject["https://wolfr.am/1IzdEvymT"]]
Needs["WolframInstitute`BioDataLink`"]
```

## Quick start

Find registered sources and construct an accession link:

```wl
BioDataSourceSearch["protein", "Limit" -> 5][All, {"Prefix", "Name"}]
BioDataURL[{"pdb", "1CRN"}]
```

Search public study metadata online:

```wl
page = BioDatasetQuery["GEO", "CRISPR AND Homo sapiens[Organism]", "PageSize" -> 3];
page["Records"][All, {"ID", "Title", "Organism"}]
```

## Development

Run `make all` for local checks and the paclet build. See
[CONTRIBUTING.md](CONTRIBUTING.md) for setup, optional backend tests and release
procedures.

## License and citation

The code is [MIT licensed](LICENSE). Bundled
[Identifiers.org metadata](BioDataLink/Assets/Sources/README.md) and
[UCI Iris measurements](BioDataLink/Assets/Examples/README.md) retain their
CC BY 4.0 attribution. Other datasets retain their own licenses and access terms.

Cite [BioDataLink](CITATION.cff) and the original data sources used in your work.
