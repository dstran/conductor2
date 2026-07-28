# Conductor Doctrine Realignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the repo's core Conductor doctrine so the OpenCode port follows upstream setup -> new-track -> implement lifecycle expectations, adds `conductor/index.md`, and refreshes the parity report accordingly.

**Architecture:** Replace the current delegation-first doctrine in `skill/SKILL.md` with an upstream-first lifecycle description, then add the missing handshake artifact and align the three OpenCode entrypoint commands to that doctrine. Finish by refreshing the parity report so it describes the new branch state honestly, keeping any remaining gaps as `partial` or `conflict` rather than overstating parity.

**Tech Stack:** Markdown documentation, OpenCode command docs, packaged `conductor/` artifacts, shell verification with `bash`, `grep`, and git status/diff checks

## Global Constraints

- upstream Conductor behavior is primary
- OpenCode adaptation is secondary
- lifecycle is explicit: setup -> new-track -> implement -> review
- planning is first-class, not optional or bypassed by default
- track and registry artifacts are part of the method, not incidental paperwork
- do not attempt to preserve both the local delegation-first doctrine and the upstream lifecycle doctrine side-by-side
- do not hide unresolved behavior differences behind compatible filenames
- do not broaden the milestone into full artifact generation or review/revert parity unless required for internal consistency
- do not commit unless the user explicitly asks for a commit

---

### Task 1: Rewrite canonical doctrine around upstream lifecycle

**Files:**
- Modify: `skill/SKILL.md`
- Reference: `docs/superpowers/specs/2026-07-27-conductor-doctrine-realignment-design.md`
- Reference: `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/gemini-conductor-upstream/skills/conductor-setup/SKILL.md`
- Reference: `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/gemini-conductor-upstream/skills/conductor-new-track/SKILL.md`
- Reference: `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/gemini-conductor-upstream/skills/conductor-implement/SKILL.md`

**Interfaces:**
- Consumes: current local doctrine plus upstream setup/new-track/implement lifecycle requirements
- Produces: a rewritten `skill/SKILL.md` that treats upstream lifecycle as canonical high-level behavior for this port

- [ ] **Step 1: Replace the opening doctrine framing**

```md
# Conductor

This file is the canonical Conductor doctrine for this repo.
For this OpenCode port, Conductor's lifecycle is setup -> new-track -> implement -> review.
Host command docs under `.opencode/command/` expose that lifecycle in OpenCode, while files under `conductor/` hold the repo-local Conductor state that the lifecycle uses.
```

- [ ] **Step 2: Remove the current closure-mode rules that forbid planning pauses**

```md
## Lifecycle

- `setup` initializes the Conductor project context and handshake artifacts.
- `new-track` creates and approves a track specification and implementation plan before coding starts.
- `implement` executes an approved track plan and updates registry state as work advances.
- `review` verifies the completed track and closes it only after explicit approval.
```

- [ ] **Step 3: Replace the current implement contract with a plan-driven contract**

```md
## Implement Contract

- `implement` works from an existing track selected from `conductor/tracks.md`.
- `implement` reads `conductor/index.md`, the selected track's `spec.md`, `plan.md`, and the linked workflow before coding.
- `implement` must not create a brand-new track opportunistically when the user asked to execute an approved plan.
- `implement` updates track and plan state as work progresses, then hands the track to `review` when implementation is complete.
```

- [ ] **Step 4: Keep only doctrine that still fits the upstream-first lifecycle**

```md
## Port Scope

- OpenCode-specific command docs may adapt invocation shape, but they do not define a competing methodology.
- If local port behavior still differs from upstream, the difference must be explicit and narrow.
```

- [ ] **Step 5: Verify the old contradictions are gone from `skill/SKILL.md`**

Run: `grep -n "Do not stop for plans\|create the next bounded track from repo-local evidence\|implement means choose one bounded slice" skill/SKILL.md`
Expected: no matches.

### Task 2: Add the upstream-style handshake artifact

**Files:**
- Create: `conductor/index.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: current packaged Conductor artifact layout and the doctrine rewrite from Task 1
- Produces: a real `conductor/index.md` that maps project definition, workflow, and tracks infrastructure for the port

- [ ] **Step 1: Create `conductor/index.md` with the handshake structure**

```md
# Project Context

## Definition

- [Product Definition](./product.md)
- [Product Guidelines](./product-guidelines.md)
- [Tech Stack](./tech-stack.md)

## Workflow

- [Workflow](./workflow.md)
- [Code Style Guides](./code_styleguides/)

## Tracks

- [Tracks Registry](./tracks.md)
- [Tracks Directory](./tracks/)
```

- [ ] **Step 2: Add a short note explaining generation targets that may not exist yet**

```md
These links define the expected Conductor project surface for this port.
Some files are created by `setup` or `new-track` and may not exist until those commands run.
```

- [ ] **Step 3: Update `README.md` so it names `conductor/index.md` as part of the packaged surface**

```md
- Shared lifecycle artifacts: `conductor/index.md`, `conductor/workflow.md`, `conductor/tracks.md`
```

- [ ] **Step 4: Verify the handshake file exists and contains the expected sections**

Run: `grep -n "# Project Context\|## Definition\|## Workflow\|## Tracks" conductor/index.md`
Expected: matches for all four headings.

### Task 3: Align OpenCode entrypoints with the rewritten doctrine

**Files:**
- Modify: `.opencode/command/setup.md`
- Modify: `.opencode/command/new-track.md`
- Modify: `.opencode/command/implement.md`
- Reference: `conductor/index.md`
- Reference: `conductor/workflow.md`
- Reference: `conductor/tracks.md`

**Interfaces:**
- Consumes: rewritten doctrine plus new handshake artifact
- Produces: three OpenCode commands that explicitly follow the setup -> new-track -> implement lifecycle and use `conductor/index.md` as discovery surface

- [ ] **Step 1: Update `/setup` to create and verify the handshake-driven artifact set**

```md
Read and maintain `conductor/index.md` as the handshake artifact for this project.

Create or refresh these project context artifacts:
- `conductor/product.md`
- `conductor/product-guidelines.md`
- `conductor/tech-stack.md`
- `conductor/workflow.md`
- `conductor/code_styleguides/`
- `conductor/tracks.md`
- `conductor/index.md`
```

- [ ] **Step 2: Update `/new-track` so it explicitly depends on setup having produced the handshake**

```md
Read `conductor/index.md` first.
Use it to locate the workflow and tracks registry before generating:
- `conductor/tracks/$ARGUMENTS/spec.md`
- `conductor/tracks/$ARGUMENTS/plan.md`
- `conductor/tracks/$ARGUMENTS/metadata.json`
```

- [ ] **Step 3: Update `/implement` so it explicitly uses the handshake before loading track artifacts**

```md
@conductor/index.md
@conductor/workflow.md
@conductor/tracks.md
@conductor/tracks/$ARGUMENTS/plan.md
@conductor/tracks/$ARGUMENTS/spec.md

Read `conductor/index.md` first to confirm the project context and track infrastructure before implementing the selected track.
```

- [ ] **Step 4: Remove any remaining wording that implies implement-time track creation as the default lifecycle**

```md
Do not create a new track during `/implement` unless the user explicitly asked to recover missing track state in this Conductor maintenance repo.
```

- [ ] **Step 5: Verify the three command docs all reference `conductor/index.md` and the explicit lifecycle**

Run: `grep -n "conductor/index.md\|new-track\|tracks.md" .opencode/command/setup.md .opencode/command/new-track.md .opencode/command/implement.md`
Expected: each file includes the intended references and no stale lifecycle wording remains.

### Task 4: Refresh the parity report for the realigned state

**Files:**
- Modify: `docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
- Reference: `skill/SKILL.md`
- Reference: `.opencode/command/setup.md`
- Reference: `.opencode/command/new-track.md`
- Reference: `.opencode/command/implement.md`
- Reference: `conductor/index.md`

**Interfaces:**
- Consumes: the updated doctrine, handshake artifact, and command docs
- Produces: a parity report that no longer describes setup/new-track/implement/index using the pre-realignment state

- [ ] **Step 1: Rewrite the `conductor/index.md` artifact row**

```md
| `conductor/index.md` | `conductor/index.md` | partial | upstream `skills/conductor-setup/SKILL.md:196-226`, `skills/conductor-new-track/SKILL.md:24-40`; local `conductor/index.md:1-16` plus the rewritten lifecycle and project-truth sections in `skill/SKILL.md` | The handshake artifact now exists; remaining parity gaps are behavioral or generated-output gaps rather than surface absence. |
```

- [ ] **Step 2: Rewrite the `setup`, `new-track`, and `implement` rows so they cite the new local files and the rewritten doctrine**

```md
| `conductor-setup` | `.opencode/command/setup.md` | partial | upstream `skills/conductor-setup/SKILL.md:63-226`; local `.opencode/command/setup.md:1-16`, the rewritten setup/lifecycle sections in `skill/SKILL.md`, and `conductor/index.md:1-16` | The command and handshake surface now exist locally; remaining gaps should only reflect still-missing upstream audit depth, generated outputs, or commit behavior. |
```

- [ ] **Step 3: Refresh the protocol-layer rows for `setup`, `new-track`, and `implement`**

```md
The local protocol is now handshake-and-plan driven at the doctrine level, but remains `partial` where upstream still has richer behavior or generated outputs not yet implemented.
```

- [ ] **Step 4: Keep any remaining `partial` or `conflict` statuses honest**

```md
Do not upgrade to `match` unless the local row has both the right surface and materially the same behavior.
```

- [ ] **Step 5: Verify the report no longer describes those surfaces as absent or delegation-first conflicts if the rewrite resolved them**

Run: `grep -n "No local handshake artifact\|No exact local command surface\|delegation-first doctrine" docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
Expected: no stale matches for the updated rows.

### Task 5: Final consistency verification for the milestone

**Files:**
- Reference: `skill/SKILL.md`
- Reference: `conductor/index.md`
- Reference: `.opencode/command/setup.md`
- Reference: `.opencode/command/new-track.md`
- Reference: `.opencode/command/implement.md`
- Reference: `docs/superpowers/reports/2026-07-27-conductor-parity-report.md`

**Interfaces:**
- Consumes: all updated doctrine, handshake, command, and report files
- Produces: a verified milestone state where the remaining differences are narrower than the original lifecycle contradiction

- [ ] **Step 1: Run a focused diff hygiene check on the milestone files**

Run: `git diff --check -- skill/SKILL.md conductor/index.md .opencode/command/setup.md .opencode/command/new-track.md .opencode/command/implement.md docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
Expected: no whitespace or patch-format errors in the milestone files.

- [ ] **Step 2: Verify the handshake and command surface are discoverable together**

Run: `grep -n "conductor/index.md" .opencode/command/setup.md .opencode/command/new-track.md .opencode/command/implement.md && grep -n "Tracks Registry\|Tracks Directory" conductor/index.md`
Expected: all three commands reference `conductor/index.md`, and the handshake file links the tracks infrastructure.

- [ ] **Step 3: Verify the doctrine no longer instructs implement-time opportunistic planning**

Run: `grep -n "Do not stop for plans\|create the next bounded track from repo-local evidence\|choose one bounded slice" skill/SKILL.md`
Expected: no matches.

- [ ] **Step 4: Verify the parity report now treats the milestone surfaces as present but still partial where appropriate**

Run: `grep -n "conductor-setup\|conductor-new-track\|conductor-implement\|conductor/index.md" docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
Expected: all four rows exist and cite the updated local paths rather than stale absence claims.

- [ ] **Step 5: Commit**

```bash
git add skill/SKILL.md conductor/index.md .opencode/command/setup.md .opencode/command/new-track.md .opencode/command/implement.md docs/superpowers/reports/2026-07-27-conductor-parity-report.md
git commit -m "docs: realign conductor doctrine to upstream lifecycle"
```

Expected: only run this step if the user explicitly asks for a commit; otherwise leave the files uncommitted and report the verified state.
