---
name: apply-expert-review
description: Apply supplied issues, notebook comments, or review findings to BioDataLink; reproduce behavior, track each outcome, and verify changes within the requested scope.
---

# Apply a review

Read the supplied material in full and the relevant implementation, design
record and [GUIDE.md](../../GUIDE.md). Preserve source artifacts and any sections
the user excluded. Record findings with source references and short paraphrases;
keep the reported problem distinct from what the current checkout does.

Classify each item as present, already fixed, different behavior, outside this
repository, or unresolved. Reproduce behavior in a fresh kernel resolving to
this checkout. For data reports, capture source release, accession and operation;
a screenshot of a past provider response does not establish current behavior.

Fix authorized findings in dependency order with the relevant implementation
or documentation playbook. Resolve routine choices from the existing contract;
do not reopen settled user decisions. Coordinate file ownership when another
agent is editing. A rename updates exports, usage, metadata, filenames, links,
examples and tests together.

For defects, add a regression check with independently specified expected data.
For prose or layout fixes, evaluate and inspect the affected artifact rather
than testing wording. Keep outcomes and evidence current. A source edit does
not close a rendering report; a mock test does not close a live-provider failure.

If a lesson applies broadly, update its existing shared rule in GUIDE and link
it from the relevant skill. Keep one-off choices in design records. Search
related occurrences within scope and classify them before editing. Report
resolved and remaining findings; release work uses
[deploy-biodatalink](../deploy-biodatalink/SKILL.md) only when requested.

Keep a compact triage table with source issue/status, current verdict, proposed
action, dependencies and final evidence. Preserve rejected reasoning and open
questions. Check new shared rules for duplicates, refinements and conflicts;
resolve routine wording from the current contract and surface only material
unresolved design choices. Follow
[Reviews and reproduction evidence](../../GUIDE.md#reviews-and-reproduction-evidence).
