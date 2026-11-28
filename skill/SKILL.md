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
- `/conductor/setup verification` audits or refreshes verification commands for
  an initialized project without repeating the product interview or changing
  unrelated project context.
- `new-track` creates and approves a track specification and implementation plan before coding starts.
- `implement` executes an approved track plan and updates registry state as work advances.
- `review` verifies the completed track and closes it only after explicit approval.
- `archive` is an optional recovery cleanup after review: from the track's own
  worktree and branch, it synchronizes and pushes the branch, moves the track
  into `conductor/archive/`, commits the archive, and pushes that commit. It
  accepts only `complete` or `awaiting-review` metadata and never force-pushes.
- `cleanup` is an optional final step: after a track's pull request is merged, it removes the local worktree and branch once merge proof holds and the user confirms.

## Project Surface

- `conductor/index.md` is the handshake artifact for the project surface.
- `setup`, `new-track`, `implement`, and `review` read `conductor/index.md` to discover project context, workflow, and track infrastructure.
- `conductor/tracks.md` and the linked `conductor/tracks/` directory are part of the method, not incidental paperwork.
- `new-track` creates a dedicated git worktree and branch for every track by default (`.worktrees/<track_id>` on branch `track/<track_id>`, from current `HEAD`). `conductor/tracks.md` and `conductor/tracks/` are therefore per-worktree once a track has its own worktree — each track's registry and artifacts live only in that track's checkout until the track's branch is merged back. Tracks created before this convention existed have no recorded worktree and continue operating on whichever worktree they're run from, unchanged.
- If the handshake or required linked artifacts are missing or stale, repair the project surface through `setup` or `new-track` rather than bypassing it.

## Verification Baseline

- Setup discovers existing checks from scripts, CI, build configuration, and
  supported language/framework versions before recommending gaps. It preserves
  established tools and avoids duplicate coverage.
- Obtain explicit approval before installing tools or changing configuration.
  Record exact commands, working directory and module/variant scope, task or
  review timing, and required/deferred status in `conductor/tech-stack.md`.
  Agree on an adoption plan before making an existing failing check required.
- A missing tool or unavailable check is not a pass. Keep deferred and unverified
  checks distinct from required checks, and report actual results only.
- For initialized projects, `/conductor/setup verification` uses the existing
  handshake and tech stack, skips the product interview and unrelated setup,
  and directs uninitialized projects to regular setup.

## Planning Discipline

- Planning is first-class: `new-track` produces an approved `spec.md` and `plan.md` before implementation begins.
- `implement` does not replace planning with opportunistic slice discovery.
- If no suitable approved track exists, the next step is `new-track`, not ad hoc execution.
- Workflow guidance linked from `conductor/index.md` is part of the execution contract for track plans.

## Design and Platform Contract

- During `new-track`, material changes to user flows, navigation, interaction,
  or visual structure require an approved design brief before final specification
  and implementation-plan approval. Record it in the track's `design.md`;
  backend-only work and established-pattern fixes record a brief justification
  in the specification instead.
- Prefer available Impeccable `shape` for web design, with direct design planning
  as the optional integration's fallback. Preserve applicable alternatives,
  user selection, and revision rounds; requirements approval is not approval
  of a visual direction. Only explicit delegation allows an agent to select it.
- For native iOS use Apple HIG; for Android use Android design guidance.
  Route cross-platform work by deployment platform, not framework name.
  Do not invoke Impeccable for native work unless requested.
- Setup may offer web projects assisted Impeccable installation and initialization
  after product/stack approval. Verify current-session discovery; obtain approval
  of installation scope and command, and explicit opt-in to `init`. A missing
  skill, declined handoff, or required restart never blocks Conductor setup.
  `new-track` can resume the same handoff at first use.
- Reuse confirmed context and existing designs. Conductor's approved context
  and specifications remain requirements authority; Impeccable's `PRODUCT.md`
  is derived context linking back to them. Reconcile conflicts with approval;
  never silently replace existing product or design files.
- Before creating a track worktree, explicitly select only the durable
  project-relative context/reference files that track needs and verify they
  are committed unchanged at `HEAD` with the read-only design-context checker.
  Obtain explicit consent before any selective commit; never stage broadly,
  auto-copy, or carry secrets, machine-local settings, or runtime previews.
  Verify selected files in the destination worktree before proceeding.

## Implement Contract

- `implement` works from an existing track selected from the tracks registry in the track's worktree (`conductor/tracks.md`).
- `implement` reads `conductor/index.md`, the selected track's `spec.md`, `plan.md`, and the linked workflow before coding.
- `implement` also reads applicable selected style guides and track design
  decisions. Preserve the approved direction; material changes require renewed
  reconciliation and approval. Do not invent design requirements for legacy or
  non-UI tracks.
- `implement` must not create a brand-new track opportunistically when the user asked to execute an approved plan.
- `implement` updates track and plan state as work progresses, then hands the track to `review` when implementation is complete.

## Review Contract

- `review` verifies the completed track against its `spec.md`, `plan.md`, and linked workflow.
- `review` owns completion and closure of the selected track in `conductor/tracks.md`.
- `review` should keep project-level truth honest by rejecting overstated completion claims.
- Review applicable design decisions, platform behavior, accessibility, and
  confirmed formatter checks with actual evidence. Report unperformed checks
  as **not verified**. Required acceptance criteria without passing evidence
  prevent closure unless explicitly revised with approval and rechecked;
  final track approval alone does not waive them.

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
