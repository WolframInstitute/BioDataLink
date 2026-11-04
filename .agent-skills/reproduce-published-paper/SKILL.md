---
name: reproduce-published-paper
description: Reproduce specified computable claims from a biological paper with BioDataLink, recording exact datasets and analysis conventions, independent checks, limitations, and drafts for missing integrations.
---

# Reproduce a published biological result

Adapted from PureMath develop's reproduction workflow. Use this for an actual
reproduction request, not a literature summary or ordinary dataset access.
Read [Reviews and reproduction evidence](../../GUIDE.md#reviews-and-reproduction-evidence).
The current paclet supplies access and import operations; analyses beyond those
operations may be uncovered and must be labeled accordingly.

## Register the case

Search existing records by DOI or accession before creating a case. Use
`benchmarks/reproduction/<Area>/<Slug>/` for a case and its probe when that work
is requested. Downloaded papers, datasets and author code stay in ignored scratch
storage or an external cache. Follow the user's commit and branch instructions.

Read the original paper and deposited methods/data, including relevant figure
captions and supplements. Record paper version, dataset accession/release,
author-code revision and applicable licenses. A supplied excerpt can guide
scope; verify its qualifiers against the original when available and record any
source access limitation.

Fill [templates/case.md](templates/case.md) before running. Register one claim
per row with paper locus, exact qualifiers, expected result/comparison,
BioDataLink route and limits. Preserve organism, cell type, assay, sample unit,
controls, preprocessing, gene selection and statistical tolerance. The paper's
expected value is an oracle, never an input used to manufacture the result.

Check existing paclet and Wolfram behavior by functionality. Distinguish access
validation from reproducing an analysis or biological conclusion. A calculation
using the authors' processed matrix checks agreement under that processing; it
does not independently verify their upstream preprocessing.

## Run and classify

Adapt [templates/reproduce.wls](templates/reproduce.wls) to load this checkout
in a fresh kernel, assert required exports and check a real result shape.
Give each claim a time budget. Record exactly one result per registered claim.
Use exact equality for counts and identifiers, and a prespecified tolerance or
statistical criterion for numerical or stochastic claims. A timeout, message,
`Failure` or unevaluated call cannot be a success.

| Verdict | Meaning |
| --- | --- |
| `HIT` | Result agrees under the registered inputs and comparison |
| `MISS` | A supported route disagrees after input and convention checks |
| `PAPER` | A source discrepancy supported by an independent route |
| `BLOCKED` | Required data, format adapter, object or runtime is unavailable |
| `UNCOVERED` | No supported BioDataLink/Wolfram route for the requested operation |
| `INCONCLUSIVE` | Timeout, ambiguity or insufficient evidence to decide |

On disagreement, first check dataset revision, axis ordering, source filtering,
normalization, sampling units, assay differences and randomness. Use a second
route or the authors' code on the same inputs where possible. Record circular
checks as agreement, not independence. Preserve the minimal failing example.
Do not modify the implementation to force a reproduction to pass within a
measurement-only task.

For missing capabilities, use [integration-patterns.md](integration-patterns.md)
and draft the relevant [blocked issue](templates/issue-blocked.md) or
[bug issue](templates/issue-miss.md). These are local drafts; post externally only
when the user requests it. A temporary probe-local converter can establish
feasibility but does not count as a completed public integration.

## Report and reuse

Record environment, data hashes, command, actual outputs and elapsed times in
the case. A rerun compares prior and current verdicts and identifies regressions,
resolved gaps and changed source data separately. Keep one result per claim.

A requested published tutorial can use
[templates/showcase-section.md](templates/showcase-section.md) after successful
checks. Preserve data access costs and evidence limits in the page, with the
[biodata-tech-note](../biodata-tech-note/SKILL.md) workflow. Reproducing an
accession or a figure is useful evidence within that scope; it does not by
itself validate a causal or clinical claim.

Report hits, misses, source discrepancies, blocked routes and uncovered or
inconclusive claims, each with its claim identifier and evidence. State exactly
what was tested and whether anything was published or committed.
