---
description: Summarize active, blocked, and archived Conductor tracks with real progress computed from each track's plan.md
agent: build
---

@conductor/tracks.md

Read `conductor/tracks.md`, then for every track listed under `## Active`
and `## Blocked`, resolve and read that track's `plan.md` (link given in
the registry entry). Do not edit product code.

## 1. Per-track progress

For each track's `plan.md`:

- Count total phases (`## Phase <N>: <title>` headings) and total tasks
  (lines starting `- [x] Task:`, `- [~] Task:`, or `- [ ] Task:`).
- Count completed tasks (`[x]`) and compute
  `completed/total (percentage%)`, rounded to the nearest whole percent.
- Identify the current in-progress task, if any (`[~]`).
- Identify the next pending task (the first `- [ ] Task:` line in
  document order).
- Note any phase heading missing a `[checkpoint: <sha>]` suffix even
  though every task inside it is `[x]` — flag this as an inconsistency
  (a checkpoint that should have happened but didn't get recorded).

## 2. Registry state per track

- **Active:** entries under `## Active`. Distinguish planned (`[ ]`),
  in progress (`[~]` with no note), awaiting review (`[~]` with the
  awaiting-review note), and completed-in-place (`[x]`).
- **Blocked:** entries under `## Blocked`, including each `Blocker:` note.
- **Archived:** if `conductor/archive/` exists, list the archived track
  directories inside it. These have been removed from the registry and
  have no live progress to report.

## 3. Workflow doctrine staleness

Compare the last line of `conductor/workflow.md` against the last line
of `~/.config/opencode/command/conductor/assets/workflow-template.md`
(same marker format `/conductor/update` reads: `<!-- conductor-workflow-version:
<sha> -->`). A missing marker on either side counts as not matching.

- If they match: the report line is `Workflow doctrine: up to date
  (<sha>).`
- If they differ (including a missing marker on the target): the report
  line is `Workflow doctrine: stale (installed <installed-sha>, project
  <project-sha-or-"none">) — run /conductor/update`.

## 4. Present the summary

Report, in this order:

1. **Current date/time.**
2. **Project status label** — `On Track` if at least one track has an
   in-progress or planned task and no track is `## Blocked`; `Blocked` if
   any track is under `## Blocked`; `Awaiting Review` if the
   furthest-along active track is in the awaiting-review state and none
   are blocked.
3. **Per active track:** track description, `completed/total
   (percentage%)`, current phase + current/in-progress task, next
   pending task, and any checkpoint inconsistency noted in step 1.
4. **Blockers:** every `Blocker:` note found under `## Blocked`.
5. **Archived tracks:** the list from step 2, or "none" if
   `conductor/archive/` doesn't exist.
6. **Workflow doctrine line** from step 3, always shown last.

If `conductor/tracks.md` has no entries under `## Active` or `## Blocked`,
report that the registry is empty and skip steps 1 and 3.
