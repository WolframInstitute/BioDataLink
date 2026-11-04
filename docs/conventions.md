# Imported conventions

BioDataLink's contributor documentation uses the user-selected
[PureMath develop snapshot](https://github.com/WolframInstitute/PureMath/tree/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22)
as the preferred source for reviews, guides and skills. The source branch was
read with `git show` and `git ls-tree`; its checkout was not changed.

Ruliology supplied initial CI and repository workflow patterns. Build,
documentation and publishing are delegated to PacletPage through thin entry
points. Source projects remain separate repositories.

## Applied documentation practices

- Keep one context and one canonical reference per exported symbol.
- Match kernel, test, guide and symbol-reference area names.
- Organize guides by researcher task and include relevant built-ins as `(WL)`
  entries, using the same symbol-chip syntax as paclet exports.
- Keep guide hierarchy links separate from related-guide cross-links.
- Show a symbol's actual return value before a reduction or plot.
- Use headerless reference tables, real Usage signatures and explicit option defaults.
- Keep reference examples independent across headings and example boundaries.
- Label synthetic examples and separate source-reported facts from new computations.
- Build examples and inspect generated output; Markdown source presence alone
  establishes neither successful evaluation nor readable rendering.
- Use double-backtick spans for contexts and preserve argument typography.

The small initial tutorial defines its fixture path in an upfront Initialization
section. Each body example independently loads the local fixture. This uses the
converter's setup semantics without custom notebook transformations.

## Biological data specialization

Providers, accessions, artifacts and measurements replace PureMath's subject
specific taxonomy. Unknown source metadata remain explicit. Matrix orientation,
identifier alignment, normalization and provenance are part of the data contract.

Provider failures and invalid imported files return structured `Failure`
expressions. This adapts the mathematical-function failure conventions to
external-data operations, where unavailable resources and invalid artifacts
need inspectable diagnostics. Unsupported argument shapes remain governed by
the documented Wolfram patterns.

Large data, remote services and optional libraries need separate evidence.
Default verification uses local fixtures. Live provider checks record their
source release and transfer details. Discovery coverage, verified download and
native import are tracked separately.

The CI/build entry points have their own local commands. Source-project pod paths,
cloud identities, installed environments and publishing destinations are not
transferred as operating requirements. See [CONTRIBUTING.md](../CONTRIBUTING.md)
for the commands in this repository.
