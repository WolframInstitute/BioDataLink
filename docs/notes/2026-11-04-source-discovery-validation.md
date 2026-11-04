# Source discovery validation — 2026-11-04

This note records bounded checks of the local 0.2 implementation. Source
directory coverage, live metadata access, resolver routing and scientific data
import are distinct claims. These checks establish the first three for the
cases described; they do not validate every registry endpoint or import any
experimental data file.

## Local performance

Measurements used Wolfram Language 15.0.0 on Mac OS X ARM64 with 14 reported
processors. One fresh kernel loaded this checkout, then `AbsoluteTiming`
measured public calls and result construction. Each warm figure is the median
of 50 calls after the relevant data were cached. Kernel process startup,
notebook rendering and network access are excluded; the operating system's
file-cache state was not controlled.

Package registration and loading took 213.319 ms. The first
`BioDataSourceSearch[]` call took 148.549 ms, including registry reading,
validation and index construction, and returned 774 active records.

| Public call | Warm median |
| --- | --- |
| `BioDataSourceSearch[]` | 1.276 ms |
| `BioDataSourceSearch["gene", "Limit" -> 20]` | 0.479 ms |
| `BioDataSourceInfo["ensembl"]` | 0.014 ms |
| `BioDataURL[{"go", "GO:0008150"}]` | 0.031 ms |
| `BioDatasetSearch["CRISPR", "Limit" -> 5]` | 0.845 ms |

These are local observations, not service-latency promises or portable CI
thresholds. The complete measurements and ranges are retained in the
[performance evidence](evidence/2026-11-04-source-performance.json).

## Public metadata queries

One unauthenticated `"CRISPR"` query with `"PageSize" -> 2` was run per
provider, plus one BioStudies continuation, on 2026-11-04 at approximately
09:52 UTC. No scientific data files were requested.

| Operation | Returned accessions | Reported total | Exact? | Elapsed |
| --- | --- | --- | --- | --- |
| BioStudies first page | E-ERAD-186, E-ERAD-298 | 7028 | No | 2.762 s |
| BioStudies continuation | E-ERAD-335, E-ERAD-444 | 7026 | No | 0.830 s |
| GEO first page | GSE352671, GSE350646 | 12618 | Yes, at request time | 1.836 s |

BioStudies' estimate changed between consecutive pages. Continuation follows
the returned cursor rather than using a reported total as a stopping rule.
GEO used one search request and one batched summary request for its page.
The results verify small public metadata operations, not credentialed access,
complete search retrieval or scientific suitability of the matching studies.
See the [query evidence](evidence/2026-11-04-public-query-smoke.json).

## Resolver behavior and correction

Metadata-only GET checks did not follow redirects. The resolver returned HTTP
302 for `https://identifiers.org/go/GO:0008150`, pointing to the corresponding
Gene Ontology page, and for `https://identifiers.org/doi:10.1038/nature12373`,
pointing to the DOI resolver. Bare or encoded embedded identifiers failed in
the checked cases. See the [resolver evidence](evidence/2026-11-04-resolver-review.json).

The implementation therefore preserves the complete original identifier and
uses the namespace/full-identifier URI form when the namespace embeds its
prefix. It does not guess capitalization or require the original prefix to
equal the registry namespace, because valid systems can use alternative
prefixes. Colons and slashes remain literal. URI resolution remains supported
according to the [Identifiers.org migration documentation](https://docs.identifiers.org/pages/migration.html).

A successful redirect verifies routing for that checked identifier at that
time. It does not establish source availability for every accession, a data
license, scientific correctness or successful retrieval of a downstream file.

## Code and documentation checks

The final local verification passed 45 Wolfram Language tests and 17 Python
tests. Source checks found 16 kernel files and 7 public exports. These offline
checks cover implemented contracts and failure paths; they are separate from
the small live provider checks above.

The documentation build generated 14 documentation notebooks plus the resource
definition notebook. The paclet archive built successfully and passed a load
check in a fresh kernel. After visual review, a source-search caption was
corrected to describe substring matching across source descriptions; the
affected page was rebuilt and the archive again passed its fresh-kernel check.
An additional check of the extracted archive in an isolated fresh kernel
returned 774 active source records, 55 Pertpy records and
`https://identifiers.org/go/GO:0008150` for the full GO identifier. That check
used no credentials or live requests and confirms that the packaged assets
support these public operations.

Focused visual inspection covered the Data Sources guide, `BioDataURL`,
`BioDatasetQuery`, `BioDataSourceSearch`, and the Finding Biological Data
Sources tutorial. No Message cells appeared in those notebooks. Tables,
prose and identifier strings were readable; representative source tables and
resolver outputs were checked in light and dark appearances. Query properties,
options and credential-reference examples were also inspected. Online query
inputs remained unevaluated, with no fabricated saved results. This was a
representative visual review, not a claim that every notebook cell was rendered
in every appearance.
