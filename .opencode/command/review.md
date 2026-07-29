---
description: Run Conductor's automated review on a track in the awaiting-review state, then wait for explicit manual approval before finalizing
agent: build
---

@conductor/workflow.md
@conductor/index.md
@conductor/tracks.md
@conductor/tracks/$ARGUMENTS/spec.md
@conductor/tracks/$ARGUMENTS/plan.md

`/review` is the final step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first to confirm the project context and track infrastructure before reviewing the selected track.

You are reviewing track `$ARGUMENTS`, which `/implement` should have left in the exact awaiting-review state defined in `conductor/tracks.md`: the track stays in `## Active` as `[~]` with the note `Status: implementation complete — awaiting review.` directly below it.
If that handshake, track entry, awaiting-review note, `spec.md`, or `plan.md` is missing, stop and direct the workflow back to `/setup`, `/new-track`, or `/implement` as appropriate rather than treating the track as ready to close.

Do the following, in order, and do not skip any step:

## 1. Plan compliance check
Diff the current working tree against the state before this track
started. For every task in `plan.md`, confirm the corresponding code
change actually exists and matches what `spec.md` asked for. Flag any
task marked `[x]` that isn't actually reflected in the diff.

## 2. Code quality / deep logic analysis
This is separate from the style check below — it's about correctness,
not formatting. Go beyond syntax and look for: race conditions in
async/concurrent code, null/undefined dereference risks, off-by-one
and boundary errors, unhandled error paths, resource leaks (unclosed
connections/handles), and logic that technically runs but doesn't
match the intent in `spec.md`. Flag each with file, line, and a short
explanation of the failure mode — not just "this looks risky."

## 3. Style and guideline check
If `conductor/code_styleguides/` exists, check the new/changed files
against it. Flag deviations — don't silently fix them, report them.

## 4. Security pass
Scan the diff for: hardcoded API keys or secrets, credentials in
plaintext, PII appearing in logs or committed files, and obvious
injection risk (unsanitized input reaching a query, shell command, or
template render).

## 5. Full test suite
Run the entire test suite for the project — not just the tests added
in this track. Confirm everything passes, including previously
existing tests (regression check).

## 6. Write the report, with severity
Write your findings to `conductor/tracks/$ARGUMENTS/review.md` with
sections: Plan Compliance, Code Quality, Style/Guidelines, Security,
Test Results. Within each section, tag every flagged issue High,
Medium, or Low:
   - **High**: breaks functionality, a security exposure, or directly
     contradicts `spec.md`/`plan.md`. Recommend against finalizing
     until resolved.
   - **Medium**: a real problem (a logic edge case, a style violation
     with a maintainability cost) that doesn't block correctness today.
   - **Low**: minor/cosmetic, worth mentioning, not worth blocking on.
A section with no issues is marked clean, not omitted. Every issue
needs a file and line — not just "looks fine" or "some concerns here."

## 7. Pause and ask — do not proceed without an explicit yes
Do NOT commit. Do NOT mark the track as done in `tracks.md`. Present
the report to the user, leading with any High severity findings if
present. Ask directly: "Does this meet your expectations? Reply yes
to finalize, or tell me what to change." PAUSE. Wait for their reply.
Never treat silence, a vague reply, or your own judgment that "it's
probably fine" as approval — and never soften a High finding to make
the track look more ready than it is.

## 8. The correction loop (repeat until the user says yes)
If the user gives feedback instead of approving:
1. Treat it as a new set of tasks. Append a "Review Fixes" phase to
   `plan.md` describing exactly what they asked for. Tag each appended
   fix task with the same task-type labels required by
   `conductor/workflow.md`; use `[needs classification]` if unclear.
   If any appended fix task is marked `[needs classification]`, pause
   and ask the user to classify it before implementing the fix.
2. Apply the same TDD enforcement from `conductor/workflow.md` to each fix
    (a backend fix still gets a test-first treatment, etc.).
3. Re-run the specific checks from steps 1–5 above that the fix
   could have affected — not necessarily the entire review from
   scratch, but don't skip a check just because it passed last time
   if this fix touches that area.
4. Update `review.md` with the new findings, keeping severity tags.
5. Before returning to step 7, check: is this the 3rd or later round
   of feedback touching the same file or area? If so, say so plainly
   to the user — e.g. "this is the third round of fixes in
   `auth-service.ts` — worth checking whether the underlying approach
   needs to change rather than another patch." This is a nudge, not
   a gate: keep looping either way, the user decides what to do with
   the observation.
6. Return to step 7. Ask again. Do not assume the second pass is
   the last one — loop for as many rounds as the user needs, with
   no cap.

## 9. After explicit approval only — closure commit
1. Re-run the full test suite one final time.
2. Mark the track complete in `conductor/tracks.md`: remove the
   awaiting-review note and change the track entry to `[x]`. The entry
   stays in `## Active` — there is no separate completed section.
3. Stage and commit the review-loop fixes (if any) plus the
   `conductor/tracks.md` `[x]` marking with a short, clear summary
   message following `conductor/workflow.md`'s commit strategy
   (e.g. `conductor(track): <track_id> <title>`).
4. Attach the full verification report as a **git note** on that
   commit — not in the commit message body:
   `git notes add -m "$(cat conductor/tracks/$ARGUMENTS/review.md)" <commit-sha>`
   This keeps the commit message short while preserving a full,
   auditable record attached to the commit itself.

## 10. Track cleanup
Ask the user, with a multiple-choice question, what to do with the
now-completed track:
   - **Archive:** move the track out of the working tree, keeping it for
     the record.
   - **Delete:** permanently remove the track folder.
   - **Skip:** leave the track in place.

Then act on the choice:
   a. **Archive:** ensure `conductor/archive/` exists, then move
      `conductor/tracks/$ARGUMENTS/` to `conductor/archive/$ARGUMENTS/`.
      Remove the track's entry from `conductor/tracks.md`. Stage the move
      and the registry edit and commit with the message
      `chore(conductor): Archive track '$ARGUMENTS'`. Tell the user the
      track was archived. This is a separate commit from the step 9
      closure commit.
   b. **Delete:** ask a Yes/No question warning that this is an
      irreversible deletion. On yes, delete `conductor/tracks/$ARGUMENTS/`,
      remove the track's entry from `conductor/tracks.md`, and commit with
      the message `chore(conductor): Delete track '$ARGUMENTS'`. On no,
      treat it as Skip.
   c. **Skip:** leave the `[x]` entry in `## Active` and the folder in
      `conductor/tracks/` unchanged. No second commit.
