# Contributing to BioDataLink

See [AGENTS.md](AGENTS.md) for layout and playbooks and [GUIDE.md](GUIDE.md)
for data, code and documentation conventions.

## Development environment

Use Wolfram Language 15.0+, `wolframscript`, Python 3 and Make. Core metadata
operations need no Python biology packages. Install missing pinned documentation
tools explicitly with `make bootstrap`; this does not fetch provider datasets.
Default tests and evaluated documentation use local data.

## Load from source

In a fresh kernel:

```wolfram
PacletDirectoryLoad["/path/to/BioDataLink/BioDataLink"];
Needs["WolframInstitute`BioDataLink`"];
FindFile["WolframInstitute`BioDataLink`"]
```

Confirm the resolved path belongs to this checkout. An installed release already
loaded in a kernel can hide edits; test runners register the checkout themselves.

## Check your work

| Change | Checks |
| --- | --- |
| Repository-only prose, agent instructions or badges | `make lint-docs`, changed-link checks and `git diff --check` |
| Kernel or dataset contract | Focused `make test FILES="..."`, then `make check` |
| Executable reference or tutorial | Relevant runtime checks, `make notebooks`, inspect rendered output |
| Python automation | `make python-tests` and affected command |
| Build, packaging or release workflow | `make all` and review the resulting archive/workflow changes |

`make test FILES="..."` accepts paths relative to the repository.
`make documentation-tests` checks tutorial initialization and caching;
`make check-publish` validates artifacts without deployment. `make all` runs
the complete local suite; `make help` lists commands.

Report commands, results and skipped checks. Rerun affected checks after the
final edit. Parse errors and zero executed tests are not passes. Keep live
checks bounded and opt-in, with source versions and observed results; fixtures
do not establish provider availability.

## Optional runtime and transport checks

Use an isolated interpreter for H5AD integration tests:

```sh
/path/to/environment/bin/python -m pip install -r BioDataLink/Tests/Python/requirements.txt
BIODATALINK_PYTHON=/path/to/environment/bin/python make h5ad-tests
```

Tests include AnnData for independent fixtures; runtime reading uses h5py/NumPy.
The paclet and test target do not install dependencies automatically.

```sh
make download-tests
```

Download transport tests require curl 8.4+, OpenSSL, Python and Wolfram Language.
They use a temporary loopback HTTPS server and certificate, not live providers.

## Style and documentation

Use four-space indentation, descriptive test IDs and UpperCamelCase public
names. Preserve sparsity, aligned metadata and option overrides. Edit Markdown
under `docs/en/`, using the relevant [playbook](AGENTS.md#playbooks).
Keep scientist-facing pages brief, with reproducibility and interpretation
details; put implementation decisions and proposed APIs in design records.

Write contexts with double-backtick spans and spaces:
`` WolframInstitute`BioDataLink` ``. Build and visually inspect executable docs.

## Git hooks and commits

Enable this checkout's hooks with `make hooks`; inspect before modifying them.
Use Conventional Commits with subjects ≤72 characters. Keep changes focused,
preserve others' work and follow the user's branch/commit instructions.

## Continuous integration

PRs and pushes to `main` run `.github/workflows/` checks. Only changes confined
to root `README.md` may skip CI. Never use `[skip ci]` for mixed changes, even
if the final commit only edits README. Manual dispatch remains available.
Release gates still require successful push CI on the exact main commit.

Python checks need no Wolfram license. Wolfram jobs require this repository's
entitlement, including simultaneous parent/child kernels. Keep credentials in
Actions secrets; never borrow another project's secrets or entitlement without
authorization. Workflow files define exact variables and gates. Repository
setup alone does not establish a successful hosted run.

## Releases

Publication requires a user request. Existing authorization covers necessary
steps for that release; do not ask again for each step. Follow the
[release playbook](.agent-skills/deploy-biodatalink/SKILL.md):

1. Check existing tags and live version; update PacletInfo, CITATION and CHANGELOG together.
2. Run `make all`; inspect notebooks and the archive in a fresh kernel.
3. Require successful main-branch push CI for the exact commit before creating the annotated version tag.
4. Watch the release and dependent Cloud publication workflows to completion.
5. Verify version, source commit, installation and rendered documentation.

The release attaches the verified CI artifact. Cloud independently checks the
released tag and exact-commit CI before publishing. A confirmed manual Publish
dispatch is only a retry for an already released tag under the same gates.
Inspect actual workflows and any `wolfram-cloud` environment rules first.
Retain the `publication` artifact with URLs/version/commit. After interruption,
inspect stage and live metadata before retrying a write.

## Reviews and reproduction work

Use the [review](.agent-skills/review-biodata-changes/SKILL.md),
[review application](.agent-skills/apply-expert-review/SKILL.md) and
[reproduction](.agent-skills/reproduce-published-paper/SKILL.md) playbooks.
Keep source status, current-code verdict, action and evidence separate.
Rendered defects need rendered checks; provider defects need that provider path.
Register reproduction claims and exact inputs before probing. Shared data
construction is not independent validation. Draft issues locally; post only
when authorized. Keep downloads and author-code caches out of the repository.

## Source use and provenance

Record source, accession, revision, retrieval time, checksum and citation when
available. Label synthetic fixtures and document derived selections and licenses.
Keep unknowns explicit and dataset terms separate from MIT. Cite stable official
sources, preserve qualifiers and distinguish reported findings from reproduced
results. Local links must resolve; ignored scratch artifacts are not durable links.
