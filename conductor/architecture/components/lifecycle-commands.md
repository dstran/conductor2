# Lifecycle Commands

## Purpose

Expose Conductor's setup, planning, implementation, review, and maintenance
operations through the OpenCode command surface.

## Responsibilities

- Initialize project context and discover available guidance.
- Audit verification commands during setup, including a verification-only mode
  for initialized projects.
- Plan tracks before implementation; route material design decisions by platform.
- Implement approved plans with a task-diff readability pass and required-check
  re-verification after edits.
- Review the full recorded verification baseline and require evidence before
  closure.
- Provide explicit archive, cleanup, status, revert, and update workflows.

## Key interfaces

- `/conductor/setup`
- `/conductor/setup verification`
- `/conductor/new-track`
- `/conductor/implement`
- `/conductor/review`
- `/conductor/archive`, `/conductor/cleanup`, `/conductor/status`,
  `/conductor/revert`, `/conductor/update`

## Depends on / Used by

- Depends on the canonical contract, project-local records, guidance assets,
  Git, and selected helper scripts.
- Used by developers through the OpenCode command palette.

## Code paths

- `.opencode/command/`
- `README.md`

## Gotchas

- Preserve approval gates and task/phase commit rules; a command doc must not
  create a competing workflow.
- New tracks use isolated worktrees by default; selected durable context must
  be committed and checked before crossing that boundary.
