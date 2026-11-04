---
name: functions-library-ingest
description: Survey an external biological library or data index into a BioDataLink capability mapping, checking existing paclet and Wolfram behavior before proposing adapters or symbols.
---

# Survey an external library

Adapted from PureMath's develop playbook. This workflow produces the inventory
or proposal requested; an inventory alone does not authorize implementation.
Read [Public interfaces](../../GUIDE.md#public-interfaces) and the current
provider contract before proposing an exported name.

Capture a large source once into ignored scratch storage and parse it locally.
Record official source URL, version or commit, retrieval date, exported name,
module, kind and a short description. Summarize top-level entries and counts by
module. Preserve only the curated mapping and permitted small metadata snapshots
in the repository; do not copy a documentation site wholesale.

Classify entries as data access, scientific analysis, internal infrastructure,
deferred specialization, or existing coverage. Access operations and supported
formats are particularly useful here; library-internal algorithm knobs do not
necessarily deserve public symbols. Keep exclusions and their reasons.

Check each candidate twice: existing BioDataLink behavior across all areas,
then Wolfram built-ins and Function Repository functions by functionality and
likely synonyms. Probe representative near matches and record the kernel
version. Reuse an existing public operation when the adapter extends its
provider or format coverage. A free symbol name does not prove a functional gap.

Write a focused mapping in `docs/notes/<Library>Integration.md` when needed:
source operation, current Wolfram route, uncovered scope, planned adapter,
status and evidence. Mark a capability implemented only when its adapter and
tests exercise the declared input family. An installed dependency or upstream
loader is not a completed BioDataLink integration.

Use [integrate-external-libraries](../integrate-external-libraries/SKILL.md) for
implementation planning and [biodata-guide-page](../biodata-guide-page/SKILL.md)
for requested guide work. Report proposed, already covered, excluded and
unresolved entries with source traceability. Do not automatically create guide
symbols or issue posts during an inventory-only task.
