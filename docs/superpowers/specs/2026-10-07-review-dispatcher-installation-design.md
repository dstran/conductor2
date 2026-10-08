# Review Dispatcher Installation

## Context

The `/conductor/review` command invokes the repository-local dispatcher
`conductor/scripts/open-pr.sh` after Archive cleanup. The source repository
contains that script, and the Gemini package currently includes it through a
recursive copy of `conductor/`, but the OpenCode curl installation does not
install it as an asset. `/conductor/setup` also does not copy it into a user
project.

As a result, a newly initialized OpenCode project can reach review-request
creation with no `conductor/scripts/open-pr.sh` file. Existing projects are
also not repaired merely by reinstalling Conductor.

## Goals

- Make `open-pr.sh` available after the standard curl installation.
- Make new projects receive a project-local dispatcher during `/conductor/setup`.
- Make existing projects work after reinstalling Conductor without requiring
  `/conductor/setup` to be rerun.
- Preserve a project-local dispatcher when one already exists.
- Keep the test harness `test-open-pr.sh` repository-only.
- Preserve `/conductor/update`'s workflow-only responsibility.

## Non-goals

- Changing provider detection, fallback output, or dispatcher behavior.
- Installing the test harness into user projects.
- Overwriting an existing project-local `conductor/scripts/open-pr.sh`.
- Adding script synchronization to `/conductor/update`.
- Changing Gemini's existing recursive package behavior.
- Adding vendor- or product-specific installation logic.

## Design

### OpenCode installation asset

Extend `install.sh`'s OpenCode surface with an asset directory:

```text
~/.config/opencode/command/conductor/assets/scripts/open-pr.sh
```

The installer creates the directory and copies only
`conductor/scripts/open-pr.sh` into it. The repository test harness remains
under source control but is not part of the runtime installation payload.

The installer continues to replace the installed Conductor command surface on
each run, so the installed dispatcher matches the checked-out Conductor
version. The existing Gemini recursive copy is unchanged because it already
packages the complete `conductor/` tree.

### Setup for new projects

Add a setup section for the review dispatcher. If
`conductor/scripts/open-pr.sh` is absent, `/conductor/setup` creates
`conductor/scripts/` and copies the installed OpenCode asset into it. If the
file already exists, setup leaves it untouched. This gives new projects a
versioned local copy without overwriting project-specific changes.

The setup integrity/index scaffolding does not need a new link: the script is
an operational helper, not a project-context document.

### Review fallback for existing projects

Update the Archive-only request-creation instructions in `review.md` to
resolve the dispatcher in this order:

1. Use `conductor/scripts/open-pr.sh` when the project-local file exists.
2. Otherwise use
   `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`.

The review command reports a clear installation error if neither path exists,
rather than attempting to invoke a missing file. The existing arguments,
temporary body-file lifecycle, provider behavior, and no-merge rule remain
unchanged.

This fallback means reinstalling Conductor repairs existing projects without
requiring setup to be rerun. A project-local copy continues to take precedence
so projects can preserve a deliberately customized or pinned dispatcher.

### `/conductor/update` boundary

`/conductor/update` remains unchanged. Its documented contract is to compare
and optionally replace only `conductor/workflow.md`; adding script migration
would broaden its write scope and introduce overwrite/versioning policy that
is not required by this fix. The review fallback handles existing projects,
and setup handles new projects.

## Files

### In scope

- `install.sh` — install the runtime dispatcher under the OpenCode assets path.
- `.opencode/command/setup.md` — copy the dispatcher for new projects.
- `.opencode/command/review.md` — use project-local dispatcher or installed
  fallback.
- `docs/superpowers/specs/2026-10-07-review-dispatcher-installation-design.md`
  — this design.

### Out of scope

- `conductor/scripts/open-pr.sh` — behavior is unchanged.
- `conductor/scripts/test-open-pr.sh` — remains a source-repository test.
- `.opencode/command/update.md` — remains workflow-only.
- `install-latest.sh` — it already clones the full repository and invokes
  `install.sh`.
- Gemini, Claude, Codex, and Antigravity installation behavior.

## Verification

- `install.sh` passes `bash -n`.
- A sandbox install from outside the repository produces
  `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh` with the
  same bytes as the source dispatcher.
- The installed command surface does not include `test-open-pr.sh`.
- `sh conductor/scripts/test-open-pr.sh` still passes.
- `sh -n conductor/scripts/open-pr.sh conductor/scripts/test-open-pr.sh`
  passes.
- Setup instructions create the project-local dispatcher only when missing.
- Review instructions prefer a project-local dispatcher and fall back to the
  installed asset, with an explicit error when both are missing.
- `update.md` remains unchanged and still states that only
  `conductor/workflow.md` is modified.
- `git diff --check` passes.

## Delivery

This change is added to the existing review-dispatcher installation PR
(`#18`) as follow-up commits. It is intentionally separate from the already
merged embedded/host-code doctrine changes in that PR's initial scope, while
using the same branch and review surface.
