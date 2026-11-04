# Imported conventions

The preferred upstream is [PureMath develop at e2dacfa](https://github.com/WolframInstitute/PureMath/tree/e2dacfa90c526c3bc9902ef7fa24d29932fb3b22).
It supplies review and authoring conventions; Ruliology supplied the initial
workflow patterns. Build and publication use PacletPage through thin entry
points. Source-project checkouts, accounts and environments remain separate.

## Applied documentation practices

Use one canonical reference per symbol, task-oriented guides, real signatures,
explicit defaults and independent reference examples. Mark built-ins WL and
Function Repository functions WFR. Label synthetic data, preserve source
attribution, and verify evaluated notebook output. Shared rules live in
[GUIDE.md](../GUIDE.md#documentation).

Tutorial helpers now live in a final, closed native Initialization group;
earlier upfront-setup examples have been replaced.

## Biological data specialization

Provider identity, matrix orientation, aligned identifiers, measurement scale,
missingness and provenance are part of the public contract. Keep discovery,
verified download and native import distinct. Data-operation failures return
structured diagnostics; unsupported argument forms follow documented patterns.

Default checks use local fixtures. Live checks and optional backends require
separate evidence. Use this repository's [commands](../CONTRIBUTING.md), not
source-project paths, credentials or publishing destinations.
