# Contributing to BioDataLink

Read [AGENTS.md](AGENTS.md) for repository layout and playbooks, and
[GUIDE.md](GUIDE.md) for code, data and documentation conventions.

## Development environment

Use Wolfram Language 15.0 or later, `wolframscript`, Python 3 and GNU Make or a
compatible `make`. The catalog and ordinary metadata operations should be
usable without Python biological-analysis packages. Optional provider backends
must report their dependencies and tested versions separately.

Documentation builds call PacletPage directly with the configured Markdown
converter. The project keeps thin check/test/build entry points. Run
`make bootstrap` explicitly to install missing documentation tooling. Provider
data is not part of that bootstrap. Keep biological examples and default tests
local and deterministic. See the build scripts for actual tool resolution.

## Load from source

Start a fresh kernel and register the inner paclet directory:

```wolfram
PacletDirectoryLoad["/path/to/BioDataLink/BioDataLink"];
Needs["WolframInstitute`BioDataLink`"];
FindFile["WolframInstitute`BioDataLink`"]
```

Confirm that the resolved path belongs to the checkout before testing. An
already loaded installed release can hide source changes; use a fresh kernel
rather than trying to repair its symbol state. The test runner should load the
checkout itself.

## Check your work

| Change | Checks |
| --- | --- |
| Repository-only prose, agent instructions or badges | `make lint-docs`, changed-link checks and `git diff --check` |
| Kernel or dataset contract | Focused `make test FILES="..."`, then `make check` |
| Executable reference or tutorial | Relevant runtime checks, `make notebooks`, inspect rendered output |
| Python automation | `make python-tests` and affected command |
| Build, packaging or release workflow | `make all` and review the resulting archive/workflow changes |

`make test` runs all Wolfram tests; the `FILES` value accepts test paths relative
to the repository. `make check-publish` validates local publication artifacts
without deploying them. `make all` is the complete local validation target.
Run `make help` for the maintained command list. The build index is maintained
manually; source-file presence does not establish that tests or notebook
verification passed.

Use small offline fixtures for default tests. Keep live-provider checks
explicit, bounded and separate from normal CI. Record dataset releases,
checksums and actual observations for any live import that is tested. Do not
represent a mock test as evidence that a remote service works.

Report commands and outcomes, including missing runtimes, front-end access,
optional dependencies and skipped checks. Rerun affected checks after the final
edit. A failed parse or a test file with no executed tests is not a pass.

## Style and documentation

Use four-space indentation, descriptive `TestID` values and clear
UpperCamelCase public names. Follow [GUIDE.md](GUIDE.md) for sparse matrices,
axis identifiers, failure handling and option forwarding. Keep source metadata
and returned values aligned across filtering and conversion.

Edit documentation Markdown under `docs/en/`. Use the appropriate
[playbook](AGENTS.md#playbooks). Keep proposed behavior in design records until
its implementation and examples work. Notebook generation and visual inspection
are separate checks; report both accurately.

In Markdown, write a Wolfram context with double-backtick spans and spaces
inside: `` WolframInstitute`BioDataLink` ``.

## Git hooks and commits

Enable the local hooks explicitly with `make hooks`. Inspect the hooks before
changing their behavior; they run only for this checkout.

Use Conventional Commits: `type(scope): subject`, at most 72 characters in the
subject. Useful types are `feat`, `fix`, `docs`, `test`, `refactor`, `perf`,
`build`, `ci`, `chore` and `style`. Keep changes focused and describe their
observable effect and validation in the pull request. Preserve another
contributor's uncommitted work. Follow the user's branch and commit instructions.

## Continuous integration

Pull requests and pushes are checked by the workflows in `.github/workflows/`.
Ordinary commits run CI; do not add skip markers as a routine convention.
The Python validators run without a Wolfram license. Wolfram runtime and build
jobs need an appropriate license entitlement configured for this repository.

Repository setup is not evidence that hosted CI has run. Confirm the first
hosted run after a remote and its secrets are configured. Keep credentials in
GitHub Actions secrets, not committed files. Never copy another project's
secret values or use its entitlement without authorization. The workflow files
are the source of truth for exact variable names and environment gates.

## Releases

Preparing, testing and building artifacts is local work. Publishing a GitHub
release, pushing a release tag, or deploying to Wolfram Cloud requires a user
request covering that action. Existing authorization remains valid for the
requested release; do not ask again for each mechanical step.

Follow [deploy-biodatalink](.agent-skills/deploy-biodatalink/SKILL.md).
Before an authorized release:

1. Reconcile the intended version with existing tags and any published version.
2. Update `BioDataLink/PacletInfo.wl`, `CITATION.cff` and `CHANGELOG.md` together.
3. Run `make all` and inspect the archive and generated documentation.
4. Ensure CI passed for the exact main-branch commit to be tagged.
5. Create the version tag through the documented release workflow.

The tag-driven release workflow creates the GitHub release from the validated
CI artifact. Wolfram Cloud publication is an explicit gated workflow dispatch,
with the requested tag and confirmation. Consult the actual workflows before
running either; do not assume pushing a tag also publishes to Wolfram Cloud.

Verify the resulting release version, source commit, installability and relevant
rendered documentation after publication. If a publish run is interrupted,
inspect its stage and remote metadata before retrying a write.

## Reviews and reproduction work

Use the [review playbook](.agent-skills/review-biodata-changes/SKILL.md) for
code and data-contract review, and the
[review application playbook](.agent-skills/apply-expert-review/SKILL.md) for
supplied findings. Keep issue status, current-code verdict, action and evidence
separate. A rendered defect needs rendered verification; a provider defect
needs evidence for that provider path.

A published-result reproduction uses the
[reproduction kit](.agent-skills/reproduce-published-paper/SKILL.md), including
case, probe and issue-draft templates. Register exact claims and dataset
revisions before running a probe. Record author code, preprocessing and
conventions, and distinguish independent checks from agreement using the same
input construction. Keep downloaded data and author code out of the repository.
Draft issues locally; post only when the user requests external communication.

The PureMath `develop` playbooks are the preferred source for these conventions.
BioDataLink retains its current tooling and data-specific contract; a future
optional-backend setup panel or reproduction showcase is added only when there
is implemented behavior to demonstrate.

## Source use and provenance

Record dataset source, accession, version, retrieval date, checksum and citation
where available. Keep unknown fields explicit. Do not commit large downloaded
datasets or local caches. Synthetic fixtures must be labeled; a derived fixture
must identify its source and transformation and be suitable for redistribution.
Keep dataset license information separate from the paclet license.

Use stable official documentation and paper links for source claims. Preserve
qualifiers and distinguish published findings from examples reproduced here.
Local documentation links must resolve to repository files; describe ignored
scratch artifacts as paths rather than durable links.
