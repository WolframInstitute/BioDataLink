# Integration patterns for blocked claims

Use this with [SKILL.md](SKILL.md) to scope a missing capability. A reproduction
run may propose or probe an adapter; it does not silently turn into a production
implementation. Preserve the distinction between a probe-local result and an
implemented BioDataLink route.

| Missing input | Pattern |
| --- | --- |
| Deposited expression matrix, metadata table, atlas or raw files | Data access and import |
| A derived graph, annotated matrix or compact synthetic benchmark | Object construction |
| AnnData, Pertpy, a statistical package or authors' software | Optional library integration |

## Data access and import

Record source URL/DOI, accession, release, file list, sizes, license and source
checksums where available. Choose a stable revision and distinguish local hashes
from upstream integrity claims. Describe the source format and exact result:
matrix axes, sparse encoding, cell/gene identity, layers and normalization.

Use existing catalog/data APIs where their semantics fit. Specify lazy or
provider-side slicing and whether a full download is required first. Plan cache
keys by revision and query, atomic writes, bounded retries and offline behavior.
Provide a tiny independent fixture plus a separate opt-in real-data check.
Accessing metadata must not start a large download.

## Object construction

If the paper provides a compact definition, record it with the source locus and
construct the smallest faithful representation from existing operations. State
shape, indexing, deterministic inputs and independently checkable invariants.
A synthetic benchmark needs its seed and generator; it is not a substitute for
a biological deposit. When no compact definition exists, treat the object as
data and apply the access/import pattern.

## Optional library integration

Follow [integrate-external-libraries](../integrate-external-libraries/SKILL.md)
and [Optional library lifecycle](../../GUIDE.md#optional-library-lifecycle).
Record version, supported platform and modules; detect readiness without
installation. Use structured Python calls or documented CLI formats before
considering native bindings. Keep dataset and dependency downloads explicit.

Preserve data types, sparse matrices, axis alignment and scientific conventions
across the boundary. Reuse owned sessions, retain caller ownership and invalidate
session-bound handles after restart. Test real-library results separately from
fallbacks and mocks. Explain license and bundling requirements without assuming
access to another project's credentials or environment.

## A complete proposal

A proposal should identify the blocked claim, the smallest operation that would
unblock it, expected data/disk/runtime cost, new dependency or export, the guide
that owns it, and a concrete validation example. Link any feasibility probe and
state the scope it actually checked.
