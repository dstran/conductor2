# Design and Code Guidance

## Purpose

Provide optional, project-matched guidance for platform design decisions and
language-specific implementation conventions.

## Responsibilities

- Route web, iOS, Android, and cross-platform design planning appropriately.
- Preserve explicit user choice and revision rounds for material design work.
- Supply bundled style guides without imposing unrelated tools or formatting.
- Describe caller-oriented naming, straightforward control flow, supported
  idioms, and abstractions justified by a present need.

## Key interfaces

- Design planning instructions in `/conductor/new-track`.
- Setup guide selection and formatter discovery.
- Optional Impeccable integration for consuming web projects.

## Depends on / Used by

- Depends on approved project context, platform targets, and user choices.
- Used by setup, new-track, implement, and review.

## Code paths

- `conductor/assets/code_styleguides/`
- `conductor/code_styleguides/`
- `.opencode/command/setup.md`
- `.opencode/command/new-track.md`
- `.opencode/command/implement.md`
- `.opencode/command/review.md`
- `README.md`

## Gotchas

- Impeccable is optional and is not installed by Conductor.
- Preserve existing formatters and their configuration; unavailable checks are
  not passes.
