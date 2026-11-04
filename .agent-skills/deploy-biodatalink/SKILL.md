---
name: deploy-biodatalink
description: Prepare or perform an explicitly requested BioDataLink release, GitHub release, or Wolfram Cloud publication; verify the source commit, artifacts, and resulting deployment.
---

# Release BioDataLink

Read [Releases](../../CONTRIBUTING.md#releases), the actual release/publish
workflow files, and [review-biodata-changes](../review-biodata-changes/SKILL.md).
Setup and local validation do not authorize remote publication. An existing
user request to release authorizes its necessary mechanical steps; do not ask
again for each step.

## Prepare a reviewable artifact

Check the intended version against existing tags and any live resource.
Confirm that the source commit includes the intended published changes. Update
PacletInfo, CITATION and CHANGELOG together. Run `make all` and inspect the
archive and relevant rendered pages. Keep ordinary and release CI unskipped.
Before tagging, require successful CI for the exact main-branch commit that the
release workflow will use.

For the initial setup, report missing repository configuration, license
entitlement or cloud credentials specifically. Never copy another project's
secret values, account session or entitlement as part of porting its scripts.

## Release and publish

When authorized, use an annotated version tag following the workflow contract.
The tag-driven release attaches the verified CI artifact. Cloud publication is
a separate explicitly gated workflow dispatch; inspect its required tag and
confirmation inputs before invoking it. The GitHub release uses the verified CI archive. Cloud publication may rebuild
from the same tag; check that its version and source commit agree and report
the rebuild rather than claiming byte-identical artifacts.

If a local publish path is used, inspect its account checks and run with the
intended existing cloud session. Avoid changing persistent account settings as
a side effect. Keep logs under ignored build output and track only the process
owned by this run. On interruption, inspect the recorded stage and remote
version metadata before retrying a write.

## Verify the result

Watch the authorized workflow to completion. Confirm version and source commit
on the published artifact, install it in a fresh kernel, and exercise the public
examples that motivated the release. Inspect relevant documentation links and
rendered output. Report local checks, hosted CI, GitHub release and Cloud
publication as separate outcomes; do not claim an unperformed stage succeeded.
