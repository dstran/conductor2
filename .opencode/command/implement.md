---
description: Implement a Conductor track phase-by-phase, following conductor/workflow.md's TDD enforcement, with per-phase checkpoints and in-flight corrections
agent: build
---

@conductor/index.md
@conductor/workflow.md
@conductor/tracks.md
@conductor/tracks/$ARGUMENTS/plan.md
@conductor/tracks/$ARGUMENTS/spec.md

`/implement` is the third step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first to confirm the project context and track infrastructure before implementing the selected track.

You are implementing track `$ARGUMENTS`. Confirm that `conductor/tracks.md` already contains the selected track and that its `spec.md` and `plan.md` already exist before starting work.

If the handshake, track registry entry, `spec.md`, or `plan.md` is missing, stop and direct the workflow back to `/setup` or `/new-track` as appropriate.
Do not create a new track during `/implement` unless the user explicitly asked to recover missing track state in this Conductor maintenance repo.

`plan.md` is organized into phases, each with its own tasks. Follow this protocol exactly.

## 1. In-flight corrections (applies throughout, at any point below)
If the user sends a message while you are actively implementing a
task — a correction, a different approach, a spotted mistake — treat
it as an immediate instruction, not something to defer to the next
checkpoint or `/review`. Adapt the current task right away, then
verify the fix using the same test-first/test-after loop from
`conductor/workflow.md` that the task's type requires before marking it done.
Do not wait for phase-end or track-end to act on it.

## 2. Work through the current phase
For each task in the current phase, in order:
   a. Check its type tag (`backend-logic`, `api-client`,
      `api-contract`, `frontend-ui`, `e2e-flow`) against the
      enforcement table in `conductor/workflow.md`.
   b. If the task has no type tag, stop and ask the user to
      classify it before proceeding — do not guess.
   c. Follow the strict test-first loop or test-after loop from
      `conductor/workflow.md`, matching the task's enforcement level exactly.
      Do not skip the "confirm it fails first" step for test-first
      tasks.
   d. Mark the task `[~]` in `plan.md` while in progress, `[x]` only
      after its test(s) actually run and pass.
   e. If a task turns out to be blocked (missing dependency, unclear
      requirement, conflicts with `spec.md`), stop immediately and
      report the blocker. Do not skip ahead to later tasks or into
      the next phase.

## 3. Phase checkpoint (trigger this the moment a phase's last task is `[x]`)
Do not silently continue to the next phase. Instead:
   a. Identify the git commit SHA at the start of this phase (from
      the previous phase's checkpoint note, or the track's first
      commit if this is phase 1). Scope everything below to files
      changed since that point.
   b. Run the automated tests relevant to this phase's changes
      (not necessarily the full suite — that's `/review`'s job at
      track end).
   c. If anything in this phase can't be confirmed by an automated
      test (e.g. requires a running server, a manual UI check, an
      external service), write out explicit manual verification
      steps — exact commands to run and what result confirms success.
   d. Present a short phase summary to the user: what was built,
      automated test results, and any manual verification steps.
      Ask: "Does this meet expectations? Reply yes to checkpoint and
      continue, or tell me what to change." PAUSE and wait.
   e. If the user gives feedback: fix it in place (using the correct
      test-first/test-after loop for what changed), re-run only the
      checks that fix could affect, and re-present the phase summary.
      Loop until they say yes. No round cap, same as `/review`'s
      correction loop — but note if this is the 3rd+ round on the
      same file or area, same as `/review` does.
   f. On explicit yes: commit with message
      `conductor(checkpoint): Checkpoint end of Phase <N> — <title>`.
      Attach the phase summary (test results + manual verification
      steps) as a **git note** on that commit — not in the commit
      body. If no files changed in this phase, commit empty rather
      than skipping the checkpoint.
   g. Move to the next phase and repeat from step 2. If this was the
      last phase, go to step 4.

## 4. Track complete
Once every phase has its own checkpoint commit:
   - Do NOT run the full-suite/style/security review yet — that's
     `/review`'s job, across the whole track.
    - Do NOT do a final "track" commit here — the phase checkpoints
      already capture the implementation work; `/review` owns the
      final approval-gated closure commit for any review-loop fixes
      plus the `tracks.md` move to complete.
   - Update `conductor/tracks.md` using the exact awaiting-review
     encoding defined there: keep the track entry in `## Active` as
     `[~]` and add the note `Status: implementation complete —
     awaiting review.` directly below it.
   - Tell the user the track is ready for `/review $ARGUMENTS`.

## 5. If you stop early due to a blocker
Leave completed tasks `[x]`, phases with completed checkpoints as
checkpointed, and the blocked task as `[~]` with a note explaining
why — so the user can resume with the same command after resolving
it, picking back up mid-phase rather than restarting it.

Report back a short summary after each phase checkpoint and at track
completion: tasks/phases completed, tests written (by type), and
anything that needed a judgment call.
