# Doctrine Update Propagation (`/conductor/update`) — Design

Adds a mechanism for a target repo that already ran `/conductor/setup`
to catch its `conductor/workflow.md` up to whatever doctrine is
currently installed, when this port's own `workflow.md` doctrine
changes after that repo's setup ran. This is net-new scope, not a
Gemini-parity restoration — upstream Gemini Conductor has no equivalent
mechanism (see "Why upstream doesn't need this" below).

## Problem

Once `/conductor/setup` runs in a target repo, `conductor/workflow.md`
is a frozen, verbatim copy of this port's doctrine as of whatever
`conductor2` version was installed that day. There is currently no way
— in this port or upstream — to bring an already-set-up target repo's
`workflow.md` forward when this port's doctrine changes later. Every
repo that ran `/setup` is permanently stuck at that day's doctrine
unless a human manually re-copies the file by hand.

This was discovered concretely: after shipping the phase-auto-checkpoint
feature (`docs/superpowers/specs/2026-08-21-phase-auto-checkpoint-design.md`),
every target repo that had already run `/setup` before that change has
no way to receive it.

## Why upstream doesn't need this

Investigated before designing this feature, since "upstream doesn't
support this — maybe it shouldn't be supported" was a real possibility.

Upstream's `conductor-setup/SKILL.md` §2.5 runs a genuine customization
interview before writing `workflow.md` — coverage percentage, commit
frequency, summary storage. Once a team answers those questions, their
`workflow.md` is *supposed* to diverge from the vendored template; there
is no single "correct current state" to sync toward, any more than a
scaffolding tool should auto-update an already-customized `.eslintrc`.
Upstream's skill commands (`conductor-implement`, `conductor-review`)
also never restate `workflow.md`'s mechanics — they only ever say
"defer to the Workflow file as the single source of truth" — so there
is no duplicated content to keep in sync either.

This port's `setup.md` step 7 currently has no customization interview
at all — it writes `workflow.md` verbatim, unconditionally. That makes
this port's `workflow.md` a pure vendored mirror with no legitimate
per-project divergence, which is exactly the situation where staleness
becomes a real, unaddressed problem. (Whether to add a real
customization interview — closing this gap by matching upstream's
model — was considered as an alternative to this feature; see
"Alternatives considered" below. The decision was to keep
`workflow.md` a pure mirror and build the sync mechanism instead. A
candidate customization design is preserved for future reconsideration
in "Deferred: workflow.md customization knobs.")

## Goal

A target repo's `conductor/workflow.md` can be brought up to date with
the currently-installed `conductor2` doctrine, safely and on demand,
without ever touching user-authored project files.

## Non-goals

- **No sync for user-owned or partially-customized artifacts.**
  `product.md`, `tech-stack.md`, `product-guidelines.md`, and
  `tracks/*` are user-authored and out of scope entirely. Style guides
  in `conductor/code_styleguides/` can carry user-appended custom rules
  (`setup.md` step 6.4 lets a user append rules to a copied guide), so
  they are also out of scope for this feature — a blind overwrite could
  destroy those additions. This is the same problem class as upstream's
  unported `implement §4` doc-sync gap (tracked as gap **G1** in
  `docs/gemini-parity-gaps.md`) but is a different mechanism solving a
  different trigger (doctrine-version drift, not track-completion
  drift) — not addressed by this design.
- **No passive/automatic checks in `implement`, `new-track`, or
  `review`.** Those commands are not modified to check or nag about
  workflow.md staleness; only `/status` gets a passive nudge (see
  Design §4), and only `/update` performs the sync.
- **No `index.md` structure sync.** If `setup.md`'s `index.md` template
  structure changes, this feature does not attempt to reconcile an
  existing target repo's `index.md`.
- **No customization of `workflow.md`.** This design keeps
  `workflow.md` a 100% vendored, zero-customization mirror. See
  "Deferred: workflow.md customization knobs" for a candidate future
  design that would change this premise.

## Design

### 1. Extract the template

`workflow.md`'s content currently exists in two places that must be
hand-kept in sync: `conductor/workflow.md` (this repo's own copy, used
for dogfooding) and an inlined fenced markdown block in
`.opencode/command/setup.md` step 7 ("write this exact content:
```...```"). This dual-maintenance pattern already caused a real
mistake during the phase-auto-checkpoint work (a task existed
specifically to re-sync the two copies by hand).

Move the canonical content to a new standalone asset file,
`conductor/assets/workflow-template.md`. `setup.md` step 7 changes from
inlining the content to copying this file, mirroring the existing
pattern step 6 already uses for style guides:

```bash
cp ~/.config/opencode/command/conductor/assets/workflow-template.md conductor/workflow.md
```

This is a content-neutral refactor — no doctrine text changes — that
also permanently removes the dual-maintenance hazard for any future
`workflow.md` doctrine edit, independent of the update mechanism below.

### 2. Version-stamp the template

`install.sh` computes the currently-checked-out commit SHA:

```bash
SHA="$(git -C "$ROOT" rev-parse --short HEAD)"
```

When it copies `conductor/assets/workflow-template.md` into the
installed command directory, it appends a trailing marker line:

```
<!-- conductor-workflow-version: <sha> -->
```

`setup.md` step 7 copies the installed file byte-for-byte into the
target repo's `conductor/workflow.md`, so the marker travels with it
automatically — no new logic needed in `setup.md` beyond the copy
change from §1.

A target repo's `workflow.md` written before this feature existed has
no marker line. `/update` (§3) treats a missing marker as always-stale,
never as an error.

### 3. `/conductor/update` command

New file `.opencode/command/update.md`. Behavior:

1. Read the trailing marker from the installed
   `assets/workflow-template.md` and from the target repo's
   `conductor/workflow.md`. Missing marker on the target counts as
   stale.
2. **If the SHAs match:** report `Workflow doctrine is up to date
   (<sha>).` and stop. No file changes, no commit.
3. **If they differ (or the target has no marker):** show the user a
   full diff between the two files (`diff -u conductor/workflow.md
   <installed-template>`), then ask a Yes/No question: "Apply this
   update to conductor/workflow.md?"
   - **No:** stop, make no changes.
   - **Yes:** overwrite `conductor/workflow.md` with the installed
     template's content in one shot (safe — the file has never carried
     user customization, per this design's premise). Stage only
     `conductor/workflow.md` and commit:
     `conductor(setup): Update workflow.md to <sha>`.
4. No clean-working-tree precondition. Unlike `/setup`'s brownfield
   classification (which reasons about the whole project state and so
   needs a clean baseline), `/update` only ever reads and writes one
   known file and stages only that file — unrelated dirty state
   elsewhere in the repo cannot be swept into its commit, so gating on
   it would add friction with no safety benefit.

### 4. `/status` staleness nudge

`.opencode/command/status.md` gains one additional report line,
computed the same way as `/update`'s check (read both markers, compare):

- Stale: `Workflow doctrine: stale (installed <sha>, project <sha>) —
  run /conductor/update`
- Current: `Workflow doctrine: up to date (<sha>)`

This is purely additive to `status.md`'s existing per-track progress
report — no other status logic changes.

### 5. `/revert` — no change needed

The update commit (`conductor(setup): Update workflow.md to <sha>`) is
an ordinary commit like any other. `/revert`'s existing generic
mechanism (locate a commit, revert it) handles it with no
special-casing required.

## Interfaces / cross-file impact

- **`conductor/assets/workflow-template.md`** *(new)* — canonical
  workflow doctrine content, extracted from `setup.md` step 7. This
  repo's own `conductor/workflow.md` (used for dogfooding this port on
  itself) is not produced by `install.sh`/`setup.md`'s copy step — it
  is the source tree, not an installed target — so it is kept
  byte-identical to `workflow-template.md` by hand and carries no
  version marker (see Layer 1 check below).
- **`.opencode/command/setup.md`** — step 7 changed from inlining
  content to copying `workflow-template.md` (§1). No doctrine text
  changes.
- **`install.sh`** — computes the current commit SHA and appends the
  version marker when copying `workflow-template.md` into the installed
  command directory (§2).
- **`.opencode/command/update.md`** *(new)* — implements §3.
- **`.opencode/command/status.md`** — gains the staleness report line
  from §4.
- **`.opencode/command/revert.md`** — no change (§5).
- **`README.md`** — add `/conductor/update` to the command reference
  table alongside the other lifecycle commands.

## Testing / verification approach

Same two-layer convention as prior specs in this repo (see
`docs/superpowers/specs/2026-08-21-phase-auto-checkpoint-design.md` and
earlier): static checks plus behavioral fixture runs, since these are
markdown protocols interpreted by an LLM.

### Layer 1 — Static checks

- `conductor/assets/workflow-template.md` exists and its content
  matches `conductor/workflow.md` byte-for-byte (minus the trailing
  version marker, which only the installed/target copies carry — this
  repo's own dogfooding copy does not need one).
- `setup.md` step 7 no longer contains an inlined fenced workflow block;
  it copies from `workflow-template.md` instead.
- `install.sh` computes and appends the `<!-- conductor-workflow-version:
  <sha> -->` marker when installing the workflow template.
- `update.md` exists, reads both markers, and contains the match/stale
  branches from §3.
- `status.md` contains the staleness report line from §4.
- `revert.md` has no new content referencing workflow-update commits
  (confirms §5 — no special-casing was added).

### Layer 2 — Behavioral fixture runs

`opencode run --command <name> "<args>" --dir <fixture>` against
disposable git fixtures under `/tmp`, asserting on ground truth
(resulting file content, commit history), not eyeballing.

| Scenario | Fixture precondition | Mechanical assertion |
|---|---|---|
| Up to date, no-op | Target repo's `workflow.md` marker matches the installed template's marker | `/update` reports up to date; `git log` shows no new commit; `workflow.md` unchanged |
| Stale, user approves | Target repo's `workflow.md` has an older marker (or a hand-edited older-doctrine body) | `/update` shows a diff, asks for confirmation; on yes, `workflow.md` now byte-matches the installed template, a commit `conductor(setup): Update workflow.md to <sha>` exists staging only `workflow.md` |
| Stale, user declines | Same as above | `/update` makes no file changes and no commit when the user answers no |
| Missing marker (pre-feature repo) | Target repo's `workflow.md` has the old inlined-era content with no marker line at all | `/update` treats it as stale (not an error) and offers the same diff/confirm flow |
| Unrelated dirty tree | Target repo has an unrelated uncommitted file change elsewhere, plus a stale `workflow.md` | `/update` still runs (no clean-tree precondition); the resulting commit stages only `workflow.md`, and the unrelated dirty file remains uncommitted and untouched afterward |
| `/status` nudge | One fixture with a stale marker, one with a matching marker | `/status` output contains the exact stale-format line for the first and the exact up-to-date line for the second |

## Risks / trade-offs

- **Depends on `workflow.md` staying a pure, zero-customization
  mirror.** If a future change reintroduces per-project customization
  (see "Deferred" below) without revisiting this design, whole-file
  overwrite becomes unsafe and `/update` would need to change to a
  merge/diff-and-preserve model instead of blind overwrite.
- **No coverage for style guides or other partially-customized
  artifacts.** A team relying on this feature to also catch up
  `code_styleguides/*` will find it out of scope; explicitly deferred,
  not silently dropped (see Non-goals).
- **Marker is advisory text, not enforced.** A user could hand-edit the
  marker line itself (e.g. copy-paste an old SHA) and fool the
  staleness check. Accepted — this mirrors the same trust model as
  every other plain-text tag in this port's doctrine (e.g.
  `[manual-checkpoint]`, `[checkpoint: <sha>]`), which are all
  editable, auditable git-tracked text rather than tamper-proof state.

## Alternatives considered

- **Add a real customization interview to `setup.md` step 7** (matching
  upstream's model) and drop the need for `/update` entirely, since
  legitimate per-project divergence would mean there's nothing to sync
  toward. Rejected for now: none of upstream's three actual knobs
  (coverage percentage, commit frequency, summary storage) transplant
  cleanly onto this port's current `workflow.md` — two of the three
  would regress documented, deliberate improvements over upstream
  (the per-task-type test enforcement table replacing a flat coverage
  percentage; git-notes-only replacing commit-body summaries — both
  called out in `docs/gemini-parity-gaps.md`'s "Port improvements over
  upstream" section). The third (commit frequency) is wired deeply
  enough into `implement.md`/`review.md`'s step-by-step mechanics that
  making it configurable is a materially larger change than a
  `workflow.md` split. See "Deferred" below for candidate knobs that
  might genuinely fit this port, preserved for future reconsideration
  rather than built now.

## Deferred: workflow.md customization knobs

Not built in this design. `workflow.md` remains a pure, zero-customization
mirror. Preserved here so the idea isn't lost if a real per-project need
surfaces later. Candidate knobs, ordered by cost/risk:

1. **Commit message convention** *(low cost)* — pure string-template
   substitution (e.g. conventional-commits `feat(scope): ...` vs.
   ticket-prefixed `PROJ-123: ...` vs. gitmoji). No mechanics change,
   just a different template value read by `implement.md`/`review.md`.
2. **Task-type taxonomy extension** *(low-medium cost)* — let a team
   append rows to the test-enforcement table (e.g. `infra`,
   `schema-migration`, `data-pipeline`) instead of always hitting the
   `[needs classification]` escape hatch for task types the built-in
   five (`backend-logic`, `api-client`, `api-contract`, `frontend-ui`,
   `e2e-flow`) don't cover. Likely a recurring pain point for
   infra-heavy or data-pipeline-heavy stacks.
3. **Test-first vs. test-after threshold per task type** *(medium
   cost)* — same table structure, different enforcement values (e.g. a
   team that trusts `api-contract` enough to always test-after). No new
   code paths in `implement.md`, just different table contents it
   already reads generically.
4. **Phase checkpoint pause frequency** *(higher cost)* — e.g. "pause
   every N phases" instead of always-per-phase. Note: this overlaps with
   the already-shipped `[manual-checkpoint]` per-phase tagging feature
   (`docs/superpowers/specs/2026-08-21-phase-auto-checkpoint-design.md`),
   which already gives fine-grained per-phase control. Adding a
   track-wide frequency knob on top would need explicit reconciliation
   with that mechanism, not an independent addition.
5. **Squash vs. two-commit-per-task strategy** *(highest cost)* — some
   teams have a strict one-commit-per-task or squash-merge culture and
   would find the current two-commits-per-task-plus-one-per-checkpoint
   pattern noisy. This is not a `workflow.md` text edit — it's wired
   through `implement.md` step 2d, `review.md`'s correction loop, and
   the SHA-recording contract that `/revert` and `/status` depend on.
   Would require a parallel commit-strategy implementation, not a
   template change.

If any of these are pursued later, revisit this design's "Risks" section
first — introducing real customization changes `/update`'s safety
assumption (blind whole-file overwrite) and likely requires a
diff-and-preserve or merge model instead.
