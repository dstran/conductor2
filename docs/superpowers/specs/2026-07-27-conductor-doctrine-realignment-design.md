# Conductor Doctrine Realignment Design

## Goal

Realign this repository so it behaves as an OpenCode port of upstream Gemini Conductor rather than a different Conductor methodology with a superficially similar command surface.

This milestone covers the highest-leverage parity work:

1. Rewrite `skill/SKILL.md` so it no longer conflicts with upstream `setup`, `new-track`, and `implement`
2. Add `conductor/index.md` as the upstream-style handshake artifact
3. Reconcile the OpenCode command entrypoints for `setup`, `new-track`, and `implement` with the rewritten doctrine
4. Refresh the parity report so those surfaces are described accurately after the rewrite

## Why This Milestone Exists

The current repo already has an OpenCode-facing command surface and packaged `conductor/` artifacts, but the canonical doctrine in `skill/SKILL.md` still defines a delegation-first lifecycle that conflicts with upstream Conductor's setup-first, spec-and-plan-first workflow.

That means the current branch has structural parity drift:

- upstream: setup -> new-track -> implement
- local doctrine: implement may create work opportunistically and should not stop for planning

For a true OpenCode port, upstream Conductor behavior should be the source of truth and OpenCode should be treated as the host-specific surface.

## Scope

This milestone is a doctrine realignment milestone, not a full feature-completion milestone.

Included:

- high-level doctrine rewrite for `setup`, `new-track`, and `implement`
- addition of `conductor/index.md`
- alignment of the three matching OpenCode command docs with the new doctrine
- parity report refresh for the affected surfaces

Excluded:

- full implementation of all upstream `setup` outputs
- full implementation of all upstream `new-track` outputs
- deepening `review`, `status`, or `revert`
- adding every remaining upstream asset or generated fixture

## Architecture

The repo should have four clear layers:

1. `skill/SKILL.md`
   - Canonical Conductor doctrine for this port
   - Describes the upstream-style lifecycle and how the port should behave at a high level
   - Should not define a competing Conductor methodology

2. `.opencode/command/*.md`
   - OpenCode command entrypoints
   - Translate host invocation into the Conductor lifecycle
   - Should follow doctrine, not override it

3. `conductor/index.md`
   - Handshake artifact and source-of-truth map
   - Connects the project definition, workflow, tracks registry, and generated track artifacts

4. `conductor/`
   - Project-local Conductor state and generated artifacts
   - Includes workflow, tracks registry, and setup/new-track outputs

## Doctrine Direction

The doctrine rewrite should follow these principles:

- upstream Conductor behavior is primary
- OpenCode adaptation is secondary
- lifecycle is explicit: setup -> new-track -> implement -> review
- planning is first-class, not optional or bypassed by default
- track and registry artifacts are part of the method, not incidental paperwork

The rewrite should remove or narrow local rules that directly contradict this, including:

- "do not stop for plans"
- implement-time creation of the next slice as the default lifecycle
- a doctrine framing centered on delegation-first execution instead of track-plan execution

## `conductor/index.md` Role

`conductor/index.md` should be introduced as the handshake artifact expected by upstream Conductor.

For this milestone it should:

- exist in the repo
- map the project context files and workflow files that Conductor commands rely on
- include links to tracks infrastructure
- become the file that `setup`, `new-track`, and `implement` conceptually use to discover the project surface

It does not need to solve every future artifact-generation case in this milestone, but it must be real and structurally correct.

## Command Alignment

The following command docs should be reviewed and updated as needed:

- `.opencode/command/setup.md`
- `.opencode/command/new-track.md`
- `.opencode/command/implement.md`

Expected result:

- they align with the rewritten doctrine
- they reference `conductor/index.md` where appropriate
- they no longer reflect assumptions from the old delegation-first model when those assumptions conflict with upstream lifecycle behavior

## Parity Report Update

After the doctrine and handshake updates, the parity report should be refreshed so it accurately reflects the new state.

Specifically, it should no longer report `setup`, `new-track`, `implement`, or `conductor/index.md` using stale pre-realignment descriptions if those are no longer true.

The report should still preserve honest `partial` or `conflict` statuses where real behavioral gaps remain.

## Change Discipline

This milestone should prefer replacement over hybridization.

That means:

- do not attempt to preserve both the local delegation-first doctrine and the upstream lifecycle doctrine side-by-side
- do not hide unresolved behavior differences behind compatible filenames
- do not broaden the milestone into full artifact generation or review/revert parity unless required for internal consistency

## Acceptance Criteria

This milestone is successful when:

- `skill/SKILL.md` no longer conflicts foundationally with upstream `setup`, `new-track`, and `implement`
- `conductor/index.md` exists and is part of the intended lifecycle
- `setup`, `new-track`, and `implement` OpenCode command docs align with that doctrine
- the parity report reflects the new branch state accurately
- any remaining differences are narrower protocol gaps, not core lifecycle contradictions

## Non-Goals

- Completing all remaining upstream parity work
- Generating example project artifacts for every setup or track output
- Solving review, status, and revert parity in this milestone
- Preserving the old doctrine merely because it already exists
