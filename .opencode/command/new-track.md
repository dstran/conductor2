---
description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.

## 1. Track description

Treat `$ARGUMENTS` as the track **description** — the feature, bug fix, or chore the user wants to plan. It is NOT the folder name. If `$ARGUMENTS` is empty, ask the user for a brief description of the track before continuing. Infer and confirm the track type (feature, bug, chore, refactor, MVP).

## 2. Generate the track ID

Derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.

Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).

**Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.

## 3. Create the track artifacts

Under the generated track ID, create:

- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`

`metadata.json` records the track ID, type, status (`new`), and created/updated timestamps.

Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`).

## 4. Update the registry

Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:

`- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

## 5. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`.
