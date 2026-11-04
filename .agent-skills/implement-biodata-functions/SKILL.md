---
name: implement-biodata-functions
description: Implement BioDataLink Wolfram Language symbols and tests for catalog discovery, dataset metadata, local import, or provider access under an established data contract.
---

# Implement BioDataLink functions

Read the owning guide, applicable design record, implementation and
[GUIDE.md](../../GUIDE.md). Put code in
`BioDataLink/Kernel/<Area>/<Topic>.wl` and tests in
`BioDataLink/Tests/<Area>/<Topic>.wlt`. The single `PackageInitialize` in
`BioDataLink/Kernel/BioDataLink.wl` loads feature files.

Before code, settle input forms, provider capabilities, output shape and one
ordinary example. Check existing Wolfram and paclet behavior, then the proposed
name for a System collision. Draft the usage message first and apply
[Public interfaces](../../GUIDE.md#public-interfaces).

Declare public symbols with `PackageExported`; use `PackageScoped` for shared
area helpers. Follow [Wolfram Language code](../../GUIDE.md#wolfram-language-code)
for evaluation, options and backend boundaries. Validate cheap conditions before
reading large files. Preserve sparse matrices, axis identifiers, data layers
and provenance. Unsupported provider capabilities need an explicit result;
never fabricate data to make an advertised example succeed.

Write independent small fixtures and descriptive `VerificationTest` IDs.
Check actual values and axis alignment, a meaningful boundary case, and any
consumed option override. Use [Tests and evidence](../../GUIDE.md#tests-and-evidence)
to choose applicable error and cache tests. Run the focused test file in a fresh
kernel, then `make check`. Default tests must work without provider access.

Add exports to `BioDataLink/PacletInfo.wl` only when their behavior works.
Update the changelog, guide, design record and reference page in the same
change. Keep version bumps coordinated with the release plan; do not publish
as a side effect of implementing a function. Hand the reference work to
[biodata-symbol-page](../biodata-symbol-page/SKILL.md).

Apply [Scope and representation guards](../../GUIDE.md#scope-and-representation-guards)
to validators and [Reviews and reproduction evidence](../../GUIDE.md#reviews-and-reproduction-evidence)
when interpreting a reported result or marking a finding resolved.
