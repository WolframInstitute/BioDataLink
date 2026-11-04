---
name: biodata-symbol-page
description: Write and verify a reference page for an implemented BioDataLink symbol, including exact dataset semantics, provider capabilities, properties, and runnable local examples.
---

# Author a symbol reference

Read the implementation, usage message, tests, relevant design record and
[GUIDE.md](../../GUIDE.md). Write
`docs/en/ReferencePages/Symbols/<Area>/<Symbol>.md` with the `Symbol` template,
matching `Name`, context, paclet and URI
`WolframInstitute/BioDataLink/ref/<Symbol>`.

Put actual signatures in Usage and supported arguments, properties and
options in Details & Options. Specify provider capability, matrix axis order,
identifier semantics, count/normalization status and relevant limits. Use the
[Reference page conventions](../../GUIDE.md#reference-pages) for placeholder
formatting and headerless tables. Keep implementation history in design notes.
Preserve the native Usage, Details & Options and Examples structure. Use short
idiomatic inputs and presentation defaults; move extended workflow discussion
to a tutorial rather than expanding every reference example.

Start with a small useful result. Examples evaluated in ordinary builds use
local fixtures; explicitly identify synthetic data and online operations.
Show useful metadata or a matrix view before reducing it to a count. Include
meaningful Scope, Options and Possible Issues examples, covering unsupported
capabilities and missing metadata when relevant. Expected outputs must come
from evaluation, not invention.

Keep reference inputs independent after context loading. Check usage and
option defaults against the implementation, link the symbol from its owning
guide, and verify related links. Follow
[Documentation verification](../../GUIDE.md#documentation-verification): run
examples, `make lint-docs`, `make notebooks`, and inspect outputs and layout.
Report build or inspection limitations separately from source checks.
