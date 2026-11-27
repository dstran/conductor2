# Canonical Workflow Contract

## Purpose

Define the methodology and invariants that host-specific command instructions
must preserve.

## Responsibilities

- Keep doctrine canonical and lifecycle ordering explicit.
- Define task classification, test enforcement, task commits, and checkpoints.
- Require explicit approval before closing a reviewed track.

## Key interfaces

- Lifecycle contract in `skill/SKILL.md`
- Test and commit procedure in `conductor/workflow.md`

## Depends on / Used by

- Depends on project-level workflow decisions approved by the maintainers.
- Used by lifecycle commands and compatibility surfaces.

## Code paths

- `skill/SKILL.md`
- `conductor/workflow.md`
- `AGENTS.md`

## Gotchas

- `skill/SKILL.md` is canonical; repository instruction files are wrappers.
- Track-local exceptions must not silently change global doctrine.
