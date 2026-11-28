# Canonical Workflow Contract

## Purpose

Define the methodology and invariants that host-specific command instructions
must preserve.

## Responsibilities

- Keep doctrine canonical and lifecycle ordering explicit.
- Define task classification, test enforcement, task commits, and checkpoints.
- Record required/deferred verification checks and distinguish actual outcomes
  from unavailable or unknown coverage.
- Require a task-diff readability pass and rerun affected required checks after
  edits.
- Require explicit approval before closing a reviewed track.

## Key interfaces

- Lifecycle contract in `skill/SKILL.md`
- Test and commit procedure in `conductor/workflow.md`
- Verification baseline in `conductor/tech-stack.md`

## Depends on / Used by

- Depends on project-level workflow decisions approved by the maintainers.
- Used by lifecycle commands and compatibility surfaces.

## Code paths

- `skill/SKILL.md`
- `conductor/workflow.md`
- `.opencode/command/setup.md`
- `.opencode/command/implement.md`
- `.opencode/command/review.md`
- `AGENTS.md`

## Gotchas

- `skill/SKILL.md` is canonical; repository instruction files are wrappers.
- Track-local exceptions must not silently change global doctrine.
