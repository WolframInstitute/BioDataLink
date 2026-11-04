# Build index

All eight functions below have implementation, test and documentation sources.
This inventory does not assert that a particular checkout passed runtime or
rendering checks; record validation separately.

## Functions

| Symbol | Task | Contract |
| --- | --- | --- |
| `BioDataSourceInfo` | Inspect namespace metadata and provenance | [Design](design.md) |
| `BioDataSourceSearch` | Search the offline source directory | [Design](design.md) |
| `BioDataURL` | Construct a resolver link offline | [Validation](notes/2026-11-04-source-discovery-validation.md) |
| `BioDatasetDownload` | Download and check an HTTPS file | [Provider contract](provider-contract.md) |
| `BioDatasetInfo` | Inspect one catalog record | [Provider contract](provider-contract.md) |
| `BioDatasetLoad` | Read JSON or a selected H5AD matrix | [JSON](interchange-format.md), [H5AD](en/Tutorials/ReadingAnnDataSlices.md) |
| `BioDatasetQuery` | Search BioStudies or GEO online | [Provider contract](provider-contract.md) |
| `BioDatasetSearch` | Search the offline Pertpy catalog | [Design](design.md) |
