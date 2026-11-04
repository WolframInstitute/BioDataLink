# BioDataLink authoring guide

## Terms and scope

A **provider** exposes a source of biological data. A **study** can produce
several datasets, processed versions and data files. A **catalog record**
describes the entity named by its provider-specific identifier; that entity
may be a study, dataset, loader or file. An **accession** is an identifier
assigned by a repository. Pertpy loader names are not repository accessions.
An **import** interprets bytes as a documented data representation. A record
being searchable does not establish that its files were downloaded, its
scientific annotations reviewed or its matrix interpretation verified.

The initial shared representation is single-cell expression data. Provider
adapters may support different capabilities; report those capabilities
explicitly. Keep requested discovery, download, import and analysis operations
separate in the API. Loading the package must not fetch biological data.

The preferred source is the PureMath `develop` branch at commit
`e2dacfa90c526c3bc9902ef7fa24d29932fb3b22`, read without changing its working
checkout. Its [general guide](https://github.com/WolframInstitute/PureMath/blob/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22/GUIDE.md),
project-specific review rules and task playbooks supply the interface,
integration, reproduction and documentation conventions adapted here.
The initial build and authoring setup also draws on
[Ruliology](https://github.com/WolframInstitute/Ruliology) commit
`41d7a9d6f4a2edc20fe3048b0739c9bb2b43100d`.

BioDataLink keeps its documented command names, four-space indentation and
local notebook build workflow. PureMath's mathematics taxonomy, dev-pod setup,
mandatory review branch sequence and external issue-posting steps do not apply
here. Its useful checks are adapted to biological data contracts and the
user's authorized scope.

## Dataset contracts

Before implementing an adapter, state its catalog identifiers, supported
operations, source API or file format, version policy and failure behavior.
Record source documentation and evidence in `docs/design.md` or a focused
record under `docs/notes/` when a decision spans symbols. Keep a provider's published claims separate from local checks.

For matrices, document and validate:

- Axis order and the identifiers attached to each axis.
- Shape, numeric type, sparse encoding, and the distinction between numerical
  zero and an unmeasured or unknown value.
- Whether values are counts, normalized expression, logarithms, or another
  measurement; preserve the relevant layer and transformations.
- Gene identifier namespace, organism and reference assembly when available.
- Missing annotations, duplicate identifiers and source-specific fields.

Use stable source identifiers for joins. A display gene symbol is not a
universal unique key. Do not silently reorder cells or genes, drop duplicate
identifiers, combine assays, normalize values, or replace missing values with
zero. Expose an intentional transformation and retain its provenance.

BioDataLink JSON version 1 treats every omitted matrix coordinate as zero and
cannot preserve a missing-measurement mask. Do not imply that successful import
establishes biological validity: integer checks do not establish read versus
molecule counts or preprocessing, unique IDs do not establish cell type or
gene-reference correctness, and required provenance strings remain declarations
from the source. An observed zero count does not prove biological absence.

A dataset object should preserve source accession, source release or revision,
retrieval time, exact file location, available checksum, and citation. Record
unknown values as `Missing` where the contract permits. A locally computed
checksum records downloaded bytes; distinguish it from a checksum supplied by
the source. Preserve source license information and original-study citations.
The software's MIT license does not relicense downloaded datasets.

## Public interfaces

Settle the input forms, result, and first ordinary example before writing code.
Check existing behavior in Wolfram Language, the Function Repository and this
paclet, then check the proposed symbol for a System name collision in the
target kernel. Record the kernel version used. A new exported symbol should
answer a recognizable research task rather than expose an internal helper.

Use clear UpperCamelCase names and documented string properties. Keep provider
selection and dataset identifiers explicit. Return `Dataset` for tabular
metadata, `Association` for structured records, and `SparseArray` for sparse
matrices when materializing in Wolfram Language. Use a documented external
handle for data that stays in a backend; accessing it must not silently
materialize an entire large matrix.

Write usage messages with signature first and one input form per line. Keep
usage, reference pages, implemented patterns and options consistent. Declare
which provider capabilities are available now. Proposed symbols belong in
design records until they work and have tests.

### Scope and representation guards

A validator must accept the same supported representations as the operations
it guards. Match the assumptions required by the algorithm: matrix orientation,
counts versus normalized values, supported schema, and unique identifier rules.
Test each boundary explicitly. A wrong-shaped input left unevaluated and an
attempted import returning `Failure` are different outcomes and need different
checks. A data-quality question that cannot be decided from available metadata
must retain that uncertainty.

Before adding properties, check whether a standard Wolfram operation already
answers the task on the returned representation. Preserve standard `Dataset`,
`Association` and `SparseArray` behavior. Add a custom accessor only when it
exposes genuinely different data or lifecycle semantics.

### Failures and missing data

Keep unsupported inputs distinguishable from a valid empty query result.
Use specific patterns for supported forms; do not return a plausible partial
result for a malformed identifier. A computation that starts but fails returns
a `Failure` carrying useful cause and context. A timeout, inaccessible source,
checksum mismatch or unavailable Python dependency must not become an empty
catalog or an empty expression matrix.

Use `Missing` for absent metadata under a documented contract. Preserve the
difference between absent metadata and a backend failure. Avoid exposing
credentials, tokens, or sensitive local paths in failure details.

## Wolfram Language code

### Definitions and evaluation

Feature files have sections for package declarations, usage messages and
function definitions. Use four-space indentation, LF endings and UTF-8.
Prefer documented public built-ins. New dependencies on private kernel
internals need a specific reason and a version check.

Use `Module` for local work, `With` for fixed bindings and `Block` for intentional
dynamic scope. Localize all working symbols. Check attributes before using a
built-in as symbolic notation. Avoid private symbols leaking into public data.
Use delayed definitions when work must happen for each call, and test
intersections between overlapping patterns.

Keep shared area helpers in `Helpers.wl` with `PackageScoped`. Loading the
public context supplies them; `PackageScope` is not a package to load with
`Needs`. Use `Lookup` for record fields and named `Function` arguments where
nested slots would be unclear.

### Options

Declare actual defaults once in `Options[f]`, consume them through
`OptionsPattern[]` and `OptionValue`, and explain what `Automatic` means.
Validate option values before network or filesystem work. Preserve explicit
caller settings and `SetOptions` changes. For forwarded options, use
`FilterRules[Flatten[{opts, Options[f]}], Options[inner]]`: caller rules precede
fallback defaults because the first duplicate setting wins.

Use native visualization defaults, including `ImageSize -> Automatic` when
supported. Preserve colors that encode biological categories across subsets.
Resource limits and cache controls are computational options, not display
preferences. Follow the [options playbook](.agent-skills/wolfram-kernel-options/SKILL.md)
when changing these behaviors.

### Cost and backend boundaries

Check cheap shape and option conditions before expensive work. Preserve
sparsity, request provider-side subsets where supported, and record when a
provider requires a full download before local slicing. A maximum returned
cell count must not be presented as a network-byte limit.

Keep Python environments explicit and reproducible. Prefer a thin adapter that
returns documented values over exposing arbitrary Python evaluation. Transfer
large data in bounded chunks or through files/handles, and check dimension and
identifier alignment at the language boundary. Pin tested dependency versions
without treating every newer version as supported.

Cache keys must distinguish provider, dataset revision and relevant query
parameters. Validate downloaded content before promoting it to the cache;
write through temporary files so an interrupted download cannot appear valid.
Cache reads must not bypass checksum or schema checks promised by the API.
Do not make ordinary searches erase or mutate cached datasets.

Bound network requests, paginate explicitly, and handle provider rate limits.
Retry transient failures within a declared limit. Do not retry authentication
errors or corrupt data indefinitely. Use the original source's API rather than
scraping a human page when it offers the required capability.

### Optional library lifecycle

An installed package is ready only after its required runtime, modules and a
small representative operation work. Readiness checks must not download or
install anything. Loading BioDataLink must succeed without optional libraries;
install/update is an explicit operation, separate from method dispatch.

Reuse owned sessions per Wolfram kernel and preserve caller-supplied sessions.
Clean up temporary objects on success and failure with `WithCleanup` when
appropriate. Invalidate session-bound handles and caches on restart; do not
share them across parallel kernels. Distinguish missing installation, failed
connection, incompatible version, conversion failure and provider failure.

Where multiple methods exist, document explicit method behavior. A requested
external method must report inability to run; automatic fallback is valid only
when it preserves the promised result. Record which method actually ran.
Measure the public operation including conversion, separating startup from
repeated calls, before selecting an automatic performance policy. CI checks
method selection and correctness, not machine-specific timing thresholds.

## Tests and evidence

Default tests run offline with small, explicit fixtures. Keep live-provider
checks opt-in and clearly report what they verify. A source catalog check is
not an end-to-end import check. Build dependency downloads are separate from
provider tests and must be reported when relevant.

Use descriptive `TestID` values. Test public behavior with independently
specified expected data, not values computed through the function under test.
For conversion, use a small asymmetric matrix with named axes, zeros and
missing metadata so transposition and alignment errors are visible. A round
trip complements a known value; two inverse functions can share one mistake.

Test applicable boundaries: no matches, unknown accession, unsupported
capability, empty subset, malformed source data, missing optional dependency,
checksum mismatch and interrupted cache writes. Check explicit option overrides
and `SetOptions` only for options the feature consumes. Avoid tests that merely
match prose or mirror implementation details.

Run tests in a fresh kernel loaded from this checkout. A parse error, timeout,
unexpected message or zero executed tests is a failed or incomplete check.
Keep fixtures small and provenance clear. Synthetic data must be labeled
synthetic; a tiny derived fixture must identify its source and transformation.
Treat cells from one biological sample as nested observations in analysis
examples; resampling cells alone does not create biological replication.

## Reviews and reproduction evidence

For supplied review notes, retain the source's issue status and reasoning
separately from the current-code verdict. Record rejected alternatives as well
as chosen designs. Attribute reusable rules by review date and issue identifier;
keep names and short quotations in the review record. Resolve routine details
within the existing contract and user request; ask about material unresolved
choices while continuing independent work.

A review finding closes with evidence for the reported behavior. Track fixed,
already fixed, deferred, outside this repository and unresolved outcomes.
Check whether a reusable lesson duplicates, refines or conflicts with an
existing rule before changing the guide. Preserve one shared statement of the
rule and point task skills to it. Scope a wider sweep separately from the
specific fix and preserve user changes in the shared checkout.

For a published-result reproduction, register the claim, source locus,
qualifiers, input dataset and expected comparison before computing. Preserve
organism, assay, sampling unit, normalization, population and uncertainty
assumptions. Separate access validation, reproduced measurement, method
agreement and biological inference. A shared source construction or shared
processed matrix is not an independent validation route.

Use the [reproduction playbook](.agent-skills/reproduce-published-paper/SKILL.md)
and its templates for a durable case record. A returned value that disagrees
requires checking data revisions, preprocessing and conventions before calling
it a software defect. Missing data or a missing adapter is a blocked route;
no supported analysis is uncovered; timeouts and unresolved ambiguity are
inconclusive. Report each outcome rather than counting skips as passes.

## Documentation

### Page roles and navigation

Guide pages organize tasks. Reference pages define exact signatures, supported
providers, return forms, properties, options and limits. Tutorials complete a
small workflow with interpreted results. Keep long implementation decisions
in `docs/design.md` or `docs/notes/` rather than user-facing pages.

Use Markdown sources under `docs/en/` and the converter's `Guide`, `Symbol`
and `TechNote` templates. Each page needs consistent `Name`, `Context`, `Paclet`
and `URI` metadata. Names must be unique within a page type because generated
notebook filenames are flat. A rename updates the filename, metadata, URI and
incoming links together.

Every guide must be reachable from the BioDataLink hub. Keep related-guide and
tutorial lists alphabetical, with `$` names last. Within a guide section, list
paclet symbols first and then external built-ins or Function Repository
functions, sorted within each group. Mark external links WL and WFR and explain
those labels. Use the destination's readable title for related pages and one
link per entry. Label worked tutorial links Applications in rendered pages.

### Reference pages

Start with actual usage forms; omit generic `opts` placeholders. Define
arguments and properties in Details & Options. State defaults and the meaning
of `Automatic`; explain matrix axes and data processing status where relevant.
Use headerless documentation tables (an empty Markdown header row) for accepted
forms, named properties and options. Keep argument placeholders italicized,
and literal Wolfram syntax in code formatting.

Start examples with the smallest useful call and show its returned data or a
useful view. Put input variations in Scope, non-default choices in Options,
comparisons in Properties and Relations, and expected limits in Possible
Issues. Cover meaningful behavior rather than aiming for a fixed example count.

### Reproducible examples

Use local fixtures for examples evaluated during ordinary documentation builds.
Show online examples explicitly as online operations, with data sizes, required
backend and dataset revision when known. The build must not download large
biological datasets to render a page. Preserve a data example's organism,
source identifiers, preprocessing, gene selection, sample selection and seed.

Show an operation's actual return value at least once before a downstream
reduction. A numeric count or a truth value supports a demonstration but cannot
replace the dataset, record or matrix being introduced. Keep one observation
per input cell and avoid bundling unrelated outputs in a list.

Reference examples stand alone after loading the context. Headings and thematic
breaks may reset bindings in the converter; start each independent example
with its own data. Tutorials thread the running example through document order under the direct
PacletPage build. Put necessary setup before its first use and keep data
selection visible. Name bindings clearly and re-show relevant data when a
reader enters a later section. Do not assume a final initialization section
is executed early unless the configured converter explicitly supports it.

Compute figures from the example. Use labeled heatmaps or distributions when
they explain expression data, and compact tables for metadata. Preserve scales
and category colors across comparisons. Inspect axes, labels and missing-data
representations; a visually plausible matrix plot does not prove orientation.
Avoid fixed styling in each example unless it conveys information or fixes a
specific readability issue. A synthetic example demonstrates software behavior,
not a biological conclusion.

### Documentation verification

Run examples in a fresh kernel resolving to this checkout. Build notebooks
with `make notebooks`, inspect actual outputs and layout, and check the
relevant links. A successful Markdown check is not evidence of evaluated
examples or rendered notebooks. Inspect representative visual output in light and dark notebook appearances
when formatting changes. Check that counts, legends and prose agree with the
saved result. Report unavailable front-end or build tools
and avoid calling the page visually verified when inspection was not possible.

Check independent copied inputs as well as a whole-page run. Ensure examples
use public symbols and match their documented version. Recheck affected pages
after changing a shared data contract or formatting helper. Keep comparison
claims within the datasets, measurements and evidence actually examined.
