---
name: integrate-external-libraries
description: Plan, implement, or test an optional BioDataLink backend, including structured conversions, sessions, method selection, correctness evidence and integration status.
---

# Integrate an external backend

Read the target API, tests, provider contract, relevant integration mapping,
and [Optional library lifecycle](../../GUIDE.md#optional-library-lifecycle).
Use [functions-library-ingest](../functions-library-ingest/SKILL.md) for a large
upstream inventory and [implement-biodata-functions](../implement-biodata-functions/SKILL.md)
for kernel changes. Python/H5AD and CELLxGENE adapters are planned work until
implemented; this playbook does not imply a setup panel already exists.

Establish what the library adds and verify its official API on a small example
when available. Record supported versions, platforms, modules and data access
requirements. Installation and usable readiness are separate observations.

Keep the adapter small. Use structured arguments, public external APIs and a
shared session helper. Transfer the smallest useful result; preserve sparse
shape, ordering, identifiers, metadata and measurement scale. An explicit
external method reports missing dependencies or conversion failure rather than
silently returning a fallback. Automatic fallback is appropriate only when the
result contract is equivalent.

Start owned sessions lazily and reuse them in that Wolfram kernel. Leave
caller-supplied sessions open. Clean up owned temporary objects on failure as
well as success. Invalidate external handles after a restart and never move
them between parallel kernels. Installation is an explicit action, not a
side effect of package load, dispatch or readiness testing.

Validate with a small independent fixture and, where authorized and available,
a representative real-library call. Verify which implementation actually ran.
Test absent dependencies, installed-but-unusable states, conversion failure,
session reuse, ownership and restart in disposable sessions without uninstalling
the user's environment. Missing optional-library tests report a skip explicitly.

If choosing methods for speed, benchmark the public operation including
conversion and cleanup. Separate startup, first call and repeated calls. Use
bounded repeated measurements and report variation; compare supported input
families and reverse method order in a fresh kernel. Keep failures and fallback
runs out of external-method timings. CI asserts correctness and method selection,
not machine-dependent speed thresholds.

Update integration status only for verified scope. Keep setup instructions in
one place and record versions, source data, checks and any skipped runtime
validation. Data provider availability and library computation are separate
checks.
