# AGENTS.md

Instructions for contributors and coding agents. `CLAUDE.md` imports this file.

BioDataLink provides discoverable, reproducible access to biological datasets
from Wolfram Language. Describe providers, records, accessions, metadata,
matrices, identifiers, provenance and evidence. Distinguish a catalog entry
from a verified download or import.

## Layout

The paclet is `WolframInstitute/BioDataLink`, with context
`` WolframInstitute`BioDataLink` ``. Kernel code lives in
`BioDataLink/Kernel/`, tests in `BioDataLink/Tests/`, and documentation sources
in `docs/en/`. Use the areas documented in [README.md](README.md).
Keep one implementation and one canonical reference page for each symbol.

Call `PackageInitialize` once in `BioDataLink/Kernel/BioDataLink.wl`.
Feature files declare public names with `PackageExported`, give each a usage
message, and list them under `"Symbols"` in `BioDataLink/PacletInfo.wl`.
Declare shared area helpers with `PackageScoped` in the area's `Helpers.wl`.
Use built-ins or existing Function Repository functions when they cover the
required behavior; a new wrapper needs a clear functional difference.

## Commands

| Task | Command |
| --- | --- |
| Metadata, source and documentation checks | `make check` |
| Wolfram Language tests | `make test` |
| One Wolfram test file | `make test FILES="BioDataLink/Tests/<Area>/<Topic>.wlt"` |
| Python automation tests | `make python-tests` |
| Markdown checks | `make lint-docs` |
| Install missing documentation build tooling | `make bootstrap` |
| Documentation notebooks from Markdown | `make notebooks` |
| Build a paclet archive | `make build` |
| Build and check publication artifacts without cloud writes | `make check-publish` |
| Complete local validation | `make all` |
| Install local git hooks | `make hooks` |

Choose checks by scope in [CONTRIBUTING.md](CONTRIBUTING.md#check-your-work).
Repository-only prose needs Markdown and changed-link checks. Code, data
contracts, and executable documentation need the corresponding runtime checks.
Default tests use local fixtures and do not call live data providers. Document
any external build-tool bootstrap separately from provider access.

Performance is a project requirement. Keep package loading offline, reuse
validated immutable metadata, index repeated identifier lookups, and batch
provider requests. Preserve sparse data and avoid unnecessary copies or full
downloads. Measure representative public operations when changing a hot path;
report cold and repeated-call timings separately, including conversion costs.
Optimize measured bottlenecks without weakening data validation or provenance.

Use Conventional Commits with a subject of at most 72 characters.
CI excludes changes confined to the root `README.md`; those changes may use
`[skip ci]`. Never use a skip marker when the push or pull request also changes
another file. Code, build configuration, executable documentation and mixed
changes must retain their CI checks. Manual CI dispatch remains available.
Release or publication requires a user request; setup work does not publish.
Follow existing user authorization without repeatedly asking for it.

## Playbooks

Read the matching playbook before that work:

| Task | Playbook |
| --- | --- |
| Survey a library or function index | [functions-library-ingest](.agent-skills/functions-library-ingest/SKILL.md) |
| Add or update a data provider | [dataset-provider](.agent-skills/dataset-provider/SKILL.md) |
| Integrate an external backend | [integrate-external-libraries](.agent-skills/integrate-external-libraries/SKILL.md) |
| Add optional dependency setup | [add-optional-library](.agent-skills/add-optional-library/SKILL.md) |
| Reproduce a published result | [reproduce-published-paper](.agent-skills/reproduce-published-paper/SKILL.md) |
| Implement kernel symbols and tests | [implement-biodata-functions](.agent-skills/implement-biodata-functions/SKILL.md) |
| Implement options or visualization defaults | [wolfram-kernel-options](.agent-skills/wolfram-kernel-options/SKILL.md) |
| Write a topic guide | [biodata-guide-page](.agent-skills/biodata-guide-page/SKILL.md) |
| Write a symbol reference | [biodata-symbol-page](.agent-skills/biodata-symbol-page/SKILL.md) |
| Write a worked tutorial | [biodata-tech-note](.agent-skills/biodata-tech-note/SKILL.md) |
| Develop an analysis essay | [biodata-computational-essay](.agent-skills/biodata-computational-essay/SKILL.md) |
| Apply supplied review findings | [apply-expert-review](.agent-skills/apply-expert-review/SKILL.md) |
| Review code and documentation | [review-biodata-changes](.agent-skills/review-biodata-changes/SKILL.md) |
| Release or publish | [deploy-biodatalink](.agent-skills/deploy-biodatalink/SKILL.md) |

The preferred upstream playbooks and review conventions are from PureMath
`develop` at `e2dacfa90c526c3bc9902ef7fa24d29932fb3b22`; provenance and deliberate
adaptations are recorded in [GUIDE.md](GUIDE.md#terms-and-scope).
Keep shared rules in [GUIDE.md](GUIDE.md). Skills link to that guide and give
steps specific to the task. Record future behavior in [ROADMAP.md](ROADMAP.md),
with implemented and proposed APIs clearly distinguished. Preserve a source's
identifier, version and measurement conventions when adapting it.

## Documentation and language

Markdown under `docs/en/` is the documentation source. Keep lists of guides,
tutorials and symbols alphabetical, with names starting with `$` last.
Separate paclet exports from built-in (WL) and Function Repository (WFR) links.
Only call a notebook verified after building and inspecting its output.
Use computed visuals when they help explain a dataset or comparison; metadata
lookups can remain text or tables.

Write short, direct sentences for a reader who knows biology but not this
project. Explain technical terms on first use. State what was checked and any
missing evidence. Do not invent dimensions, access conditions, licenses or
verified-import status from a paper title or catalog description.

A Wolfram context ends in a backtick. In Markdown, use double-backtick code
spans with spaces inside: `` Needs["WolframInstitute`BioDataLink`"] ``.
This also applies to commit messages and pull-request prose.
