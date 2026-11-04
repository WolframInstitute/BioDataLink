# Case-study review follow-up

Source: the 2026-11-04 worktree review in this task. All three reported issues
were reproduced in Wolfram Language 15.0 before the fixes.

| Reported issue | Current verdict and action | Verification |
| --- | --- | --- |
| P2: PCA comparison hides cell populations | Fixed. Use the full range in the shared map helper; also include all genes in the adjacent loading plot. Explain the platelet-labeled cells' large PC 2 extent. | Saved PCA, UMAP and loading plots contain no points outside their ranges. All 14 platelet-labeled cells are included. Light and dark renderings inspected. |
| P2: hinge plot clips the key results | Fixed. Include the full range of backbone-angle changes. | Saved plot reaches 173.99 degrees and includes all eight changes above 60 degrees. Light and dark renderings inspected. |
| P2: regenerated PBMC data fails its integrity test | Fixed. Pin compact JSON content after dropping only the retrieval timestamp; validate that the recorded timestamp parses. | All 7 example-data tests pass on both the committed subset and the independently regenerated subset. |

The dataset checks retain all counts, axis metadata, selection flags and fixed
provenance. Freezing the retrieval timestamp was rejected because it would
misstate when a fresh download occurred. Refreshing the expected checksum on
every run was rejected because identical scientific content should pass the
existing check. The reader's file-byte hash remains unchanged in meaning.

The existing [figure rules](../../GUIDE.md#figures) already require checking
automatic plot ranges. No duplicate authoring rule was added.

The local build initially reported a resource-category lookup warning because
the kernel's Internet access was disabled. This is a documentation-tool metadata
request, separate from biological provider access. Enabling Internet access
only in a fresh build process returned the native category selector and
confirmed the live resource was version 0.3.1. Online tutorial inputs remain
unevaluated in the documentation build.
