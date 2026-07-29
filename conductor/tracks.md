# Tracks Registry

This is the shared Conductor track registry consumed by `/new-track`,
`/implement`, `/review`, `/status`, and `/revert`.

Use one track entry per line in the format below and move the entry
between sections as its lifecycle changes:

`- [ ] **Track: <Track Description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

- `[ ]` means planned or ready to implement.
- `[~]` means the track is active but not complete yet. Use the exact
  note formats below when the state needs to be distinguished:
  - `Status: implementation complete — awaiting review.`
  - `Blocker: <short explanation>`
- `[x]` means complete. A completed track stays in `## Active` as `[x]`
  unless `/review` archives or deletes it.

Exact lifecycle encodings:

- Planned or ready to implement: place the track in `## Active` as `[ ]`.
- In progress: place the track in `## Active` as `[~]` with no note.
- Awaiting review: place the track in `## Active` as `[~]` with the
  note `Status: implementation complete — awaiting review.` directly
  below the track entry.
- Blocked: place the track in `## Blocked` as `[~]` with the note
  `Blocker: <short explanation>` directly below the track entry.
- Complete: mark the track `[x]` in `## Active`.
- Archived/Deleted: `/review` may move a completed track's folder to
  `conductor/archive/<track_id>/` (removing its registry entry) or delete
  it outright.

## Active

<!-- /new-track adds new entries here and links each entry to plan.md. -->

## Blocked

<!-- Move blocked track entries here as [~] and include the Blocker note below the entry. -->
