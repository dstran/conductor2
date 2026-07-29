---
description: Summarize active, blocked, and archived Conductor tracks from the registry and archive directory without editing product code
agent: build
---

@conductor/tracks.md

Read `conductor/tracks.md` and summarize the tracks without editing product code:

- **Active:** entries under `## Active`. Distinguish planned (`[ ]`),
  in progress (`[~]`), awaiting review (`[~]` with the awaiting-review
  note), and completed-in-place (`[x]`).
- **Blocked:** entries under `## Blocked`, including each `Blocker:` note.
- **Archived:** if `conductor/archive/` exists, list the archived track
  directories inside it. These have been removed from the registry.
