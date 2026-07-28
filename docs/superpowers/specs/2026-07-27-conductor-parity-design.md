# Conductor Parity Evaluation Design

## Goal

Evaluate this repository against the upstream Gemini Conductor extension and determine whether it provides the same command surface, artifact layout, and protocol behavior.

Because parity is required at the exact command and artifact surface level, this evaluation is not limited to "similar behavior." It must determine whether this repo exposes the same core features in the same practical shape.

## Scope

The evaluation covers three layers, in order:

1. Surface layer
   - Commands and invocation shape
   - File and directory layout
   - Generated and updated artifacts
2. Protocol layer
   - Behavioral expectations for each command
   - Approval gates, correction loops, review behavior, and status tracking
3. Wiring layer
   - Whether the repo is actually wired for OpenCode to expose and use those commands and artifacts, not merely document them

## Upstream Baseline

The upstream comparison target is the Gemini Conductor extension repository and its documented feature surface, including:

- `conductor-setup`
- `conductor-new-track`
- `conductor-implement`
- `conductor-review`
- `conductor-status`
- `conductor-revert`

Expected upstream artifacts include:

- `conductor/product.md`
- `conductor/product-guidelines.md`
- `conductor/tech-stack.md`
- `conductor/workflow.md`
- `conductor/code_styleguides/`
- `conductor/tracks.md`
- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`
- `conductor/tracks/<track_id>/review.md` where applicable

## Current Repo Starting Point

Initial inspection shows this repo currently centers doctrine in `skill/SKILL.md`, with additional draft documents at repository root including `workflow.md`, `implement.md`, and `review.md`.

Known likely mismatches already identified:

- Current draft command docs live at repository root rather than an OpenCode command surface
- Draft command docs reference `@conductor/workflow.md`, but the actual file currently exists as `workflow.md` at repo root
- Upstream-documented commands `setup`, `new-track`, `status`, and `revert` are not yet present in the current repo state
- The canonical doctrine in `skill/SKILL.md` is narrower and more delegation-centric than upstream Conductor's spec-driven lifecycle

These are hypotheses to verify, not final conclusions.

## Evaluation Method

### 1. Surface Audit

Compare upstream and local definitions for:

- command names
- command locations and discovery paths
- artifact paths
- expected generated files
- required track metadata and status files

### 2. Protocol Audit

For each upstream command, compare:

- what inputs it expects
- what files it reads and writes
- how it handles approval and pause points
- how it records progress
- whether it includes correction loops, checkpointing, or revert semantics
- what verification steps it performs

### 3. Wiring Audit

Confirm whether the current repo is operationally wired so the documented command surface can actually be invoked in OpenCode.

This includes checking whether the repo layout, command placement, and references line up with the host's expectations.

## Output Format

The audit output should be a parity matrix with one row per upstream feature or command.

Each row should include:

- upstream feature or command
- current repo implementation
- status: `match`, `partial`, `missing`, or `conflict`
- evidence: repo file paths and line references
- recommended fix

## Status Definitions

- `match`: same command or artifact surface and materially same behavior
- `partial`: present but incomplete, relocated, or behaviorally weaker
- `missing`: upstream feature is absent
- `conflict`: current repo behavior or doctrine contradicts upstream Conductor requirements

## Deliverables

The work should produce:

1. A concise parity report covering command surface, artifact layout, protocol behavior, and wiring
2. A list of repo-local mismatches grouped by command surface, artifact layout, and behavior
3. A minimal change plan for straightforward gaps
4. Repo updates for the highest-confidence, lowest-ambiguity fixes if the audit shows they can be applied without guessing

## Change Discipline

If the audit reveals straightforward gaps, fix them with the smallest correct changes.

If a gap requires a product or doctrine decision, stop and ask rather than guessing.

If current repo doctrine actively conflicts with upstream parity, record that as a conflict instead of smoothing it over.

## Acceptance Criteria

This phase is successful when:

- every upstream command and major artifact has a concrete parity status
- documentation gaps are separated from real behavioral gaps
- easy fixes are distinguished from doctrine-level conflicts
- repo changes, if any, are directly traceable to audited gaps rather than speculative alignment

## Non-Goals

- Rewriting this repo to become a byte-for-byte copy of upstream
- Treating README wording alone as sufficient proof when stronger repo evidence is available
- Making doctrine changes without explicitly identifying the upstream behavior they are meant to restore
