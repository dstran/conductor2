# Conductor Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit this repository against upstream Gemini Conductor and close the verified gaps required for exact command, artifact, and behavioral parity.

**Architecture:** Start with a source-backed parity report so every change is tied to a verified upstream requirement. Then move the current draft workflow and command docs into a canonical command/artifact layout, add the missing commands, and finally update doctrine, packaging, and install behavior so the new surface is actually usable. End with a packaging-level verification pass rather than assuming markdown-only parity.

**Tech Stack:** Markdown, JSON, shell installer, OpenCode command docs, Gemini extension metadata, git-based verification

## Global Constraints

- Exact command and artifact surface parity is required; similar behavior in a different layout is not enough.
- Evaluate and implement in this order: surface layer, protocol layer, then wiring layer.
- Every parity status must cite concrete evidence with local file paths and line references.
- If current doctrine contradicts upstream behavior, record it as `conflict` before changing anything.
- Prefer the smallest correct change set; do not add duplicate mirrors unless a host requires them.
- Do not rely on upstream README wording alone when stronger upstream repo evidence is available.
- Stop and ask if parity requires a doctrine or product decision that is not mechanically implied by the audit.
- Do not commit unless the user explicitly asks for a commit.

---

### Task 1: Create the parity report baseline

**Files:**
- Create: `docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
- Reference: `README.md`
- Reference: `skill/SKILL.md`
- Reference: `workflow.md`
- Reference: `implement.md`
- Reference: `review.md`
- Reference: `install.sh`
- Reference: `gemini-extension.json`
- Reference: `.github/copilot-instructions.md`
- Reference: `.github/agents/conductor.agent.md`
- Reference: `docs/superpowers/specs/2026-07-27-conductor-parity-design.md`

**Interfaces:**
- Consumes: upstream Conductor README plus any directly inspected upstream command or skill files
- Produces: a parity matrix with rows for `setup`, `new-track`, `implement`, `review`, `status`, `revert`, artifact layout, and packaging/discoverability

- [ ] **Step 1: Create the report skeleton**

```md
# Conductor Parity Report

## Commands

| Upstream surface | Local surface | Status | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |
| `conductor-setup` | no local command found yet | unverified | upstream README command list plus local repo scan in Step 2 | add command doc if local scan confirms absence |
| `conductor-new-track` | no local command found yet | unverified | upstream README command list plus local repo scan in Step 2 | add command doc if local scan confirms absence |
| `conductor-implement` | `implement.md` at repo root | unverified | `implement.md:1-91` | move to `.opencode/command/implement.md` if audit confirms OpenCode command discovery requires it |
| `conductor-review` | `review.md` at repo root | unverified | `review.md:1-97` | move to `.opencode/command/review.md` if audit confirms OpenCode command discovery requires it |
| `conductor-status` | no local command found yet | unverified | upstream README command list plus local repo scan in Step 2 | add command doc if local scan confirms absence |
| `conductor-revert` | no local command found yet | unverified | upstream README command list plus local repo scan in Step 2 | add command doc if local scan confirms absence |

## Artifacts

| Upstream artifact | Local artifact | Status | Evidence | Recommended fix |
| --- | --- | --- | --- | --- |
| `conductor/workflow.md` | `workflow.md` at repo root | unverified | `workflow.md:1-87` | move to `conductor/workflow.md` if audit confirms exact path parity is required |
| `conductor/tracks.md` | no local artifact found yet | unverified | local repo scan in Step 2 | create `conductor/tracks.md` if local scan confirms absence |
| `conductor/tracks/<track_id>/metadata.json` | no local artifact found yet | unverified | local repo scan in Step 2 | add `metadata.json` generation to the new-track command if missing |

## Wiring

| Surface | Status | Evidence | Recommended fix |
| --- | --- | --- | --- |
| OpenCode command discovery | unverified | local repo scan in Step 2 | create `.opencode/command/*.md` if no discoverable command surface exists |
| Installer packaging | unverified | `install.sh:1-38`, `gemini-extension.json:1-5` | expand installer payload if single-file packaging blocks parity |
```

- [ ] **Step 2: Fill the local evidence rows from the current repo**

```bash
rg -n "description:|@conductor/|conductor-|tracks.md|workflow.md|install" \
  README.md skill/SKILL.md workflow.md implement.md review.md install.sh gemini-extension.json \
  .github/copilot-instructions.md .github/agents/conductor.agent.md
```

Expected: line-level evidence showing the repo is currently centered on `skill/SKILL.md`, with draft command docs at repo root and no existing `.opencode/command/` surface.

- [ ] **Step 3: Add upstream command and artifact rows from inspected upstream sources**

```md
| `conductor-review` | `review.md` at repo root | partial | `review.md:1-97` | move to `.opencode/command/review.md`, update references, verify host discovery |
| `conductor-status` | no local command found | missing | `README.md:1-16`, `skill/SKILL.md:1-213` | add OpenCode command doc and supporting track-status contract |
```

- [ ] **Step 4: Classify each row as `match`, `partial`, `missing`, or `conflict`**

```md
- `match`: same command/artifact surface and materially same behavior
- `partial`: present but incomplete, relocated, or behaviorally weaker
- `missing`: no local implementation exists
- `conflict`: local doctrine contradicts upstream parity requirements
```

- [ ] **Step 5: Verify the report has one row for every required command and artifact**

Run: `rg -n "conductor-(setup|new-track|implement|review|status|revert)|conductor/workflow.md|metadata.json|tracks.md" docs/superpowers/reports/2026-07-27-conductor-parity-report.md`

Expected: every required command and major artifact appears at least once in the report.

### Task 2: Move current draft docs onto the canonical local surface

**Files:**
- Create: `conductor/workflow.md`
- Create: `.opencode/command/implement.md`
- Create: `.opencode/command/review.md`
- Delete: `workflow.md`
- Delete: `implement.md`
- Delete: `review.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: current root-level `workflow.md`, `implement.md`, and `review.md`
- Produces: one canonical workflow file under `conductor/` and OpenCode-discoverable command docs under `.opencode/command/`

- [ ] **Step 1: Copy `workflow.md` into the canonical artifact path**

```md
# conductor/workflow.md

Copy the current root `workflow.md` content verbatim into `conductor/workflow.md`, preserving the test-enforcement table, strict test-first and test-after loops, manual review gate, and commit strategy sections.
```

- [ ] **Step 2: Copy `implement.md` into the OpenCode command surface and fix its references**

```md
---
description: Implement a Conductor track phase-by-phase, following conductor/workflow.md's TDD enforcement, with per-phase checkpoints and in-flight corrections
agent: build
---

@conductor/workflow.md
@conductor/tracks/$ARGUMENTS/plan.md
@conductor/tracks/$ARGUMENTS/spec.md
```

- [ ] **Step 3: Copy `review.md` into the OpenCode command surface and fix its references**

```md
---
description: Run Conductor's automated review on a completed track, then wait for explicit manual approval before finalizing
agent: build
---

@conductor/workflow.md
@conductor/tracks/$ARGUMENTS/spec.md
@conductor/tracks/$ARGUMENTS/plan.md
```

- [ ] **Step 4: Delete the root-level duplicates after the new paths exist**

```bash
rg -n "@conductor/workflow.md|conductor/tracks/\$ARGUMENTS" .opencode/command/implement.md .opencode/command/review.md conductor/workflow.md
```

Expected: the new canonical paths contain the content and the old root-level copies are no longer needed.

- [ ] **Step 5: Update `README.md` to describe the new local command and artifact locations**

```md
- Canonical workflow artifact: `conductor/workflow.md`
- OpenCode command docs: `.opencode/command/*.md`
- Canonical doctrine: `skill/SKILL.md` unless parity work replaces or narrows that claim
```

### Task 3: Add the missing command surface for setup, new-track, status, and revert

**Files:**
- Create: `.opencode/command/setup.md`
- Create: `.opencode/command/new-track.md`
- Create: `.opencode/command/status.md`
- Create: `.opencode/command/revert.md`
- Modify: `.opencode/command/implement.md`
- Modify: `.opencode/command/review.md`
- Create: `conductor/tracks.md`

**Interfaces:**
- Consumes: upstream command contract established in the parity report
- Produces: a complete OpenCode command surface matching the upstream lifecycle and a local `conductor/tracks.md` contract that those commands share

- [ ] **Step 1: Add the setup command contract**

```md
@conductor/product.md
@conductor/product-guidelines.md
@conductor/tech-stack.md
@conductor/workflow.md
@conductor/code_styleguides/
@conductor/tracks.md

Create or refresh the project context files above, then pause for user review before treating setup as complete.
```

- [ ] **Step 2: Add the new-track command contract**

```md
@conductor/tracks/$ARGUMENTS/spec.md
@conductor/tracks/$ARGUMENTS/plan.md
@conductor/tracks/$ARGUMENTS/metadata.json

Generate a spec and phased plan for the new track, require task type tags for workflow enforcement, and pause for approval before implementation.
```

- [ ] **Step 3: Add the status command contract**

```md
@conductor/tracks.md

Read `conductor/tracks.md` and summarize active, blocked, and completed tracks without editing product code.
```

- [ ] **Step 4: Add the revert command contract**

```md
Analyze git history plus `conductor/tracks.md` and the target track's `plan.md` to revert a track, phase, or task safely, resetting checklist state from `[x]` back to `[ ]` where appropriate.
```

- [ ] **Step 5: Cross-check the full command set now exists in the OpenCode command path**

Run: `rg -n "^description:" .opencode/command/*.md`

Expected: exactly six command docs exist: `setup`, `new-track`, `implement`, `review`, `status`, and `revert`.

### Task 4: Reconcile doctrine, metadata, and installation with the new command surface

**Files:**
- Modify: `skill/SKILL.md`
- Modify: `README.md`
- Modify: `.github/copilot-instructions.md`
- Modify: `.github/agents/conductor.agent.md`
- Modify: `install.sh`
- Modify: `gemini-extension.json`

**Interfaces:**
- Consumes: verified parity gaps from the report plus the new local command layout
- Produces: packaging and wrapper behavior that expose the parity surface consistently across supported hosts

- [ ] **Step 1: Update `skill/SKILL.md` only after recording any doctrine conflict in the report**

```md
If `skill/SKILL.md` currently claims a single-file, delegation-only contract that contradicts the upstream lifecycle, either:
1. narrow that claim so command docs can own the lifecycle behavior, or
2. stop and ask the user before rewriting doctrine more broadly.
```

- [ ] **Step 2: Update the wrapper docs to point at the parity surface instead of the old single-file layout**

```md
- `.github/copilot-instructions.md`
- `.github/agents/conductor.agent.md`
- `README.md`

Describe where command docs live, where workflow and tracks artifacts live, and how installation exposes them.
```

- [ ] **Step 3: Update `install.sh` to install the full OpenCode and Gemini-compatible surface, not just `skill/SKILL.md`**

```bash
cp -R "$ROOT/.opencode" "$HOME/.opencode/conductor"
cp -R "$ROOT/conductor" "$HOME/.opencode/conductor"
cp "$ROOT/skill/SKILL.md" "$HOME/.opencode/skill/conductor/SKILL.md"
```

Use the exact copy targets discovered in the audit; do not keep shipping a single-file install if parity requires multiple files.

- [ ] **Step 4: Expand `gemini-extension.json` or companion Gemini files only if the audit shows the current manifest is too thin for parity**

```json
{
  "name": "conductor",
  "version": "0.4.0",
  "contextFileName": "SKILL.md"
}
```

If this manifest remains sufficient after the audit, leave it unchanged and record that as a `match`.

- [ ] **Step 5: Verify wrapper docs and installer all reference the same canonical paths**

Run: `rg -n "skill/SKILL.md|\.opencode/command|conductor/workflow.md|conductor/tracks.md|install" README.md .github/copilot-instructions.md .github/agents/conductor.agent.md install.sh`

Expected: no stale references to root-level `workflow.md`, `implement.md`, or `review.md`, and no claim that the distribution is single-file-only if it no longer is.

### Task 5: Validate discoverability and packaging in a clean install target

**Files:**
- Modify: `docs/superpowers/reports/2026-07-27-conductor-parity-report.md`
- Reference: `install.sh`
- Reference: `.opencode/command/*.md`
- Reference: `conductor/workflow.md`
- Reference: `skill/SKILL.md`
- Reference: `gemini-extension.json`

**Interfaces:**
- Consumes: the restructured repo and installer
- Produces: final wiring verdicts in the parity report backed by a clean-install verification run

- [ ] **Step 1: Prepare a clean temporary HOME outside the repo**

```bash
mkdir -p "/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home"
```

- [ ] **Step 2: Run the installer from outside the source tree**

Run: `HOME="/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home" "/Users/dt105/git/playground/conductor2/install.sh"`

Expected: install succeeds without the repo-root guard firing and creates the host-specific conductor files under the temporary HOME.

- [ ] **Step 3: Verify the installed OpenCode and Gemini surfaces contain the required files**

```bash
rg -n "description:" \
  "/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home/.opencode" \
  "/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/conductor-home/.gemini"
```

Expected: the installed OpenCode tree contains the six command docs, and the Gemini tree contains the verified manifest/context files.

- [ ] **Step 4: Update the parity report with the final wiring verdicts**

```md
## Wiring

| Surface | Status | Evidence | Recommended fix |
| --- | --- | --- | --- |
| Installer copies full OpenCode command surface | match or partial based on the verification run | cite the exact final `install.sh` line numbers and the temporary install tree paths you inspected | none if all required files are present; otherwise specify the missing copy step |
```

- [ ] **Step 5: Run a final consistency check over the report and repo paths**

Run: `rg -n "match|partial|missing|conflict|\.opencode/command|conductor/workflow.md|conductor/tracks.md" docs/superpowers/reports/2026-07-27-conductor-parity-report.md README.md skill/SKILL.md install.sh`

Expected: the report statuses are populated, repo docs point at the canonical paths, and no stale path references remain.
