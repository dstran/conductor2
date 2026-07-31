# Tier 1 Gemini Conductor Parity — Design

Implements Tier 1 of `docs/gemini-parity-gaps.md`: G1 (doc-sync), G6 (SHA
recording), G5 (revert mechanism), G4 (status progress), plus G12
(track-creation commit) pulled forward from Tier 2 because G5 depends on it.

## Problem

The port's `/implement`, `/status`, and `/revert` commands describe *intent*
("revert safely", "summarize status") without the mechanics upstream Gemini
Conductor actually has: SHA-annotated plan lines, doc-sync after a track
completes, plan-derived progress percentages, and full git reconciliation for
reverts. `/new-track` also never commits, so there's no anchor commit for a
full-track revert.

## Goals

- `plan.md` task lines and phase headings carry real, parseable commit SHAs.
- `/implement` proposes project-doc updates (`product.md`, `tech-stack.md`,
  `product-guidelines.md`) after a track's phases are all checkpointed.
- `/status` reports real progress: phase/task counts, percentage, current
  task, next action, blockers — computed from `plan.md`, not just registry
  entries.
- `/revert` can actually find and undo a task, phase, or whole track by
  reconciling `plan.md` SHAs against git history, with a Safe/Hard-reset
  choice and conflict handling.
- `/new-track` commits at creation so track-level revert has an anchor.

## Non-goals

- Tier 2 items other than G12 (per-track `index.md`, the broader
  commit-message convention overhaul like `chore(conductor): Mark track...`
  wording) and all of Tier 3 (skill catalog, review action-menu,
  UX-adapter rule, resume script) — out of scope for this pass. The one
  commit-message change made here (phase-checkpoint wording, §1) is a
  mechanical side effect of the commit no longer carrying code, not a
  deliberate G11 realignment.
- Changing the review/checkpoint approval-gate UX itself (still Yes/No +
  no-cap correction loop, unchanged).

## Design

### 1. Commit model change: per-task commits (prerequisite for everything else)

Today `workflow.md` documents **one commit per phase**. This changes to
**two commits per task** (matching upstream) plus **one plan-update commit
per phase checkpoint**.

**Ownership:** this is a procedural mechanic, not just a policy bullet, and
it must be followed identically by both `/implement` (normal tasks) and
`/review` (tasks in an appended "Review Fixes" phase) so that revert can
find *any* task's commits regardless of which command created them.
`conductor/workflow.md` therefore gains an explicit numbered "Task commit
procedure" (mirroring upstream's `assets/workflow.md` "Standard Task
Workflow"), and both `implement.md` and `review.md` defer to it by
reference instead of restating it. This is the same "workflow.md is
binding on both `/implement` and `/review`" principle the doctrine already
states — the procedure was previously only spelled out inline in
`implement.md`; now it moves to the shared file so `/review`'s fix tasks
aren't a special case.

The procedure, once per task:

1. **Task code commit** — conventional message (e.g. `feat(auth): Add login
   endpoint`), made immediately after the task's test-first/test-after loop
   (per its type tag) passes.
2. **Task plan-update commit** — `plan.md` only. Marks the task `[x]` and
   appends the 7-char SHA of commit (1). Message:
   `conductor(plan): Mark task '<task>' as complete`.

At phase end (existing checkpoint gate, unchanged: summary, automated
tests, manual verification steps, Yes/No, correction loop, 3rd-round nudge):

3. **Phase plan-update commit** — `plan.md` only. Appends `[checkpoint:
   <sha>]` to the phase heading, where `<sha>` is the last task commit in
   that phase (never a new empty commit). Message: `conductor(plan): Mark
   phase '<N> — <title>' as complete`. This message replaces the current
   `conductor(checkpoint): Checkpoint end of Phase <N> — <title>` wording —
   not a G11 convention realignment (still out of scope), but a mechanical
   necessity: this commit no longer carries code, only the plan-file
   update, so it needs to read as one.
4. The git note (test results + manual verification transcript) attaches to
   that same last-task-commit SHA — unchanged principle, just re-targeted
   since there's no longer a distinct phase-code commit to attach to.

**plan.md line formats (exact, matches upstream):**

- Task: `- [x] Task: <description> [<task-type>] <sha>`
- Phase heading: `## Phase <N>: <title> [checkpoint: <sha>]`

This is a breaking change to `conductor/workflow.md`'s documented commit
strategy. `implement.md`'s phase-checkpoint step and `review.md`'s
correction-loop step both get updated to defer to the new shared procedure
instead of restating commit mechanics inline.

### 2. G12: `/new-track` commits on creation

After the registry entry is appended (existing step 4) and before the
pause-for-approval step (existing step 5): stage
`conductor/tracks/<track_id>/` and `conductor/tracks.md`, commit
`chore(conductor): initialize track '<track_id>'`. This becomes the anchor
commit for full-track reverts.

### 3. G1: doc-sync step in `/implement`

New step 4 in `implement.md`, inserted after all phases are checkpointed
(current step 4 "Track complete") and before the existing awaiting-review
handoff (renumbers to step 5):

- Read the track's `spec.md`.
- For `product.md` and `tech-stack.md`, independently: assess whether the
  completed track materially changed what that file describes. If yes,
  present a diff-style proposed edit and ask a Yes/No question; apply only
  on explicit yes. If no material impact, state so briefly — do not ask a
  question.
- For `product-guidelines.md`: only propose a change if `spec.md` explicitly
  describes a branding/voice/tone/UX-philosophy shift. If so, present the
  diff with an explicit sensitivity warning, then a Yes/No. Otherwise skip
  silently (do not even state "no change" — this file is rarely touched and
  noting it every time is noise upstream doesn't produce either).
- If any file changed, stage them and commit:
  `docs(conductor): Synchronize docs for track '<track_id>'`. If nothing
  changed, no commit.

### 4. G4: `/status` parses plans and computes progress

Rewrite `status.md` to, for every track listed in `tracks.md` (`## Active`
and `## Blocked`):

- Resolve and read that track's `plan.md`.
- Parse phase headings (`## Phase <N>: <title>` with optional
  `[checkpoint: <sha>]`) and task lines (`[x]`/`[~]`/`[ ]`).
- Compute per-track: total phases, total tasks, completed tasks, the
  current in-progress task (if any), the next pending task, and
  `completed/total (percentage%)`.
- Roll up a project-level summary: current date/time, overall status label
  (On Track / Blocked / Awaiting Review — derived from registry state and
  whether any track has stalled `[~]` tasks with no recent movement),
  current phase+task across the active track being worked, next action
  needed, and any `Blocker:` notes from `## Blocked`.
- Preserve the existing archived-track listing from `conductor/archive/`.

### 5. G5: `/revert` — full mechanism

Rewrite `revert.md` into a numbered protocol:

1. **Handshake check** — `conductor/index.md` present; if not, offer to run
   `/setup` (Yes/No), same pattern as other commands.
2. **Target selection:**
   - Path A (`$ARGUMENTS` provided): resolve the referenced track/phase/task
     in `tracks.md` + the track's `plan.md`; confirm with Yes/No.
   - Path B (nothing provided): scan `tracks.md` and every track's
     `plan.md`; prioritize the top 3 most relevant `[~]` in-progress items;
     if none, fall back to the 3 most-recently-completed `[x]` items;
     present as a single-choice menu (max 4 options including "Other" via
     the `question` tool's built-in custom option). Loop back to Path A's
     confirmation once chosen.
3. **Git reconciliation** (uses the SHA formats from §1):
   - **Task:** the task's own commit SHA (from its `plan.md` line) + its
     plan-update commit (found via `git log` on `plan.md` immediately
     following that SHA).
   - **Phase:** the `[checkpoint: <sha>]` SHA, every task pair within that
     phase, and the phase's own plan-update commit.
   - **Track:** all phase-level items above for every phase in the track,
     plus the track-creation commit (`git log --grep="initialize track
     '<track_id>'"`, from §2).
   - **Ghost-commit handling:** if a recorded SHA is not found in `git log`
     (history rewritten), search for a commit with a highly similar message;
     ask Yes/No to substitute it; halt if declined.
   - Compile the final SHA list; flag merge commits or duplicate
     cherry-picks if found.
4. **Present the execution plan** — list every SHA and its message that
   will be reverted, in revert order (newest first).
5. **Strategy choice** (single-choice question):
   - **Safe (Recommended):** `git revert --no-edit`, newest → oldest.
   - **Hard Reset (Destructive):** `git reset --hard <base_sha>`, with an
     explicit warning about losing uncommitted changes and rewriting
     history.
6. **Execute:**
   - Safe: run each revert in order; on conflict, halt and give manual
     resolution instructions (do not force through).
   - Hard Reset: confirm the warning was acknowledged, then reset to the
     commit immediately before the earliest SHA in the list.
7. **Reconcile `plan.md`:** reset the reverted task(s)/phase(s) to `[ ]`,
   strip the SHA/`[checkpoint: ...]` annotation, remove the awaiting-review
   note if a whole track was reverted. Commit this correction:
   `conductor(plan): Reset '<target>' after revert`.
8. **Announce completion** — state what was reverted and the resulting
   `plan.md` state.

## Interfaces / cross-file dependencies

- `conductor/workflow.md` is the source of truth for the task commit
  procedure (§1); `implement.md` (normal tasks) and `review.md` ("Review
  Fixes" phase tasks) both defer to it by reference rather than restating
  it, so a task's commits look identical regardless of which command
  created it — required for revert to treat them uniformly.
- `revert.md` depends on the SHA formats from §1 and the track-creation
  commit from §2 — those must land first (or in the same change) or revert
  has nothing to parse.
- `status.md` depends only on the existing `[x]`/`[~]`/`[ ]` + phase-heading
  format, which is unaffected by the `[checkpoint: <sha>]` suffix (status
  ignores the suffix, just counts checkboxes).
- `new-track.md` §2 (G12) has no dependency on the others and can land
  independently.

## Testing / verification approach

These are markdown protocols interpreted by an LLM, not runtime code — so
"does it parse" (static check) and "does it behave" (live agent execution)
are different questions, and both are required. Grep alone only proves the
first.

### Layer 1 — Static checks

- Grep-based structural checks (exact strings/formats present, stale
  strings absent), same style as the precedent in
  `docs/superpowers/plans/2026-07-28-review-archive-step.md`.
- A read-through self-review confirming each command doc's numbered steps
  are internally consistent (step references, renumbering after insertions).
- Cross-file consistency check: commit message formats and SHA formats
  match verbatim everywhere they're referenced (`workflow.md`,
  `implement.md`, `review.md`, `revert.md`).

### Layer 2 — Behavioral checks (live agent runs against a disposable fixture)

`opencode run --command <name> "<args>" --dir <fixture>` resolves a
directory's **project-local** `.opencode/command/*.md` (confirmed: it does
not fall back to the globally-installed copy under
`~/.config/opencode/command/conductor/`, which may be stale). This makes it
possible to actually execute the edited command against known-state git
fixtures under `/tmp` and assert on ground truth — real `git log` entries,
real `plan.md` content, real file diffs — instead of trusting the doc's
prose.

Per changed command, one fixture-driven run whose outcome is checked
mechanically (`git log --oneline`, `grep` on the resulting `plan.md`,
`git diff`), not just read and eyeballed:

| Command | Fixture precondition | Mechanical assertion |
|---|---|---|
| `/new-track` (G12) | fresh `conductor/` from `/setup`, no tracks | `git log --oneline` contains a commit matching `chore(conductor): initialize track '<id>'` |
| `/implement` (G6 SHA format) | one approved track, 1 phase / 2 tasks | each `[x]` task line matches `- \[x\] Task: .* \[<sha>\]` and `<sha>` resolves via `git cat-file -e`; the phase heading contains `[checkpoint: <sha>]` for a real commit |
| `/implement` (G1 doc-sync, positive) | track whose `spec.md` clearly changes the tech stack | `tech-stack.md` is modified; `git log` contains `docs(conductor): Synchronize docs for track '<id>'` |
| `/implement` (G1 doc-sync, negative control) | track with no product/tech-stack/guidelines impact | `product.md`, `tech-stack.md`, `product-guidelines.md` are byte-identical to before the run; no `docs(conductor):` commit exists |
| `/status` (G4) | `plan.md` with a known, hand-crafted mix of `[x]`/`[~]`/`[ ]` (e.g. 2 of 5 tasks done) | reported completion is exactly `2/5 (40%)`; reported next-pending task matches the fixture's first `[ ]` line |
| `/revert` (G5, Safe strategy) | a track produced by a real `/implement` run (so task/phase/plan-update commits and SHAs are genuine) | after revert: target task/phase line is back to `[ ]` with no SHA/`[checkpoint]` annotation; `git log` shows new revert commits; `git diff <pre-task-sha> HEAD -- <touched files>` is empty |
| `/revert` (G5, ghost-commit path) | fixture where a recorded SHA has been rebased away | run halts with the ghost-commit Yes/No prompt rather than silently failing or fabricating a SHA |

Interactive Yes/No and single-choice prompts inside these runs are steered
by stating the intended answers directly in the `opencode run` message
(e.g. "approve every checkpoint and confirmation with yes"). Any
unexpected `permission requested` / tool-rejection / halt encountered
during a fixture run is itself a **failure** of that task, not something
to script around — it means the command doc caused the agent to attempt
something the fixture didn't anticipate or a tool it can't use unprompted.

Each implementation-plan task's "done" criteria includes both layers: the
static grep/consistency check AND the specific fixture run(s) from the
table above relevant to that task.

## Risks / trade-offs

- **More commits per track.** Two commits per task instead of one per phase
  meaningfully increases commit volume. This is the accepted cost of task-
  level revert granularity (explicitly chosen over keeping phase-only
  commits).
- **Doc-sync adds interaction overhead** to every track's completion (up to
  2 more Yes/No questions). Mitigated by skipping the question entirely
  when there's no material change to propose.
- **Revert is unavoidably complex.** Ghost-commit handling and Hard Reset
  are inherently risky operations; the design keeps upstream's explicit
  warnings and halts-on-ambiguity behavior rather than simplifying them
  away.
- **Behavioral fixture runs cost real tokens/time per task** (each is a
  live multi-turn agent session). Accepted because static checks alone
  cannot verify LLM-interpreted protocol behavior — this is the direct
  answer to "how do we know it adheres to the spec."
