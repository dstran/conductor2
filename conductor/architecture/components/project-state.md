# Project Context and Track State

## Purpose

Store project-approved context, lifecycle state, and auditable track artifacts.

## Responsibilities

- Link product definition, product guidelines, tech stack, workflow, and style
  guidance through the project handshake.
- Record exact verification commands, scope, task/review timing, and
  required/deferred status in the technology stack.
- Track planned, active, awaiting-review, blocked, complete, and archived work.
- Preserve specifications, plans, metadata, review reports, and design decisions.

## Key interfaces

- `conductor/index.md` links the project surface.
- `conductor/tracks.md` encodes track lifecycle status.
- Per-track `spec.md`, `plan.md`, `metadata.json`, and `review.md` record work.

## Depends on / Used by

- Depends on explicit project/user decisions and Git history.
- Used by setup, new-track, implement, review, and maintenance commands.

## Code paths

- `conductor/index.md`
- `conductor/product.md`
- `conductor/product-guidelines.md`
- `conductor/tech-stack.md`
- `conductor/tracks.md`
- `conductor/tracks/`
- `conductor/archive/`

## Gotchas

- Track registries and artifacts are branch/worktree-local until merged.
- `PRODUCT.md` from an optional integration is derived context, not the
  requirements authority.
