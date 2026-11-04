# Build index

The functions in this paclet and the contracts they implement. Update this
inventory when adding or changing a public symbol. Status records source
presence; it does not establish that tests passed or that notebooks were built,
evaluated or visually inspected. Record those checks separately.

## Functions

| Symbol | Area | Does | Sources | Status |
| --- | --- | --- | --- | --- |
| `BioDatasetInfo` | Catalog | returns a dataset record using its provider and source identifier | [Provider contract](provider-contract.md) | implementation + test/doc sources |
| `BioDatasetLoad` | DataAccess | validates and imports a local JSON expression dataset | [Interchange format](interchange-format.md) | implementation + test/doc sources |
| `BioDatasetSearch` | Catalog | searches the bundled metadata snapshot with provider and organism filters | [Design](design.md) | implementation + test/doc sources |