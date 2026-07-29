# `/review` Archive Step Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the port's `## Completed` registry model with upstream Gemini Conductor's Archive / Delete / Skip cleanup step in `/review`, and update the dependent docs (`tracks.md`, `status.md`, `setup.md`) so nothing references the dropped `## Completed` section.

**Architecture:** Four independent Markdown edits. `review.md` gets a rewritten closure (mark `[x]` in `## Active` + closure commit + git note) followed by an Archive/Delete/Skip menu; `tracks.md`, `status.md`, and `setup.md` are updated to drop the `## Completed` model. No runtime code; verification is grep + read-through.

**Tech Stack:** Markdown command docs, OpenCode command discovery, OpenCode `question` tool, git.

## Global Constraints

- Adopt upstream's model exactly: NO persistent `## Completed` section anywhere.
- On approval, `/review` marks the track `[x]` and removes the awaiting-review note, leaving it in `## Active`, BEFORE the cleanup menu.
- The approval closure (review-loop fixes + `[x]` marking, with the `review.md` git note) is one commit; the chosen Archive/Delete action is a SECOND, separate commit.
- Archive target path is exactly `conductor/archive/<track_id>/`.
- Commit messages: closure `conductor(track): <track_id> <title>`; archive `chore(conductor): Archive track '<track_id>'`; delete `chore(conductor): Delete track '<track_id>'`.
- Change set is EXACTLY these four files: `.opencode/command/review.md`, `conductor/tracks.md`, `.opencode/command/status.md`, `.opencode/command/setup.md`. Do NOT modify `implement.md`, `revert.md`, or `skill/SKILL.md`.
- Preserve `review.md` steps 1-8 unchanged (plan compliance, quality, style, security, tests, report, pause, correction loop).

---

### Task 1: Rewrite review.md closure into closure-commit + Archive/Delete/Skip

**Files:**
- Modify: `.opencode/command/review.md` — replace section "## 9. After explicit approval only" (currently lines 100-108, the final section) with a rewritten step 9 (closure) + new step 10 (cleanup).

**Interfaces:**
- Consumes: the approved track `$ARGUMENTS`, left by `/implement` in `## Active` as `[~]` with the awaiting-review note (unchanged steps 1-8).
- Produces: an approved track marked `[x]` in `## Active`; optionally its folder moved to `conductor/archive/<track_id>/` with the registry entry removed. Downstream `/status` reads `## Active`, `## Blocked`, and `conductor/archive/`.

- [ ] **Step 1: Replace the final section of `.opencode/command/review.md`**

Find the current final section (starts at the line `## 9. After explicit approval only` and runs to the end of the file):

```
## 9. After explicit approval only
1. Re-run the full test suite one final time.
2. Update `conductor/tracks.md` as the final closure step that `/review` owns: remove the awaiting-review note, move the track entry from `## Active` to `## Completed`, and mark it `[x]` using the exact registry encoding defined in `conductor/tracks.md`.
3. Stage and commit the review-loop fixes (if any) plus the `conductor/tracks.md` closure update with a short, clear summary message following `conductor/workflow.md`'s commit strategy (e.g. `conductor(track): <track_id> <title>`).
4. Attach the full verification report as a **git note** on that
   commit — not in the commit message body:
   `git notes add -m "$(cat conductor/tracks/$ARGUMENTS/review.md)" <commit-sha>`
   This keeps the commit message short while preserving a full,
   auditable record attached to the commit itself.
```

Replace it entirely with:

```
## 9. After explicit approval only — closure commit
1. Re-run the full test suite one final time.
2. Mark the track complete in `conductor/tracks.md`: remove the
   awaiting-review note and change the track entry to `[x]`. The entry
   stays in `## Active` — there is no separate completed section.
3. Stage and commit the review-loop fixes (if any) plus the
   `conductor/tracks.md` `[x]` marking with a short, clear summary
   message following `conductor/workflow.md`'s commit strategy
   (e.g. `conductor(track): <track_id> <title>`).
4. Attach the full verification report as a **git note** on that
   commit — not in the commit message body:
   `git notes add -m "$(cat conductor/tracks/$ARGUMENTS/review.md)" <commit-sha>`
   This keeps the commit message short while preserving a full,
   auditable record attached to the commit itself.

## 10. Track cleanup
Ask the user, with a multiple-choice question, what to do with the
now-completed track:
   - **Archive:** move the track out of the working tree, keeping it for
     the record.
   - **Delete:** permanently remove the track folder.
   - **Skip:** leave the track in place.

Then act on the choice:
   a. **Archive:** ensure `conductor/archive/` exists, then move
      `conductor/tracks/$ARGUMENTS/` to `conductor/archive/$ARGUMENTS/`.
      Remove the track's entry from `conductor/tracks.md`. Stage the move
      and the registry edit and commit with the message
      `chore(conductor): Archive track '$ARGUMENTS'`. Tell the user the
      track was archived. This is a separate commit from the step 9
      closure commit.
   b. **Delete:** ask a Yes/No question warning that this is an
      irreversible deletion. On yes, delete `conductor/tracks/$ARGUMENTS/`,
      remove the track's entry from `conductor/tracks.md`, and commit with
      the message `chore(conductor): Delete track '$ARGUMENTS'`. On no,
      treat it as Skip.
   c. **Skip:** leave the `[x]` entry in `## Active` and the folder in
      `conductor/tracks/` unchanged. No second commit.
```

- [ ] **Step 2: Verify the rewrite and that steps 1-8 are untouched**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- no ## Completed reference remains ---"
grep -nE '## Completed|to `## Completed`|Completed section' .opencode/command/review.md && echo "FAIL: Completed ref remains" || echo "OK none"
echo "--- archive move + path present ---"
grep -nE 'conductor/archive/\$ARGUMENTS' .opencode/command/review.md | head
echo "--- Archive/Delete/Skip menu present ---"
grep -nE '\*\*Archive:|\*\*Delete:|\*\*Skip:' .opencode/command/review.md
echo "--- separate archive/delete commit messages ---"
grep -nE "chore\(conductor\): Archive track|chore\(conductor\): Delete track" .opencode/command/review.md
echo "--- [x] marked, stays in Active (closure step) ---"
grep -nE 'stays in `## Active`|change the track entry to `\[x\]`' .opencode/command/review.md | head
echo "--- steps 1-8 still present ---"
grep -nE '^## 1\. Plan compliance|^## 8\. The correction loop' .opencode/command/review.md
```

Expected: `OK none`; the archive path line appears; the three menu labels appear; both `chore(conductor):` commit messages appear; the `[x]`/stays-in-Active lines appear; steps 1 and 8 headers still present.

- [ ] **Step 3: Verify scope — only review.md changed**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
git status --porcelain
```

Expected: only `.opencode/command/review.md` modified.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/review.md
git commit -m "Add Archive/Delete/Skip cleanup to /review closure"
```

---

### Task 2: Drop the Completed model from tracks.md

**Files:**
- Modify: `conductor/tracks.md` — remove the `## Completed` section and its encoding; update the `[x]` legend; document the archive location.

**Interfaces:**
- Consumes: nothing.
- Produces: a registry doc with only `## Active` and `## Blocked` sections. `/review` (Task 1) marks completed tracks `[x]` in `## Active` and may remove archived entries; `/status` (Task 3) reads `## Active`, `## Blocked`, and `conductor/archive/`.

- [ ] **Step 1: Update the `[x]` legend line**

In `conductor/tracks.md`, replace this line:

```
- `[x]` means complete.
```

with:

```
- `[x]` means complete. A completed track stays in `## Active` as `[x]`
  unless `/review` archives or deletes it.
```

- [ ] **Step 2: Remove the Completed lifecycle encoding**

Delete this line from the "Exact lifecycle encodings" list:

```
- Complete: place the track in `## Completed` as `[x]`.
```

And in its place add:

```
- Complete: mark the track `[x]` in `## Active`.
- Archived/Deleted: `/review` may move a completed track's folder to
  `conductor/archive/<track_id>/` (removing its registry entry) or delete
  it outright.
```

- [ ] **Step 3: Remove the `## Completed` section**

Delete these final three lines of the file:

```
## Completed

<!-- /review moves approved track entries here as [x]. -->
```

The file should now end with the `## Blocked` section and its comment.

- [ ] **Step 4: Verify**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- no Completed section/encoding remains ---"
grep -nE '## Completed|place the track in `## Completed`' conductor/tracks.md && echo "FAIL" || echo "OK none"
echo "--- archive location documented ---"
grep -nE 'conductor/archive/<track_id>' conductor/tracks.md | head
echo "--- sections present ---"
grep -nE '^## Active|^## Blocked' conductor/tracks.md
```

Expected: `OK none`; the archive line appears; `## Active` and `## Blocked` present (and no `## Completed`).

- [ ] **Step 5: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add conductor/tracks.md
git commit -m "Drop Completed section from tracks registry in favor of archive"
```

---

### Task 3: Update status.md to summarize active/blocked/archived

**Files:**
- Modify: `.opencode/command/status.md` — description frontmatter + body.

**Interfaces:**
- Consumes: `conductor/tracks.md` (`## Active`, `## Blocked`) and `conductor/archive/`.
- Produces: a `/status` summary of active, blocked, and archived tracks. No `## Completed` reference.

- [ ] **Step 1: Replace the full contents of `.opencode/command/status.md`**

Write exactly this file:

```markdown
---
description: Summarize active, blocked, and archived Conductor tracks from the registry and archive directory without editing product code
agent: build
---

@conductor/tracks.md

Read `conductor/tracks.md` and summarize the tracks without editing product code:

- **Active:** entries under `## Active`. Distinguish planned (`[ ]`),
  in progress (`[~]`), awaiting review (`[~]` with the awaiting-review
  note), and completed-in-place (`[x]`).
- **Blocked:** entries under `## Blocked`, including each `Blocker:` note.
- **Archived:** if `conductor/archive/` exists, list the archived track
  directories inside it. These have been removed from the registry.
```

- [ ] **Step 2: Verify**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- no Completed reference ---"
grep -niE 'completed tracks|## completed' .opencode/command/status.md && echo "FAIL" || echo "OK none"
echo "--- mentions archive ---"
grep -nE 'conductor/archive/|Archived' .opencode/command/status.md | head
```

Expected: `OK none` (note: the word "completed-in-place" is fine — the failing grep targets "completed tracks"/"## completed"); the archive lines appear.

- [ ] **Step 3: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/status.md
git commit -m "Summarize archived tracks instead of completed in /status"
```

---

### Task 4: Stop setup.md from creating a Completed section

**Files:**
- Modify: `.opencode/command/setup.md:173` — the tracks-registry creation instruction.

**Interfaces:**
- Consumes: nothing.
- Produces: setup creates a registry skeleton with only `## Active` and `## Blocked`, consistent with Task 2's registry model.

- [ ] **Step 1: Update the registry-creation instruction**

In `.opencode/command/setup.md`, replace this line (line 173):

```
If `conductor/tracks.md` is missing, create it with the standard registry skeleton (`# Tracks Registry` header plus empty `## Active`, `## Blocked`, and `## Completed` sections and the lifecycle-encoding notes). Do not add any track entries — `/new-track` owns those.
```

with:

```
If `conductor/tracks.md` is missing, create it with the standard registry skeleton (`# Tracks Registry` header plus empty `## Active` and `## Blocked` sections and the lifecycle-encoding notes). Do not add any track entries — `/new-track` owns those.
```

- [ ] **Step 2: Verify**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- setup no longer creates Completed ---"
grep -nE 'Completed' .opencode/command/setup.md && echo "FAIL: Completed ref remains" || echo "OK none"
echo "--- still names Active + Blocked ---"
grep -nE '`## Active` and `## Blocked`' .opencode/command/setup.md
```

Expected: `OK none`; the Active + Blocked line appears.

- [ ] **Step 3: Final cross-file consistency check**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- zero ## Completed anywhere in command docs + registry ---"
grep -rnE '## Completed' .opencode/command/ conductor/tracks.md && echo "FAIL: stray Completed section" || echo "OK none"
```

Expected: `OK none`.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/setup.md
git commit -m "Stop setup from creating a Completed registry section"
```

---

## Self-Review

**Spec coverage:**
- review.md step 9 rewrite (mark `[x]` in Active, closure commit + git note) → Task 1. ✓
- review.md step 10 Archive/Delete/Skip, archive move to `conductor/archive/<id>/`, registry removal, separate `chore(conductor): Archive`/`Delete` commits → Task 1. ✓
- tracks.md drop `## Completed` section + encoding, keep Active/Blocked, update `[x]` legend, document archive location → Task 2. ✓
- status.md summarize active/blocked/archived, no Completed → Task 3. ✓
- setup.md create registry with only Active + Blocked → Task 4. ✓
- Scope = exactly the four files; implement.md/revert.md/skill untouched → each task's scope/verify steps + Task 4 Step 3 cross-check. ✓

**Placeholder scan:** No TBD/TODO/vague directives. All replacement text is given verbatim; all verification commands are concrete. ✓

**Type consistency:** `conductor/archive/<track_id>/` (docs) and `conductor/archive/$ARGUMENTS/` (review.md runtime) are the same path with the token that each file uses. Commit messages `conductor(track): <track_id> <title>`, `chore(conductor): Archive track '<track_id>'`, `chore(conductor): Delete track '<track_id>'` are identical between the Global Constraints and Task 1's file content. `## Active`/`## Blocked` section names are consistent across Tasks 2, 3, 4. ✓
