---
name: wolfram-kernel-options
description: Implement or review BioDataLink kernel options, including cache and resource controls, forwarding, native visualization defaults, and SetOptions behavior.
---

# Kernel option conventions

Read [Options](../../GUIDE.md#options). `Options[f]` must describe the actual
defaults. Consume options through `OptionsPattern[]` and `OptionValue`; explain
and resolve `Automatic` before treating it as a Boolean or numeric value.

Preserve explicit call settings and `SetOptions` changes. Forward only options
supported by the inner function, keeping caller rules before fallback defaults.
Handle nested option lists without discarding `RuleDelayed`. Validate options
before provider requests or filesystem changes.

For data access, distinguish returned-cell limits, transfer-byte limits,
timeouts, cache selection and source version. An option limiting the result
must not imply a smaller download when the provider only supplies whole files.
Preserve exact dataset/query identity when resolving defaults.

For plots, inherit appropriate built-in defaults, including automatic sizing.
Keep stable category/color encodings across subsets; allow caller overrides.
Do not insert fixed sizes inside a function body as hidden defaults. Display
changes must not alter data selection or computational resource budgets.

Check observable defaults, a `SetOptions` change, and an explicit override;
restore defaults after tests. Inspect representative graphics when output
formatting changes. Documentation may set a size for a specific readable
example, with the saved result inspected.
