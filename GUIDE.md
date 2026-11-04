# BioDataLink authoring guide

## Terms and scope

A **provider** exposes data; a **study** may produce several datasets and files.
A **catalog record** describes a provider-specific study, dataset, loader or
file. An **accession** is repository-assigned; Pertpy loader names are not
accessions. An **import** interprets bytes under a documented representation.
Keep discovery, download, import and scientific validation distinct.

The initial shared representation is single-cell expression. Other providers
must declare their capabilities. Loading the package stays offline.

Conventions derive from [PureMath develop at e2dacfa](https://github.com/WolframInstitute/PureMath/blob/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22/GUIDE.md),
with initial tooling from [Ruliology](https://github.com/WolframInstitute/Ruliology)
at `41d7a9d6f4a2edc20fe3048b0739c9bb2b43100d`. Source checkouts remain unchanged.
BioDataLink keeps its commands, four-space indentation and notebook workflow.
PureMath's taxonomy, dev pods, mandatory branch sequence and external issue
posting do not apply; follow the user's authorized scope.

## Dataset contracts

Before implementing an adapter, record identifiers, supported operations,
source API/format, version policy and failures in `docs/design.md` or `docs/notes/`.
Separate provider claims from local checks. Validate and document:

- Axis order, shape, numeric type, sparsity and aligned identifiers.
- Zero versus unmeasured values, missing annotations and duplicate labels.
- Counts, normalization, layer, units and transformations.
- Gene namespace, organism and reference assembly when supplied.
- Accession, revision, retrieval time, file identity, citation and license.

Use stable source IDs for joins. Do not silently reorder, collapse duplicates,
combine assays, normalize or zero-fill missing measurements. Record deliberate
transformations and selections. JSON version 1 has no missing-measurement mask.
Integer counts do not establish reads versus molecules; unique IDs do not
validate biological annotations. Keep unknown metadata as `Missing` where allowed.

Distinguish computed hashes from source-supplied checksums and preserve both.
The software's MIT license does not relicense datasets.

## Public interfaces

Define input forms, result and a useful first example before implementation.
Check existing paclet, Wolfram Language and Function Repository behavior and
System-name collisions in the target kernel. New exports must serve a research
task with a clear functional difference from existing tools.

Use UpperCamelCase names, explicit providers/IDs and documented string properties.
Return `Dataset` for tables, `Association` for records and `SparseArray` for
sparse matrices. External handles must disclose lifecycle and materialization.
Keep usage, implemented patterns, options and reference pages consistent;
proposed APIs belong in the roadmap until implemented and tested.

### Scope and representation guards

Validators must accept the representations their operations support and enforce
actual assumptions: axes, shape, scale, schema and ID rules. Test boundaries.
Distinguish an unsupported form left unevaluated from an attempted operation
returning `Failure`. Preserve uncertainty that metadata cannot resolve.
Use standard operations on returned Wolfram objects before adding accessors.

### Failures and missing data

Malformed identifiers and backend failures must not produce plausible partial
results or successful empty searches. Use specific supported patterns and
structured `Failure` causes. Keep absent metadata distinct from operational
failure. Exclude credentials, tokens and sensitive paths from diagnostics.

## Wolfram Language code

### Definitions and evaluation

Use UTF-8, LF endings, four-space indentation and sections for declarations,
usage and definitions. Prefer public built-ins; private kernel dependencies
need a reason and version check. Localize work with `Module`, fixed bindings
with `With`, and deliberate dynamic scope with `Block`. Check attributes and
overlapping patterns; keep private symbols out of results.

Declare shared helpers with `PackageScoped` in area `Helpers.wl`. Loading the
public context supplies them; do not load `PackageScope` with `Needs`.
Use `Lookup` and named arguments when nested slots obscure meaning.

### Options

Define defaults once in `Options[f]`; use `OptionsPattern[]` and `OptionValue`.
Explain `Automatic` and validate settings before I/O. Preserve caller overrides
and `SetOptions`. Forward options with
`FilterRules[Flatten[{opts, Options[f]}], Options[inner]]`: first matching rules win.

Use native display defaults, including `ImageSize -> Automatic` when supported.
Keep category colors consistent. Resource limits are separate from styling.
Follow the [options playbook](.agent-skills/wolfram-kernel-options/SKILL.md).

### Cost and backend boundaries

Validate cheaply before expensive work. Preserve sparsity and request remote
subsets where supported; disclose full downloads before local filtering.
Bound and paginate requests, batch summaries, respect rate limits and prefer
official APIs. Bound retries; do not repeatedly retry bad credentials or data.

Keep Python environments explicit and pinned. Use thin adapters and bounded
transfers or handles; check dimensions and identifiers at language boundaries.
Newer dependency versions are untested until checked. Cache keys must include
provider, revision and relevant query choices. Validate before atomic placement;
cache hits must retain promised checks. Searches must not erase data caches.

### Optional library lifecycle

Readiness requires a working runtime, modules and a representative operation.
Checks install or download nothing. Core loading must work without optional
libraries; setup and method dispatch stay separate.

Reuse owned sessions, preserve caller sessions and clean temporary objects on
success and failure. Restart invalidates session handles and caches; never
share them across parallel kernels. Distinguish installation, connection,
version, conversion and provider failures.

Explicit methods must report inability to run. Automatic fallback must preserve
the contract and record the method used. Measure public operations including
conversion, separating startup and repeated calls. Test correctness and method
selection in CI, not hardware-specific timing thresholds.

## Tests and evidence

Default tests use small offline fixtures. Live-provider checks and build-tool
downloads are separate evidence. Use descriptive `TestID` values and independent
expected results; a round trip can share an error in both directions.
Conversion fixtures should expose transposition, zeros, missing metadata and
axis alignment with an asymmetric named matrix.

Cover relevant empty results, unknown IDs, unsupported capabilities, malformed
data, missing dependencies, checksum failures and interrupted writes. Test
consumed option overrides; avoid assertions that merely mirror implementation
or prose. A parse error, timeout, unexpected message or zero tests is not a pass.

Use a fresh kernel resolving to this checkout. Label synthetic fixtures and
document derived selections. Cells from one sample are nested observations,
not independent biological replicates.

## Reviews and reproduction evidence

Keep source review status and reasoning separate from the current-code verdict,
chosen action and evidence. Record rejected alternatives and attribute reusable
lessons by date/issue. Resolve routine choices within authorization; ask only
about material uncertainty. Preserve user edits and scope wider work separately.

Close findings with evidence for the reported behavior. Distinguish fixed,
already fixed, deferred, outside-repository and unresolved outcomes. Keep each
shared rule here once; skills link to it.

For [reproduction work](.agent-skills/reproduce-published-paper/SKILL.md), register
the exact claim, qualifiers, dataset, preprocessing, sampling unit and expected
comparison before computing. Separate access validation, reproduced values,
method agreement and biological inference. Shared input construction is not
independent validation. Check revisions and conventions before reporting a
defect. Missing data/adapters are blocked routes; no supported analysis is
uncovered; timeouts or ambiguity are inconclusive. Do not count skips as passes.

## Documentation

### Page roles and navigation

Write for scientists who know biology but not BioDataLink. Lead with the task,
then the minimum workflow and its interpretation. Define unfamiliar terms once.
Keep selection, units, scale, provenance and material limitations; remove repeated
warnings, extended theory and secondary analyses. Link to a canonical page
instead of repeating setup or contracts. Keep tutorials focused on one question.

Guides organize tasks; references define APIs; tutorials show a complete workflow.
README covers installation, quickstart and top links. Put implementation decisions
in design notes and future APIs in the roadmap.

Use Markdown `Guide`, `Symbol` and `TechNote` templates with consistent Name,
Context, Paclet and URI. Names are unique within a type. Renames update filenames,
metadata and incoming links. Every guide must be reachable from the hub.
Alphabetize guides, tutorials and symbols, with `$` names last. Put paclet exports
before external functions and label the latter WL/WFR. Use destination titles
and one link per entry. Render worked tutorial links as Applications.

### Reference pages

Use [CellularAutomaton](https://reference.wolfram.com/language/ref/CellularAutomaton.html)
and [FileHash](https://reference.wolfram.com/language/ref/FileHash.html) as style
references. Give each supported signature a short usage sentence. Put argument
forms, properties and defaults in compact notes and headerless tables under
Details, or Details & Options when options exist. Use italic placeholders and
code formatting for literal syntax; omit generic `opts`.

Start Basic Examples with a small useful result. Use short captions ending in
a colon, followed by input and evaluated output. Each example demonstrates one
operation; related inputs can share visible setup within the same group.
Use Scope, Options, Applications, Properties & Relations and Possible Issues
only for distinct content. Separate independent examples with `---`; each group
must run after context loading. Keep longer workflows in tutorials.

Guide abstracts should be one short paragraph followed by grouped function
links with brief descriptions. Keep detailed contracts in symbol references.
Tutorials use short step captions, visible inputs and outputs, with scientific
interpretation next to the relevant result.

### Reproducible examples

Locate fixtures with the `"Examples"` asset and `FileNameJoin`. Asset aliases
must not overlap. Ordinary builds use local data. Mark online and optional
inputs with `#| eval: false`, explain prerequisites and never invent saved
outputs. Test live operations separately.

Keep organism, source IDs, revisions, processing, selections and seeds explicit.
Prefer small real public datasets for scientific examples; retain license,
checksum and selection rules in the [example data record](BioDataLink/Assets/Examples/README.md).
Use `scripts/exampleData.wls` for pinned regeneration. Label synthetic examples
and state the limits of subsets or single-donor data.

Show the actual data or a useful view before counts or truth values. Keep one
observation per input. Reference examples reset their own data after headings
and thematic breaks. Tutorials define one running dataset with visible choices.

Place reusable tutorial helpers in a final `## Initialization` section. Build
enabled helpers before the body and retain native initialization cells in one
closed group with a visible opener. Keep inputs inspectable; do not use
`#| input: false`. Online and optional cells remain disabled and are never
initialization cells.

Use concise native Wolfram Language and presentation defaults. Each figure is
one copyable input, with short figure-only setup in `With`. Shared data and
analysis prerequisites remain explicit. Keep units, labels, seeds, shared scales,
fixed comparison coordinates and options needed for interpretation; omit
decorative repetition. Verify axis orientation and missingness, not only appearance.

### Figures

Choose distributions for spread, log scales for counts, explicitly ordered
heatmaps for matrices and shared scales for comparisons. Use small marks in
dense plots; draw expressing cells above zeros. Encode magnitude by area in
dot/rose plots. Check automatic ranges and use `PlotRange -> All` when extremes
carry the result.

Choose color by value type
([Crameri et al. 2020](https://doi.org/10.1038/s41467-020-19160-7)):

- Categories: [Okabe-Ito](https://doi.org/10.1038/nmeth.1618) for up to seven,
  or [Tol muted](https://sronpersonalpages.nl/~pault/) for eight or nine. Check
  actual mark size, background and color-vision-deficiency simulations.
- Magnitudes: monotonic lightness, such as `"BlueGreenYellow"` or reversed
  `"LakeColors"` when zeros should recede.
- Signed values: a diverging map centered on the neutral value; use a shared
  symmetric range and check color scaling, not just plot range.
- Avoid rainbow-like maps that create false boundaries.

Label groups and reuse their colors. UMAP can distort global distances,
densities and group sizes; check conclusions in the analysis space.

### Documentation verification

Run examples in a fresh checkout kernel, build with `make notebooks`, inspect
outputs/layout and check links. Source checks alone do not verify notebooks.
Inspect representative light/dark output when formatting changes. Verify prose,
counts, legends and saved results agree; report missing tooling or inspection.

Check individual figure inputs after their documented prerequisites as well as
whole-page runs. For helpers, verify initialization-only evaluation, the final
closed group and exclusion of disabled cells. Recheck affected pages after
contract or helper changes. Keep every claim within the evidence examined.
