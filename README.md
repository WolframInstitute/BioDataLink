# BioDataLink

A Wolfram Language paclet for discovering biological datasets and loading
supported data with their identifiers and provenance.

The long-term goal is access across biological domains, from sequences and
structures to expression, pathways, imaging and biodiversity. The current
implementation starts with Pertpy metadata and local expression matrices.

The initial development version is `WolframInstitute/BioDataLink` 0.1.0 and
requires Wolfram Language 15.0 or later. The bundled catalog contains 55 records
extracted from a fixed revision of Pertpy's data loaders. These are loader
entries, including processed variants and examples, rather than 55 independent
studies. Their descriptions are taken from the source and have not been
scientifically curated by BioDataLink. Search and metadata inspection run offline.
The first reader accepts local BioDataLink JSON version 1 files and returns
a sparse expression matrix with aligned cell and gene metadata.

Remote downloads, direct H5AD/AnnData conversion, and CELLxGENE/GEO access
are planned. A catalog record reports discovery coverage; it does not promise
that its source data can already be imported. No published paclet release is
required for the checkout workflow below.

## Use a checkout

From a Wolfram kernel, register the inner paclet directory:

```wolfram
PacletDirectoryLoad["/path/to/BioDataLink/BioDataLink"]
Needs["WolframInstitute`BioDataLink`"]
```

Browse the catalog and inspect a source record:

```wolfram
BioDatasetSearch["CRISPR", "Limit" -> 5]
BioDatasetInfo[{"Pertpy", "norman_2019"}]
```

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

## Organization

The kernel, tests, guides and reference pages share these areas:

| Area | Purpose |
| --- | --- |
| Catalog | Dataset discovery, metadata and source identity |
| DataAccess | Validated import of supported biological data formats |

The paclet has one context: `` WolframInstitute`BioDataLink` ``. Provider and
format helpers remain private.

## Documentation

- [BioDataLink guide source](docs/en/Guides/BioDataLink.md)
- [Catalog guide source](docs/en/Guides/Catalog/Catalog.md)
- [Data Access guide source](docs/en/Guides/DataAccess/DataAccess.md)
- [Exploring Biological Data tutorial source](docs/en/Tutorials/ExploringBiologicalData.md)
- [Design](docs/design.md), [provider contract](docs/provider-contract.md) and
  [build index](docs/build-index.md)

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

The contributor rules, review playbooks and documentation conventions use
[WolframInstitute/PureMath](https://github.com/WolframInstitute/PureMath/tree/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22)
from its `develop` branch as the preferred source. Initial CI/repository patterns come
from [WolframInstitute/Ruliology](https://github.com/WolframInstitute/Ruliology).
Thin entry points delegate builds, documentation and publishing to PacletPage.
See [AGENTS.md](AGENTS.md) and [GUIDE.md](GUIDE.md) for the biological-data
specialization and [the adaptation record](docs/conventions.md).

## Release status

This repository contains the initial paclet design and implementation. Release
and publishing workflows are provided for maintainers; no release or cloud
deployment is implied by their presence. Follow the release playbook and the
[roadmap](ROADMAP.md) before publishing.

## License

[MIT](LICENSE). Source datasets retain their own licenses, citations and terms.
