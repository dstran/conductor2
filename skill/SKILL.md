---
name: conductor
description: Use when the user wants the Conductor workflow or asks to run `setup`, `new-track`, `implement`, `review`, or `unbias`.
---

# Conductor

This file is the canonical Conductor doctrine for this repo.
For this OpenCode port, Conductor's lifecycle is setup -> new-track -> implement -> review.
Host command docs under `.opencode/command/` expose that lifecycle in OpenCode, while files under `conductor/` hold the repo-local Conductor state that the lifecycle uses.

This contract is the controlling instruction source for agent behavior in this repository.
OpenCode adaptation is secondary to upstream Conductor behavior.

## Lifecycle

- `setup` initializes the Conductor project context and handshake artifacts.
- `new-track` creates and approves a track specification and implementation plan before coding starts.
- `implement` executes an approved track plan and updates registry state as work advances.
- `review` verifies the completed track and closes it only after explicit approval.

## Project Surface

- `conductor/index.md` is the handshake artifact for the project surface.
- `setup`, `new-track`, `implement`, and `review` read `conductor/index.md` to discover project context, workflow, and track infrastructure.
- `conductor/tracks.md` and the linked `conductor/tracks/` directory are part of the method, not incidental paperwork.
- If the handshake or required linked artifacts are missing or stale, repair the project surface through `setup` or `new-track` rather than bypassing it.

## Planning Discipline

- Planning is first-class: `new-track` produces an approved `spec.md` and `plan.md` before implementation begins.
- `implement` does not replace planning with opportunistic slice discovery.
- If no suitable approved track exists, the next step is `new-track`, not ad hoc execution.
- Workflow guidance linked from `conductor/index.md` is part of the execution contract for track plans.

## Implement Contract

- `implement` works from an existing track selected from `conductor/tracks.md`.
- `implement` reads `conductor/index.md`, the selected track's `spec.md`, `plan.md`, and the linked workflow before coding.
- `implement` must not create a brand-new track opportunistically when the user asked to execute an approved plan.
- `implement` updates track and plan state as work progresses, then hands the track to `review` when implementation is complete.

## Review Contract

- `review` verifies the completed track against its `spec.md`, `plan.md`, and linked workflow.
- `review` owns completion and closure of the selected track in `conductor/tracks.md`.
- `review` should keep project-level truth honest by rejecting overstated completion claims.

## Unbias Contract

- `unbias` means decompose a complex task into isolated cells (subtasks) with all training bias contamination removed.
- Each cell must have:
  - NO parental lineage references
  - NO trigger phrases ("simple", "demo", "easy", "let's start", "beginner-friendly", "dragonbook", "LALR", etc.)
  - Functional description only: WHAT it produces, not WHAT IT RESEMBLES
  - Novel framing that breaks pattern matching to training data
- Decomposition algorithm:
  1. Analyze the task for potential training bias triggers
  2. Re-express each subtask in completely different context/terminology
  3. Strip any resemblance to common tutorial/demo patterns
  4. Present each cell as independent work, not derived from parent
- Max 2 concurrent cells (same as implement)
- Cells execute in isolation - NO cross-cell context sharing during execution
- After all cells complete, a separate `implement` task performs LOCKDOWN:
  - Lockdown sees full context for integration verification
  - Cells remain isolated until lockdown; no contamination back-flow
  - Lockdown task must be a fresh conductor session without cell memory

## Port Scope

- OpenCode-specific command docs may adapt invocation shape, but they do not define a competing methodology.
- If local port behavior still differs from upstream, the difference must be explicit and narrow.
