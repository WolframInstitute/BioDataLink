---
name: add-optional-library
description: Add or revise explicit optional-backend setup and readiness checks for BioDataLink when such setup is requested; do not assume an installer or setup dialog already exists.
---

# Add optional dependency setup

Read [Optional library lifecycle](../../GUIDE.md#optional-library-lifecycle)
and inspect existing dependency/setup code before editing. The initial paclet
has native catalog and local JSON access; a Python biological backend and a
shared installer are future capabilities, not prerequisites for package load.

If an optional-library registry exists, extend its single entry format. If the
requested task introduces the first one, define the smallest shared setup API
needed for that task. Record library name, tested version, platform support,
trusted source, approximate download size when known and any manual requirements.
Do not create a separate dialog or prompt for each adapter.

Keep installation explicit. Readiness checks inspect the actual runtime and
required modules and run a small representative operation when appropriate;
they perform no downloads. A missing optional library must not prevent loading
BioDataLink or using native catalog and JSON functions. A successful install
must invalidate a cached missing-library result in the current kernel.

Test missing, ready, unsupported and installed-but-unusable states with controlled
fixtures. For a requested real-install check, use an isolated environment and
confirm a second check does not download again. Leave existing user environments
and global package versions intact. Installation failures retain their causes.

A future setup dialog must remain optional and stay out of scripts, CI, cloud
and parallel evaluation. If one is actually added, test cancellation, progress,
reopening and failed operations. Document only installed behavior; describe
unimplemented setup work in the roadmap.
