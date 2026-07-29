# `/review` Archive Step (Upstream-Exact) — Design

## Goal

Replace the port's persistent `## Completed` registry model with upstream
Gemini Conductor's **Archive / Delete / Skip** cleanup step, so that after a
track is approved in `/review` the user can move its folder to
`conductor/archive/<track_id>/`, delete it, or leave it in place.

## Background

Upstream `conductor-review` §3.3 (Track Cleanup) offers a multiple-choice menu
after approval:

- **Archive:** move the track folder to `conductor/archive/` and remove the
  entry from the tracks registry; commit `chore(conductor): Archive track '<id>'`.
- **Delete:** after a Yes/No irreversibility warning, delete the folder and
  remove the entry; commit `chore(conductor): Delete track '<id>'`.
- **Skip:** leave the track as is.

Upstream has no persistent completed list — archived tracks leave the registry
entirely.

The port currently diverges: `/review` step 9 moves the entry to a `##
Completed` section and marks it `[x]`, leaving the folder in
`conductor/tracks/`. `conductor/tracks.md` defines a `## Completed` section,
`.opencode/command/status.md` summarizes "completed" tracks, and
`.opencode/command/setup.md:173` tells setup to create a `## Completed` section
in a new registry.

## Decisions

1. **Adopt upstream's model exactly.** Drop the persistent `## Completed`
   section in favor of Archive / Delete / Skip.
2. **Mark `[x]` in place, then show the menu.** On approval, `/review` first
   marks the track `[x]` and removes the awaiting-review note, leaving it in
   `## Active`; then it presents Archive / Delete / Skip.
3. **Separate archive commit.** The approval closure (review-loop fixes + `[x]`
   marking, with the `review.md` git note) is one commit; the chosen
   Archive/Delete action is a second, separate commit.
4. **Update dependent docs for consistency.** `tracks.md`, `status.md`, and
   `setup.md` are updated so nothing references a `## Completed` section that
   no longer exists.

## Changes

### `.opencode/command/review.md` — rewrite step 9

Replace the current step 9 ("move to `## Completed`") with:

**9. After explicit approval only — closure commit**
1. Re-run the full test suite one final time.
2. Mark the track `[x]` in `conductor/tracks.md` and remove the awaiting-review
   note. The entry stays in `## Active`.
3. Stage and commit the review-loop fixes (if any) plus the `[x]` marking with
   a short message following `conductor/workflow.md`'s commit strategy, e.g.
   `conductor(track): <track_id> <title>`.
4. Attach the full verification report as a git note on that commit (not the
   message body):
   `git notes add -m "$(cat conductor/tracks/$ARGUMENTS/review.md)" <commit-sha>`.

**10. Track cleanup**
Ask the user, with a multiple-choice question, what to do with the track:
- **Archive:** ensure `conductor/archive/` exists; move
  `conductor/tracks/$ARGUMENTS/` to `conductor/archive/$ARGUMENTS/`; remove the
  track entry from `conductor/tracks.md`; stage and commit
  `chore(conductor): Archive track '$ARGUMENTS'`; announce that the track was
  archived.
- **Delete:** ask a Yes/No question warning that this is an irreversible
  deletion. On yes, delete `conductor/tracks/$ARGUMENTS/`, remove the entry
  from `conductor/tracks.md`, and commit `chore(conductor): Delete track
  '$ARGUMENTS'`. On no, fall back to leaving the track in place.
- **Skip:** leave the `[x]` entry in `## Active` and the folder in
  `conductor/tracks/` unchanged; no second commit.

### `conductor/tracks.md` — drop the Completed model

- Remove the `## Completed` section and its comment.
- Remove the "Complete: place the track in `## Completed` as `[x]`" encoding
  line.
- Keep `## Active` (which now also holds `[x]` skipped-complete tracks) and
  `## Blocked`.
- Update the `[x]` legend to: "`[x]` means complete; a completed track stays in
  `## Active` as `[x]` unless it is archived or deleted."
- Add a short note documenting that `/review` can move a completed track's
  folder to `conductor/archive/<track_id>/` and remove its registry entry.

### `.opencode/command/status.md` — stop referencing Completed

- Update the description and body so `/status` summarizes **active, blocked,
  and archived** tracks: read `## Active` and `## Blocked` from
  `conductor/tracks.md`, and list archived tracks from `conductor/archive/`
  (if it exists). No `## Completed` reference.

### `.opencode/command/setup.md` — stop creating Completed

- Change the `tracks.md` creation instruction so the registry skeleton contains
  only `## Active` and `## Blocked` sections (plus the header and
  lifecycle-encoding notes). Remove `## Completed` from that instruction.

## What stays unchanged

- `.opencode/command/implement.md` and `.opencode/command/revert.md`: their
  `[x]` references are `plan.md` task markers, not the registry, and are
  unaffected.
- `skill/SKILL.md`: its review wording ("verifies the completed track and
  closes it only after explicit approval") is generic and remains accurate.
- Steps 1-8 of `review.md` (plan compliance, quality, style, security, tests,
  report, pause, correction loop).

## Non-Goals

- Changing the `/revert` or `/implement` doctrine.
- Adding an "un-archive" or archive-listing command beyond `/status` listing
  the archive directory.

## Verification

This is a command-doc/registry change with no runtime code. Verify by
read-through plus grep:

1. No `## Completed` reference or "Completed section" wording remains in
   `.opencode/command/*.md` or `conductor/tracks.md`.
2. `review.md` contains the Archive / Delete / Skip menu, the
   `conductor/archive/$ARGUMENTS/` move, the registry-entry removal, and the
   separate `chore(conductor): Archive track` / `chore(conductor): Delete
   track` commits.
3. `review.md` still marks the approved track `[x]` in `## Active` with the
   closure commit + git note before the menu.
4. `tracks.md` has only `## Active` and `## Blocked` sections and documents the
   `conductor/archive/<track_id>/` location.
5. `status.md` summarizes active/blocked/archived, not completed.
6. `setup.md` creates a registry with only `## Active` and `## Blocked`.
