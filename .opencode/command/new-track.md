---
description: Generate a new Conductor track spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first.
Use it to locate the workflow and tracks registry before generating these track artifacts for `$ARGUMENTS`:

- `conductor/tracks/$ARGUMENTS/spec.md`
- `conductor/tracks/$ARGUMENTS/plan.md`
- `conductor/tracks/$ARGUMENTS/metadata.json`

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.

Update `conductor/tracks.md` with the new linked registry entry. Require task type tags for workflow enforcement, then pause for approval before `/implement`.

Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins.
