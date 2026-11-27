# Lifecycle Helpers and Tests

## Purpose

Support bounded Git lifecycle operations and verify installer, context-handoff,
and dispatcher behavior in disposable fixtures.

## Responsibilities

- Dispatch pull/merge request creation with safe manual fallback behavior.
- Archive tracks with Git/worktree safety checks.
- Check explicitly selected context files before worktree branching.
- Exercise helpers and installer behavior with isolated regression tests.

## Key interfaces

- Shell and Python command-line helpers in `conductor/scripts/`.
- Test scripts invoked from `conductor/tech-stack.md`.

## Depends on / Used by

- Depends on Git, shell, and Python 3; provider CLIs are optional.
- Used by lifecycle command instructions and maintainers' regression checks.

## Code paths

- `conductor/scripts/open-pr.sh`
- `conductor/scripts/archive-track.py`
- `conductor/scripts/check-design-context.py`
- `conductor/scripts/test-open-pr.sh`
- `conductor/scripts/test-archive-track.sh`
- `conductor/scripts/test-design-context.py`
- `conductor/scripts/test-installer.sh`

## Gotchas

- Helpers must not silently stage, commit, copy, or overwrite user context.
- Tests use disposable repositories and temporary homes; do not run installer
  smoke tests against a real user home.
