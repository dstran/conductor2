# Workflow

This file defines *how* work gets done on this project: methodology,
test enforcement, and commit conventions. `/implement` and `/review`
both read this file before acting — it is binding, not a suggestion.

## Test enforcement by task type

Every task in a track's `plan.md` must be tagged with one of the
types below. `/new-track` adds the initial tags before plan approval,
and `/review` must tag any tasks it appends in a `Review Fixes`
phase before those fixes are implemented.

| Task type | Enforcement | Rationale |
|---|---|---|
| `backend-logic` (services, business logic, utility functions) | **Strict test-first** | Contract is knowable up front; test-first improves interface design |
| `api-client` (calls to an external or internal API, e.g. an Angular service) | **Strict test-first** | Request/response shape is known before the call is written |
| `api-contract` — interface already specified in `plan.md` | **Test-first** | Same reasoning as above |
| `api-contract` — interface still exploratory | **Test-after** (still required) | Forcing test-first here produces guesses that get rewritten |
| `frontend-ui` — component logic (state, handlers, computed values) | **Test-after** (test-first optional) | Logic is testable but often clarified while building |
| `frontend-ui` — styling/layout only | **No test required** | No behavioral signal; overhead with no payoff |
| `e2e-flow` | **Test-after only — never test-first** | Depends on rendered UI/selectors that don't exist yet |

If a task doesn't cleanly fit one of these, the agent should flag it
in `plan.md` with `[needs classification]` and ask the user, rather
than guessing.

## The strict test-first loop

For any task enforced as test-first:

1. Write the test. It must fail.
2. Run it. Confirm it fails for the *right* reason (missing
   implementation — not a typo, bad import, or config error).
3. Implement the minimum needed to pass.
4. Run the test again. Confirm it passes.
5. Mark the task `[x]` in `plan.md` only after step 4 succeeds.

The agent must not skip step 2. A test that was never confirmed to
fail first is not verified TDD — it's just a test written early.

## The test-after loop

For tasks enforced as test-after (still required):

1. Implement the task.
2. Write the test.
3. Run it. Confirm it passes.
4. Mark the task `[x]` in `plan.md`.

## Coverage expectations

- Every `backend-logic` and `api-client` task must have at least one
  passing unit test before the task is marked complete.
- `e2e-flow` tasks are validated once, at the end of the track during
  `/review` — not per-task.
- No task is marked `[x]` on the strength of an assumption that a
  test "would" pass. It must have actually been run.

## Task commit procedure

Every task, once its test-first/test-after loop (per the enforcement
table above) has actually passed, is committed in exactly two steps —
whether the task came from `/new-track`'s original plan or from
`/review`'s appended "Review Fixes" phase (see `review.md`'s correction
loop). This procedure is the single source of truth for both:

1. **Task code commit.** Stage the code and test changes for this task
   only. Commit with a short conventional message describing the change
   (e.g. `feat(auth): Add login endpoint`). Get its SHA:
   `git log -1 --format=%h`.
2. **Task plan-update commit.** Edit `plan.md`: change the task's
   checkbox from `[~]` to `[x]` and append the task's type tag and the
   7-character SHA from step 1, producing exactly:
   `- [x] Task: <description> [<task-type>] <sha>`
   Stage only `plan.md` and commit with message
   `conductor(plan): Mark task '<task>' as complete`.

Never combine these into one commit, and never write the SHA into
`plan.md` before the code commit exists — the SHA must reference a real,
already-made commit.

## Phase checkpoint procedure

Every phase heading in `plan.md` is either tagged `[manual-checkpoint]`
or left untagged. `/new-track` sets this tag at plan-generation time
based on its tagging heuristic (see `new-track.md`); the user may add or
remove the tag by hand at any point before `/implement` reaches that
phase's checkpoint step. `/implement` reads the heading fresh each time
it reaches this step — it has no memory of a tag that was later removed,
and it never adds the tag itself.

- **Tagged `[manual-checkpoint]`:** `/implement` pauses at the end of the
  phase, presents a summary, asks "does this meet expectations?", and
  only checkpoints the phase after an explicit yes (looping on feedback
  the same way `/review` does, including the same 3rd-round nudge).
  Nothing beyond a phase checkpoint is finalized without that.
- **Untagged (the default):** `/implement` runs the phase's tests,
  presents the same summary plus the line "No manual checkpoint
  required — auto-checkpointing," and proceeds straight to checkpointing
  — no pause, no wait for a reply.

Once a phase is ready to checkpoint (explicit yes for a tagged phase;
immediately for an untagged phase):

1. Identify the last task code commit made in this phase (from step 1 of
   the task commit procedure above, for the phase's final task). Do NOT
   create a new empty commit — the checkpoint always points at an
   existing task commit.
2. Attach the phase summary (automated test results + manual verification
   steps, if any) as a **git note** on that commit — not in a commit
   message body: `git notes add -m "<summary>" <sha>`
3. Edit `plan.md`: append `[checkpoint: <sha>]` to the phase's heading —
   after any existing `[manual-checkpoint]` tag — producing exactly:
   `## Phase <N>: <title> [checkpoint: <sha>]` (untagged phase), or
   `## Phase <N>: <title> [manual-checkpoint] [checkpoint: <sha>]`
   (tagged phase). Stage only `plan.md` and commit with message
   `conductor(plan): Mark phase '<N> — <title>' as complete`.

Once all phases are checkpointed, `/implement` stops and hands off to
`/review` for the track-level pass: full test suite, style, security, and
plan compliance across the whole track. `/review` has its own
pause-and-ask gate before the final track-closure commit is made.
`/implement` never invokes `/review` itself — regardless of how many
phases in the track were tagged, the user must separately run
`/review <track_id>`.

## Commit strategy

- `/implement` and `/review` both follow the **task commit procedure**
  above for every task they complete (two commits per task: code, then
  plan update) and the **phase checkpoint procedure** above at the end of
  each phase (one plan-only commit per phase, referencing the last task
  commit — never a new empty commit).
- `/review` makes the final approval-gated track closure commit after
  its full-track pass, including any review-loop fixes and the
  `tracks.md` move to complete.
- Commit messages stay short and clean: task code commits are
  conventional (`feat(...)`, `fix(...)`, etc.); task plan updates use
  `conductor(plan): Mark task '<task>' as complete`; phase plan updates
  use `conductor(plan): Mark phase '<N> — <title>' as complete`; review
  closure uses a concise `conductor(track): <title>` summary with the
  track ID.
- Attach the phase summary or full review report to the corresponding
  commit as a **git note**, not in the commit message body. This keeps
  `git log` readable while preserving a complete, auditable record.
- No task plan-update commit happens before that task's test(s) have
  actually run and passed. No phase plan-update commit happens before the
  user has explicitly approved the current phase summary. No final
  closure commit happens before `/review` has run and the user has
  explicitly approved the current `review.md` after any correction loop.
