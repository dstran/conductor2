---
description: Summarize active, blocked, and archived Conductor tracks with real progress computed from each track's plan.md
agent: build
---

@conductor/tracks.md

Read `conductor/tracks.md`, then for every track listed under `## Active`
and `## Blocked`, resolve and read that track's `plan.md` (link given in
the registry entry). Do not edit product code.

## 0. Discover sibling track worktrees

Run `git worktree list` to enumerate every worktree attached to this
repository, not just the current one. For each worktree other than the
current one, check whether it has its own `conductor/tracks.md` and
`conductor/tracks/*/metadata.json` files (a track worktree created by
`/conductor/new-track`'s worktree-creation step). Read each discovered
worktree's `conductor/tracks.md` the same way Step 1 reads the current
one, so this command's view spans every track currently in flight
across all worktrees, not only the invoking worktree's own registry.
Skip any worktree that has no `conductor/` directory (not a Conductor
track worktree — e.g. an unrelated feature-branch worktree).

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

## 2.5. Cleanup-ready worktrees

For each sibling worktree discovered in Step 0 (and the current one, if
it has recorded worktree metadata), read its track's `metadata.json`
for `branch` and `baseRef`. For each such track:

- Compute `git log <baseRef>..<branch>`. If this is empty, the branch's
  commits are already fully contained in `baseRef` — the PR (if one
  was opened per `/conductor/review`'s Archive step) has been merged.
- If `gh` is available, cross-check with `gh pr view <branch> --json
  state` — a `MERGED` state also confirms this.
- Flag any track meeting either condition as **cleanup-ready**, and
  print the exact commands to remove it: `git worktree remove
  <worktreePath>`, followed by `git branch -d <branch>` and, if a
  remote copy exists, `git push origin --delete <branch>`.
- This is detection only — never run these commands automatically.
  The human decides when to actually clean up a merged worktree.

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
6. **Cleanup-ready worktrees:** the list flagged in step 2.5 — track,
   worktree path, and the exact removal commands — or "none" if no
   sibling worktree's branch is fully merged.
7. **Workflow doctrine line** from step 3, always shown last.

If `conductor/tracks.md` has no entries under `## Active` or `## Blocked`,
report that the registry is empty and skip steps 1 and 3.
