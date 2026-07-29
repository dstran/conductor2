# Concise Track Folder Names Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/conductor/new-track` generate concise `shortname_YYYYMMDD` track folder names instead of using the raw user input as the folder name.

**Architecture:** Single command-doc change to `.opencode/command/new-track.md`. It separates the track *description* (`$ARGUMENTS`) from a *generated track ID* (`shortname_YYYYMMDD`), adds a collision check, and creates artifacts under the generated ID. Downstream commands (`implement.md`, `review.md`, `revert.md`) already take the short track ID as `$ARGUMENTS` and are untouched.

**Tech Stack:** Markdown command doc, OpenCode command discovery, OpenCode `question` tool.

## Global Constraints

- Change scope is `.opencode/command/new-track.md` ONLY. Do NOT modify `implement.md`, `review.md`, `revert.md`, `setup.md`, `status.md`, `skill/SKILL.md`, or any `conductor/` artifact.
- Track ID format is exactly `shortname_YYYYMMDD` (shortname first, underscore, then the 8-digit date). Example: `user-auth_20260728`.
- The shortname is a concise 2-4 word kebab-case slug derived from the track description/type — NOT the raw `$ARGUMENTS`.
- A collision check must gate directory creation: if the generated ID already exists under `conductor/tracks/`, halt and ask (single-choice) to provide a unique name or resume the existing track.
- The `conductor/tracks.md` registry entry links to the track by its generated ID, using the human-readable description as the entry label.
- Preserve the existing handshake checks (require `conductor/index.md` and `conductor/tracks.md`; route back to `/setup` if missing/stale), the task-type tagging requirement, and the plan-first / approval-before-implement discipline.

---

### Task 1: Rework new-track.md to generate `shortname_YYYYMMDD` track IDs

**Files:**
- Modify (full rewrite): `.opencode/command/new-track.md`

**Interfaces:**
- Consumes: `$ARGUMENTS` (now the track description, not the folder name); `conductor/index.md` and `conductor/tracks.md` for handshake.
- Produces: track artifacts at `conductor/tracks/<track_id>/{spec.md,plan.md,metadata.json}` where `<track_id>` = `shortname_YYYYMMDD`; a `conductor/tracks.md` registry entry linking to that ID. Downstream `/conductor/implement <track_id>`, `/conductor/review <track_id>`, `/conductor/revert <track_id>` select the track by this short ID.

- [ ] **Step 1: Replace the entire contents of `.opencode/command/new-track.md`**

Write exactly this file:

````markdown
---
description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.

## 1. Track description

Treat `$ARGUMENTS` as the track **description** — the feature, bug fix, or chore the user wants to plan. It is NOT the folder name. If `$ARGUMENTS` is empty, ask the user for a brief description of the track before continuing. Infer and confirm the track type (feature, bug, chore, refactor, MVP).

## 2. Generate the track ID

Derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.

Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).

**Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.

## 3. Create the track artifacts

Under the generated track ID, create:

- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`

`metadata.json` records the track ID, type, status (`new`), and created/updated timestamps.

Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`).

## 4. Update the registry

Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:

`- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

## 5. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`.
````

- [ ] **Step 2: Verify the doc no longer uses `$ARGUMENTS` as the folder name and documents the required format**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- must NOT use \$ARGUMENTS as a path segment ---"
grep -nE 'tracks/\$ARGUMENTS' .opencode/command/new-track.md && echo "FAIL: still uses \$ARGUMENTS as folder" || echo "OK none"
echo "--- must document the shortname_YYYYMMDD format ---"
grep -nE 'shortname_YYYYMMDD|<shortname>_YYYYMMDD|_YYYYMMDD' .opencode/command/new-track.md | head
echo "--- must reference the generated <track_id> in artifact paths ---"
grep -nE 'conductor/tracks/<track_id>/(spec|plan|metadata)' .opencode/command/new-track.md | head
echo "--- collision check present ---"
grep -niE 'collision|already exists' .opencode/command/new-track.md | head
```

Expected: `OK none` for the `$ARGUMENTS`-as-folder check; the format line(s) appear; the three `<track_id>` artifact paths appear; a collision line appears.

- [ ] **Step 3: Verify scope — only new-track.md changed**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
git status --porcelain
```

Expected: only `.opencode/command/new-track.md` is modified. If anything else appears, revert it.

- [ ] **Step 4: Verify downstream commands still align with a short track-ID selector**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- downstream still select by \$ARGUMENTS (should be unchanged) ---"
grep -nE 'tracks/\$ARGUMENTS' .opencode/command/implement.md .opencode/command/review.md .opencode/command/revert.md
```

Expected: `implement.md`, `review.md`, `revert.md` still reference `conductor/tracks/$ARGUMENTS/...` (they select an existing track by its short ID — this is correct and unchanged).

- [ ] **Step 5: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/new-track.md
git commit -m "Generate concise shortname_YYYYMMDD track IDs in new-track"
```

---

## Self-Review

**Spec coverage:**
- Format `shortname_YYYYMMDD` → Task 1 §2 + Step 2 assertion. ✓
- Shortname is derived slug, not raw `$ARGUMENTS` → Task 1 §1-2 + Step 2 negative assertion. ✓
- Collision check gates dir creation → Task 1 §2 + Step 2 assertion. ✓
- Registry links by ID, labels by description → Task 1 §4. ✓
- Artifacts under generated ID → Task 1 §3 + Step 2 assertion. ✓
- Preserve handshake checks / task-type tags / plan-first / approval → Task 1 intro + §3 + §5. ✓
- Scope limited to new-track.md; downstream unchanged → Step 3 + Step 4. ✓

**Placeholder scan:** No TBD/TODO/vague directives. The full file content is given verbatim; all verification commands are concrete. ✓

**Type consistency:** The token `<track_id>` = `shortname_YYYYMMDD` is used consistently across §2, §3, §4, and the Step 2 assertions. The format string `_YYYYMMDD` matches between the spec, the file content, and the grep checks. ✓
