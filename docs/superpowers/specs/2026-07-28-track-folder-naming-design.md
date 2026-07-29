# Concise Track Folder Names (`shortname_YYYYMMDD`) — Design

## Goal

Make `/conductor/new-track` create concise track folder names in the upstream
Gemini Conductor format `shortname_YYYYMMDD`, instead of using the raw user
input as the folder name.

## Problem

`.opencode/command/new-track.md` currently uses `$ARGUMENTS` verbatim as the
track folder name:

```
- conductor/tracks/$ARGUMENTS/spec.md
- conductor/tracks/$ARGUMENTS/plan.md
- conductor/tracks/$ARGUMENTS/metadata.json
```

So when a user types a descriptive phrase after the command, the entire phrase
becomes the literal folder name, producing long, awkward directories. There is
no track-ID generation step.

Upstream `conductor-new-track` (`skills/conductor-new-track/SKILL.md:144-146`)
instead generates a derived, unique Track ID `shortname_YYYYMMDD` that is
independent of the full description, and (`:142`) performs a collision check
before creating the directory.

## Scope

The change is localized to `.opencode/command/new-track.md`.

The downstream commands (`implement.md`, `review.md`, `revert.md`) already
treat their `$ARGUMENTS` as the track ID *to select* — they receive the short
ID from `conductor/tracks.md` and read `conductor/tracks/$ARGUMENTS/...`. They
require no changes: once `new-track` produces short IDs, the user passes those
short IDs to the downstream commands as before.

## Decisions

1. **Format:** `shortname_YYYYMMDD` — matches upstream exactly (shortname
   first, date at the end).
2. **Shortname derivation:** the agent derives a concise 2-4 word kebab-case
   slug from the track description and type (e.g. "Add user authentication with
   OAuth" → `user-auth`). Not the raw `$ARGUMENTS`.
3. **Collision check:** ported from upstream — before creating the directory,
   list existing dirs in `conductor/tracks/`; if the generated
   `shortname_YYYYMMDD` already exists, halt and ask the user (single-choice)
   to provide a unique name or resume the existing track.

## Change to new-track.md

Rework the artifact-generation portion so it:

1. Treats `$ARGUMENTS` as the **track description** (the thing to build), not
   the folder name.
2. Derives a **shortname**: a concise 2-4 word kebab-case slug from the
   description/type.
3. Composes the **track ID** as `<shortname>_YYYYMMDD` using today's date.
4. **Collision check:** list existing directories in `conductor/tracks/`. If
   the composed track ID already exists, halt and ask (single-choice) whether
   to provide a unique name or resume the existing track. Only proceed once the
   ID is unique or the user has chosen to resume.
5. Creates artifacts under the generated ID:
   - `conductor/tracks/<track_id>/spec.md`
   - `conductor/tracks/<track_id>/plan.md`
   - `conductor/tracks/<track_id>/metadata.json`
6. Adds the `conductor/tracks.md` registry entry linking to the track by its
   **generated ID**, using the human-readable description as the entry label —
   so the registry stays readable while the folder stays short.
7. Tells the user the generated track ID and that the next step is
   `/conductor/implement <track_id>`.

The existing handshake checks (require `conductor/index.md` and
`conductor/tracks.md`; route back to `/setup` if missing/stale), the task-type
tagging requirement, and the plan-first / approval-before-implement discipline
all remain.

## What stays unchanged

- `implement.md`, `review.md`, `revert.md` — they already accept the track ID
  as `$ARGUMENTS`; the ID is simply shorter now.
- Lifecycle, workflow, and `tracks.md` registry encodings.
- `metadata.json` continues to record the track ID, type, status, timestamps.

## Non-Goals

- Changing the date position (upstream `shortname_YYYYMMDD` is kept as-is).
- Adding a per-track `index.md` handshake (separate parity item; not part of
  this change).
- Touching the downstream command docs.

## Verification

This is a command-doc change with no runtime code. Verify by read-through:

1. `new-track.md` derives a track ID rather than using `$ARGUMENTS` as the
   folder name.
2. The documented format is exactly `shortname_YYYYMMDD`.
3. The collision check against `conductor/tracks/` is present and gates
   directory creation.
4. Artifact paths reference the generated `<track_id>`, and the registry entry
   links to that ID while labeling the entry with the human-readable
   description.
5. Downstream commands still line up: they select a track by its short ID via
   `$ARGUMENTS`.
