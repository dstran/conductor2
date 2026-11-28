# Verification Baseline and Readable Implementation Plan

> Execute through `/conductor/implement verification-baseline_20261127`
> after plan and task classification approval. Follow Conductor's task
> commit and phase checkpoint procedure.

**Goal:** Establish a repeatable verification baseline and a task-level pass for cleaner, idiomatic code.

**Architecture:** Keep the lifecycle contract in `skill/SKILL.md` and operational
instructions in the existing commands. Use `conductor/tech-stack.md` for the
approved verification baseline and the bundled general guide for readability criteria.

**Tech stack:** Markdown command instructions, bundled guidance, and existing shell/Python regression suites.

**Spec:** [Approved design](./spec.md).

## Global constraints

- Preserve existing tools, settings, workflow test ordering, and approval gates.
- Ask before installing tools or changing configuration. Limit edits to approved
  files; do not reformat unrelated code.
- Use official guidance for supported versions. Do not add duplicate checks or
  claim unverified checks passed.
- Existing projects need a verification-only path without a setup interview.
- The user approved the plan and the track-local `documentation` classification
  for all three tasks. Verify these instruction changes with source checks and
  scenario walkthroughs. The global task taxonomy is unchanged.

## Review focus

- Existing projects may have unstructured verification commands; preserve them.
- A build can already type-check, and some checks need a device or service.
- Backlogged or unavailable checks must not become required silently.
- Simplification can invalidate earlier test results.
- A missing verification entry or tool must not become a false pass.

## Phase 1: Establish the baseline [checkpoint: bc4480d]

- [x] Task: Add baseline discovery, consent, and verification-only setup [documentation] bc4480d

  **Files:** `.opencode/command/setup.md`, `skill/SKILL.md`.

  1. Route `/conductor/setup verification` before the initialized-project guard.
     Read the existing handshake and tech stack. If the project is uninitialized,
     direct it to regular setup. Both routes share baseline discovery; verification
     mode skips the interview, style-guide copying, and unrelated setup steps.
  2. Inventory existing commands in scripts, CI, and config. Map them to the
     applicable check categories and project scopes, and propose only gaps using
     official version-relevant guidance. Retain the existing Swift and Android
     distinctions, and document unavailable recommendations rather than guessing.
  3. Obtain approval for the exact dependencies, configuration diff, and commands.
     Run approved commands. In `conductor/tech-stack.md` under
     `## Verification Commands`, record command, working directory/module scope,
     task or review timing, required/deferred status, and adoption notes when
     applicable. Preserve legacy entries pending explicit reconciliation.
  4. Walk through fresh and initialized setup, mixed modules, build covering
     type-checking, a device-only check, a missing tool, approval declined, and a
     failing pre-existing baseline. Verify the correct route, scope, and status
     with no unauthorized configuration changes.

## Phase 2: Apply and verify the baseline

- [x] Task: Apply readability and idiom checks before task commits [documentation] 1c20269

  **Files:** `.opencode/command/implement.md`, `skill/SKILL.md`,
  `conductor/assets/code_styleguides/general.md`.

  1. Expand general guidance with caller-oriented naming, straightforward control
     flow, comments for intent or constraints, version-appropriate idioms, and
     patterns justified by a present need. Keep judgment calls distinct from
     concrete issues.
  2. Add one task-diff pass before the code commit. Reuse applicable installed
     project guides. Run required task checks at recorded scopes, fix concrete
     issues within scope, and rerun affected checks after edits. Keep test-first
     and test-after ordering intact. A failed or unavailable required check
     prevents marking the task complete; report the reason.
  3. Walk through a clear readability issue, a legitimate explanatory comment,
     a supported idiom versus a newer unavailable one, justified versus premature
     abstraction, and a post-test edit that requires re-verification.

### Task 3: Verify the full baseline and document adoption

- [ ] Task: Verify the full baseline and document adoption [documentation]

  **Files:** `.opencode/command/review.md`, `skill/SKILL.md`, `README.md`.

  1. At review, run required task- and track-level checks. Record pass, failure,
     deferred, or not verified with a reason. Recheck affected items after
     corrections and rerun the required baseline at closure. If an older
     project has only legacy commands, use its confirmed commands and disclose
     unknown coverage; offer the verification-only audit.
  2. Document how adopters set up or refresh the baseline and what implement
     and review do with it. Walk the required pass/fail, missing device, deferred
     gap, and legacy baseline paths. Distinguish instruction walkthroughs from
     execution by a consuming agent.
  3. Run `python3 conductor/scripts/test-design-context.py`,
     `sh conductor/scripts/test-installer.sh`, `sh conductor/scripts/test-open-pr.sh`,
     `sh conductor/scripts/test-archive-track.sh`, and `git diff --check`.
     Require all commands to exit successfully and report any verification
     limitations in the checkpoint evidence.
