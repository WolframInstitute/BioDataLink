---
name: review-biodata-changes
description: Review BioDataLink code, provider contracts, tests, and documentation before handoff or release, including work in a shared checkout.
---

# Review BioDataLink changes

Read the diff, [AGENTS.md](../../AGENTS.md), [GUIDE.md](../../GUIDE.md) and the
relevant design record. Check promised behavior, including capabilities not
yet implemented, rather than relying on a passing test summary.

When another contributor owns an actively edited file, send findings with a
minimal reproducer and coordinate corrections. At handoff, review the new diff
and recheck affected behavior. Preserve unrelated changes and keep temporary
review scripts outside tracked source.

Check public signatures, provider identifiers, matrix shape and orientation,
axis labels, sparse values and processing status. Verify that filtering and
conversion preserve alignment. Check missing metadata, empty query results,
unsupported capabilities and computation failures separately. Inspect option
precedence, cache identity, bounded network operations and optional backend
errors as applicable.

Read test expectations. Confirm a small independent fixture exercises actual
values, not just dimensions or a conversion round trip. Ensure default tests
are offline and do not mislabel mocks as remote-import evidence. Run checks in
a fresh kernel resolving to the checkout; unexpected messages, parse failures
and zero executed tests are not passing results.

Compare reference pages, usage messages and examples with the final contract.
Verify provider claims and citations against source documentation. Follow
[Documentation verification](../../GUIDE.md#documentation-verification) for
executed and inspected notebooks, keeping source-only checks distinct.
Report findings by practical consequence with locations and evidence, followed
by checks run and remaining gaps.

Apply [Scope and representation guards](../../GUIDE.md#scope-and-representation-guards)
to validators and [Reviews and reproduction evidence](../../GUIDE.md#reviews-and-reproduction-evidence)
when interpreting a reported result or marking a finding resolved.
