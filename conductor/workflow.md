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

## Manual review gate

`/implement` pauses at the end of every phase, presents a summary,
asks "does this meet expectations?", and only commits that phase's
checkpoint after an explicit yes (looping on feedback the same way
`/review` does, including the same 3rd-round nudge). Nothing beyond
a phase checkpoint is finalized without that.

Once all phases are checkpointed, `/implement` stops and hands off
to `/review` for the track-level pass: full test suite, style,
security, and plan compliance across the whole track. `/review` has
its own pause-and-ask gate before the final track-closure commit is
made.

## Commit strategy

- `/implement` makes one checkpoint commit per approved phase.
- `/review` makes the final approval-gated track closure commit after
  its full-track pass, including any review-loop fixes and the
  `tracks.md` move to complete.
- Commit messages stay short and clean: phase checkpoints use
  `conductor(checkpoint): Checkpoint end of Phase <N> - <title>`;
  review closure uses a concise `conductor(track): <title>` summary
  with the track ID.
- Attach the phase summary or full review report to the corresponding
  commit as a **git note**, not in the commit message body. This keeps
  `git log` readable while preserving a complete, auditable record.
- No checkpoint commit happens before the user has explicitly approved
  the current phase summary.
- No final closure commit happens before `/review` has run and the
  user has explicitly approved the current `review.md` after any
  correction loop.
