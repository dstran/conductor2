# Conductor Parity Report

Audit order: surface layer, protocol layer, then wiring layer.

Status key:
- `match`: same surface and materially same behavior
- `partial`: present but incomplete, relocated, or behaviorally weaker
- `missing`: no local implementation exists
- `conflict`: local doctrine contradicts upstream behavior or required artifact shape

Evidence roots:
- Local repo: `/Users/dt105/git/playground/conductor2/.worktrees/conductor-parity-2026-07-27`
- Upstream clone: `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/gemini-conductor-upstream`

Current-state note:
- The current worktree now ships the packaged OpenCode command docs under `.opencode/command/` plus the shared lifecycle artifacts under `conductor/`.
- Artifact rows below distinguish between assets already present in this worktree and setup/new-track outputs that are only generated when those commands run.

## Surface Layer

### Commands

| Upstream surface | Local surface | Status | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |
| `conductor-setup` | `.opencode/command/setup.md` | partial | upstream `skills/conductor-setup/SKILL.md:63-226`; local `.opencode/command/setup.md:6-21`, `skill/SKILL.md:15-27`, `conductor/index.md:1-20` | The command and handshake surface now exist locally; remaining gaps should only reflect still-missing upstream audit depth, generated outputs, or commit behavior. |
| `conductor-new-track` | `.opencode/command/new-track.md` | partial | upstream `skills/conductor-new-track/SKILL.md:24-168`; local `.opencode/command/new-track.md:6-21`, `skill/SKILL.md:15-34`, `conductor/index.md:1-20` | The command, handshake dependency, and plan-first surface now exist locally; remaining gaps should only reflect still-missing upstream interactive questioning, per-track handshake generation, or commit behavior. |
| `conductor-implement` | `.opencode/command/implement.md` | partial | upstream `skills/conductor-implement/SKILL.md:41-139`; local `.opencode/command/implement.md:6-104`, `skill/SKILL.md:29-47`, `conductor/index.md:1-20` | The command and approved-plan execution surface now exist locally; remaining gaps should only reflect still-missing upstream registry-driven selection, project-doc synchronization, or completion semantics. |
| `conductor-review` | `.opencode/command/review.md` | partial | Upstream `README.md:223-255`, `skills/conductor-review/SKILL.md:49-222`; local `.opencode/command/review.md:1-108`, `skill/SKILL.md:15-20`, `skill/SKILL.md:43-47`, `conductor/index.md:1-20`, `conductor/tracks.md:20-27`, `conductor/workflow.md:60-91` | Keep the review command surface and close any remaining behavioral gaps such as archive/delete semantics if exact upstream parity matters. |
| `conductor-status` | `.opencode/command/status.md` | partial | Upstream `README.md:223-255`, `skills/conductor-status/SKILL.md:42-71`; local `README.md:6-8`, `.opencode/command/status.md:1-8`, `conductor/tracks.md:1-39` | Expand from the current summary command only if exact parity needs the richer upstream progress rendering. |
| `conductor-revert` | `.opencode/command/revert.md` | partial | Upstream `README.md:223-255`, `skills/conductor-revert/SKILL.md:39-124`; local `README.md:6-8`, `.opencode/command/revert.md:1-9`, `conductor/tracks.md:1-39` | Expand the existing revert command surface with the remaining git-history reconciliation details if exact parity is required. |

### Artifacts

| Upstream artifact | Local artifact | Status | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |
| `conductor/index.md` | `conductor/index.md` | partial | upstream `skills/conductor-setup/SKILL.md:196-226`, `skills/conductor-new-track/SKILL.md:24-40`; local `conductor/index.md:1-20`, `skill/SKILL.md:22-27` | The handshake artifact now exists; remaining parity gaps are behavioral or generated-output gaps rather than surface absence. |
| `conductor/product.md` | Setup-target artifact; not checked in yet | partial | Upstream `README.md:172-179`, `skills/conductor-setup/SKILL.md:106-117`; local `.opencode/command/setup.md:10-20` | `setup` now names this artifact explicitly, but the source tree still lacks a generated example. |
| `conductor/product-guidelines.md` | Setup-target artifact; not checked in yet | partial | Upstream `README.md:172-179`, `skills/conductor-setup/SKILL.md:119-125`; local `.opencode/command/setup.md:10-20` | `setup` now names this artifact explicitly, but the source tree still lacks a generated example. |
| `conductor/tech-stack.md` | Setup-target artifact; not checked in yet | partial | Upstream `README.md:172-179`, `skills/conductor-setup/SKILL.md:127-142`; local `.opencode/command/setup.md:10-20` | `setup` now names this artifact explicitly, but the source tree still lacks a generated example. |
| `conductor/workflow.md` | `conductor/workflow.md` | partial | Upstream `README.md:169-179`, `skills/conductor-setup/assets/workflow.md:1-92`; local `.opencode/command/setup.md:10-21`, `conductor/workflow.md:1-91` | The workflow artifact now exists in-tree; remaining differences are protocol-level, not surface absence. |
| `conductor/code_styleguides/` | Setup-target artifact; not checked in yet | partial | Upstream `README.md:174-179`, `skills/conductor-setup/SKILL.md:144-156`; local `.opencode/command/setup.md:10-21` | Add the actual directory contents if exact parity requires packaged style guides rather than a setup target only. |
| `conductor/tracks.md` | `conductor/tracks.md` | partial | Upstream `README.md:174-179`, `README.md:213-255`, `skills/conductor-status/SKILL.md:46-71`; local `README.md:7-8`, `conductor/tracks.md:1-39` | The shared registry now exists in-tree; remaining gaps are in generated per-track content and behavior, not registry absence. |
| `conductor/tracks/` | `/new-track` generation target; directory absent until a track exists | partial | Upstream `README.md:195-205`, `skills/conductor-new-track/SKILL.md:59-110`; local `conductor/index.md:17-20`, `.opencode/command/new-track.md:6-16` | The handshake links the tracks directory contract, but this worktree still has no generated track directory yet. |
| `conductor/tracks/<track_id>/spec.md` | `/new-track` generation target; no example track checked in | partial | Upstream `README.md:195-205`, `skills/conductor-new-track/SKILL.md:59-89`, `skills/conductor-new-track/SKILL.md:148-151`; local `.opencode/command/new-track.md:6-16` | Keep the generated path contract and add example or exercised output only if parity review needs checked-in fixtures. |
| `conductor/tracks/<track_id>/plan.md` | `/new-track` generation target; no example track checked in | partial | Upstream `README.md:195-205`, `skills/conductor-new-track/SKILL.md:91-110`, `skills/conductor-new-track/SKILL.md:148-151`; local `.opencode/command/new-track.md:6-16`, `.opencode/command/implement.md:8-9`, `.opencode/command/review.md:8-9` | The path is now part of the local command contract and later commands consume it; the tree simply has no generated sample yet. |
| `conductor/tracks/<track_id>/metadata.json` | `/new-track` generation target; no example track checked in | partial | Upstream `README.md:195-205`, `skills/conductor-new-track/SKILL.md:148-151`; local `.opencode/command/new-track.md:6-16` | Keep the generation target and add exercised output only if parity review requires a concrete sample artifact. |

## Protocol Layer

| Upstream protocol | Local protocol | Status | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |
| `conductor-setup` performs brownfield/greenfield audit, writes context artifacts, writes `conductor/index.md`, and commits setup | Local setup doctrine now creates or refreshes the handshake and context artifacts, routes later commands through `conductor/index.md`, and pauses for user review before completion | partial | Upstream `skills/conductor-setup/SKILL.md:63-104`, `skills/conductor-setup/SKILL.md:106-226`; local `.opencode/command/setup.md:6-21`, `skill/SKILL.md:15-27`, `conductor/index.md:1-20` | Keep the handshake-first setup doctrine, then add the remaining upstream audit, resume, integrity-check, and commit behavior if exact parity is required. |
| `conductor-new-track` runs interactive spec approval, plan approval, metadata creation, registry update, and commit | Local new-track doctrine now requires the handshake, produces an approved `spec.md` and `plan.md` before implementation, generates metadata and registry state, and pauses before `/implement` | partial | Upstream `skills/conductor-new-track/SKILL.md:24-168`; local `.opencode/command/new-track.md:6-21`, `skill/SKILL.md:15-34`, `conductor/index.md:1-20` | Keep the handshake-and-plan flow, then add the remaining upstream questioning loop, per-track handshake generation, and commit/handoff behavior if exact parity is required. |
| `conductor-implement` selects a track from `conductor/tracks.md`, updates status, executes `plan.md`, synchronizes docs, and hands off to review | Local implement doctrine now requires a pre-existing approved track, reads the handshake/spec/plan/workflow before coding, executes phase-by-phase with workflow enforcement, and hands the finished track to `/review` | partial | Upstream `skills/conductor-implement/SKILL.md:41-139`; local `.opencode/command/implement.md:6-104`, `skill/SKILL.md:29-41`, `conductor/index.md:1-20` | Keep the plan-driven implementation flow, then add the remaining upstream registry-selection, project-doc synchronization, and completion-status behavior if exact parity is required. |
| `conductor-review` loads plan/spec/context, runs diff analysis and tests, emits a review report, may apply fixes, and may archive/delete tracks | Local `/review` command now requires the handshake plus the `[~]` awaiting-review state before starting, runs quality/security/tests, writes `review.md`, and owns the final move to `[x]` complete after explicit approval, but does not yet claim the full upstream archive/delete lifecycle | partial | Upstream `skills/conductor-review/SKILL.md:52-222`; local `.opencode/command/review.md:6-108`, `skill/SKILL.md:43-47`, `conductor/index.md:1-20`, `conductor/tracks.md:20-27`, `conductor/workflow.md:60-91` | Keep the review protocol surface and add archive/delete behavior only if exact parity requires it. |
| `conductor-status` parses `conductor/tracks.md` and per-track plans into a progress summary | Local `/status` command reads `conductor/tracks.md` and summarizes active, blocked, and completed tracks, but does not yet promise the fuller upstream progress rendering | partial | Upstream `skills/conductor-status/SKILL.md:46-71`; local `.opencode/command/status.md:6-8`, `conductor/tracks.md:1-39` | Expand only if exact parity needs the richer upstream summary shape. |
| `conductor-revert` confirms a logical target, reconciles git history, reverts associated commits, and resynchronizes plan state | Local `/revert` command exists and targets `tracks.md` plus a track `plan.md`, but its current contract is still much thinner than the upstream git-history workflow | partial | Upstream `skills/conductor-revert/SKILL.md:39-124`; local `.opencode/command/revert.md:6-9`, `conductor/tracks.md:1-39` | Flesh out the git-history reconciliation steps if exact parity is required. |

## Wiring Layer

| Surface | Status | Evidence | Recommended fix |
| --- | --- | --- | --- |
| Installer copies full OpenCode command surface | match | `install.sh:24-31`, `README.md:8-8`; a clean install to `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-final-fix` produced `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-final-fix/.opencode/conductor/.opencode/command/{implement.md,new-track.md,revert.md,review.md,setup.md,status.md}`. | None for the worktree installer surface. |
| Gemini packaging and host discoverability | match | `install.sh:33-42`; a clean install to `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview` produced `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview/.gemini/extensions/conductor/{SKILL.md,gemini-extension.json}` plus `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview/.gemini/extensions/conductor/.opencode/command/{implement.md,new-track.md,revert.md,review.md,setup.md,status.md}` and `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview/.gemini/extensions/conductor/conductor/{index.md,tracks.md,workflow.md}`. | None for the worktree installer surface. |
| Setup asset packaging (`index.md`, `workflow.md`, `tracks.md`) | match | `install.sh:24-40`, `README.md:8-8`; the clean install produced both `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview/.opencode/conductor/conductor/{index.md,tracks.md,workflow.md}` and `/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home-rereview/.gemini/extensions/conductor/conductor/{index.md,tracks.md,workflow.md}`. | Add `code_styleguides/` only if exact upstream parity still requires those extra assets. |

## Baseline Summary

- The worktree now ships the six packaged OpenCode command docs plus shared `conductor/index.md`, `conductor/workflow.md`, and `conductor/tracks.md` artifacts.
- The largest remaining parity gaps are richer upstream setup/new-track/implement behaviors plus generated track-surface artifacts such as `conductor/tracks/` and per-track outputs.
- Setup and new-track outputs such as `product.md`, `tech-stack.md`, `conductor/tracks/`, and per-track files are currently generation targets rather than checked-in sample artifacts.
- The worktree installer now lays down the packaged OpenCode and Gemini surfaces as documented.
