# Doctrine Update Propagation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the design in
`docs/superpowers/specs/2026-09-03-doctrine-update-propagation-design.md`:
let a target repo that already ran `/conductor/setup` catch its
`conductor/workflow.md` up to whatever doctrine is currently installed,
via a new `/conductor/update` command, a version marker stamped by
`install.sh`, and a passive staleness nudge in `/conductor/status` —
without ever touching `product.md`, `tech-stack.md`,
`product-guidelines.md`, `tracks/*`, or `code_styleguides/*`.

**Architecture:** Five independently committable changes:

1. Extract `workflow.md`'s content out of `setup.md`'s inlined fenced
   block into a new standalone asset, `conductor/assets/workflow-template.md`
   — a content-neutral refactor that also removes the dual-maintenance
   hazard between `conductor/workflow.md` and `setup.md`'s embedded copy
   (the same hazard that caused an extra reconciliation task during the
   phase-auto-checkpoint work).
2. `install.sh` computes the installed commit SHA and appends a trailing
   `<!-- conductor-workflow-version: <sha> -->` marker when it copies the
   template into the installed command directory.
3. New `.opencode/command/update.md` reads both markers (installed vs.
   target repo's `conductor/workflow.md`), diffs, confirms, and overwrites
   on approval.
4. `.opencode/command/status.md` gains one additional report line
   comparing the same two markers.
5. `README.md`'s command table gains `/conductor/update`.

No change to `.opencode/command/revert.md`, `implement.md`, `new-track.md`,
or `review.md` — the update commit is an ordinary commit `/revert`'s
existing generic mechanism already handles, and no other command's logic
is affected. Verified with the same two-layer approach as prior plans in
this repo: static grep/diff checks per doc edit, then live `opencode run
--command <name> --dir <fixture>` behavioral tests against disposable
`/tmp` git fixtures.

**Tech Stack:** Markdown command docs (OpenCode command discovery), bash,
git, `diff`, `opencode run` for live behavioral fixtures.

## Global Constraints

- **Scope is `workflow.md` only (spec Non-goals):** `product.md`,
  `tech-stack.md`, `product-guidelines.md`, `tracks/*`, and
  `code_styleguides/*` are never read, diffed, or written by any change
  in this plan. Style guides are explicitly excluded because they can
  carry user-appended custom rules (`setup.md` step 6.4) that a blind
  overwrite would destroy.
- **Marker format, exact (spec §2):** `<!-- conductor-workflow-version:
  <sha> -->` as the trailing line of the installed
  `assets/workflow-template.md`, where `<sha>` is `git rev-parse
  --short HEAD` computed by `install.sh` at install time. This repo's
  own `conductor/workflow.md` (used for dogfooding) carries no marker —
  it is hand-kept byte-identical to `workflow-template.md`, not produced
  by `install.sh`/`setup.md`'s copy step.
- **Missing marker on the target counts as stale, never as an error
  (spec §2, §3, Layer 2 "Missing marker" scenario):** a target repo's
  `conductor/workflow.md` written before this feature existed has no
  marker line at all; `/update` must treat that identically to a
  genuine SHA mismatch, not as a special/error case.
- **No clean-working-tree precondition for `/update` (spec §3 step 4):**
  `/update` only ever reads/writes/stages `conductor/workflow.md` and
  makes no assumption about the rest of the working tree.
- **`/update` commit message, exact (spec §3 step 3):**
  `conductor(setup): Update workflow.md to <sha>`, staging only
  `conductor/workflow.md`.
- **No change to `revert.md`'s source text (spec §5, Non-goals):** Task
  5's fixtures only *verify* the update commit is an ordinary commit
  `/revert` handles generically — no `revert.md` edit is in scope.
- **No passive checks in `implement.md`, `new-track.md`, or `review.md`
  (spec Non-goals):** the only passive nudge is the new line in
  `status.md` (Task 4).

---

### Task 1: Extract `workflow.md`'s content into a standalone template asset

**Files:**
- Create: `conductor/assets/workflow-template.md`
- Modify: `.opencode/command/setup.md:73-229` (step 7's header sentence and
  fenced content block)

**Interfaces:**
- Consumes: nothing new from other files — this is a pure extraction of
  content that already exists identically in `conductor/workflow.md` and
  `setup.md`'s fenced block (confirmed identical below).
- Produces: `conductor/assets/workflow-template.md`, which Task 2
  (install.sh) copies and stamps, and which `setup.md` step 7 now copies
  from instead of inlining. This repo's own `conductor/workflow.md`
  remains hand-kept identical to this new file (no marker) — it is
  source-tree content, not an installed target.

- [ ] **Step 1: Confirm `conductor/workflow.md` and `setup.md`'s embedded copy are still byte-identical**

```bash
cd /Users/dt105/git/playground/conductor2
diff conductor/workflow.md <(sed -n '78,228p' .opencode/command/setup.md)
```

Expected: no output (files match). If they differ, stop and reconcile
before proceeding — Step 2 below copies `conductor/workflow.md` verbatim
as the new template, so it must be the authoritative, current version.

- [ ] **Step 2: Create the new template file**

```bash
cd /Users/dt105/git/playground/conductor2
mkdir -p conductor/assets
cp conductor/workflow.md conductor/assets/workflow-template.md
```

- [ ] **Step 3: Verify the new file's content**

```bash
cd /Users/dt105/git/playground/conductor2
diff conductor/workflow.md conductor/assets/workflow-template.md
wc -l conductor/assets/workflow-template.md
```

Expected: `diff` prints no output; `wc -l` reports `151`.

- [ ] **Step 4: Replace `setup.md` step 7's inline block with a copy instruction**

Find this exact text at `setup.md:73-229` (the full step 7 section,
including its fenced content block):

````markdown
## 7. Workflow (`conductor/workflow.md`)

If `conductor/workflow.md` is missing, explain that the workflow defines the binding "rules of the game" (test enforcement by task type, phase checkpoints, commit strategy) that `/implement` and `/review` follow, then write this exact content:

```markdown
# Workflow

This file defines *how* work gets done on this project: methodology,
test enforcement, and commit conventions. `/implement` and `/review`
both read this file before acting — it is binding, not a suggestion.

## Test enforcement by task type

Every task in a track's `plan.md` must be tagged with one of the
types below. `/new-track` adds the initial tags before plan approval,
and `/review` must tag any tasks it appends in a `Review Fixes`
phase before those fixes are implemented.

| Task type | Enforcement | Rationale |
|---|---|---|
| `backend-logic` (services, business logic, utility functions) | **Strict test-first** | Contract is knowable up front; test-first improves interface design |
| `api-client` (calls to an external or internal API, e.g. an Angular service) | **Strict test-first** | Request/response shape is known before the call is written |
| `api-contract` — interface already specified in `plan.md` | **Test-first** | Same reasoning as above |
| `api-contract` — interface still exploratory | **Test-after** (still required) | Forcing test-first here produces guesses that get rewritten |
| `frontend-ui` — component logic (state, handlers, computed values) | **Test-after** (test-first optional) | Logic is testable but often clarified while building |
| `frontend-ui` — styling/layout only | **No test required** | No behavioral signal; overhead with no payoff |
| `e2e-flow` | **Test-after only — never test-first** | Depends on rendered UI/selectors that don't exist yet |

If a task doesn't cleanly fit one of these, the agent should flag it
in `plan.md` with `[needs classification]` and ask the user, rather
than guessing.

## The strict test-first loop

For any task enforced as test-first:

1. Write the test. It must fail.
2. Run it. Confirm it fails for the *right* reason (missing
   implementation — not a typo, bad import, or config error).
3. Implement the minimum needed to pass.
4. Run the test again. Confirm it passes.
5. Mark the task `[x]` in `plan.md` only after step 4 succeeds.

The agent must not skip step 2. A test that was never confirmed to
fail first is not verified TDD — it's just a test written early.

## The test-after loop

For tasks enforced as test-after (still required):

1. Implement the task.
2. Write the test.
3. Run it. Confirm it passes.
4. Mark the task `[x]` in `plan.md`.

## Coverage expectations

- Every `backend-logic` and `api-client` task must have at least one
  passing unit test before the task is marked complete.
- `e2e-flow` tasks are validated once, at the end of the track during
  `/review` — not per-task.
- No task is marked `[x]` on the strength of an assumption that a
  test "would" pass. It must have actually been run.

## Task commit procedure

Every task, once its test-first/test-after loop (per the enforcement
table above) has actually passed, is committed in exactly two steps —
whether the task came from `/new-track`'s original plan or from
`/review`'s appended "Review Fixes" phase (see `review.md`'s correction
loop). This procedure is the single source of truth for both:

1. **Task code commit.** Stage the code and test changes for this task
   only. Commit with a short conventional message describing the change
   (e.g. `feat(auth): Add login endpoint`). Get its SHA:
   `git log -1 --format=%h`.
2. **Task plan-update commit.** Edit `plan.md`: change the task's
   checkbox from `[~]` to `[x]` and append the task's type tag and the
   7-character SHA from step 1, producing exactly:
   `- [x] Task: <description> [<task-type>] <sha>`
   Stage only `plan.md` and commit with message
   `conductor(plan): Mark task '<task>' as complete`.

Never combine these into one commit, and never write the SHA into
`plan.md` before the code commit exists — the SHA must reference a real,
already-made commit.

## Phase checkpoint procedure

Every phase heading in `plan.md` is either tagged `[manual-checkpoint]`
or left untagged. `/new-track` sets this tag at plan-generation time
based on its tagging heuristic (see `new-track.md`); the user may add or
remove the tag by hand at any point before `/implement` reaches that
phase's checkpoint step. `/implement` reads the heading fresh each time
it reaches this step — it has no memory of a tag that was later removed,
and it never adds the tag itself.

- **Tagged `[manual-checkpoint]`:** `/implement` pauses at the end of the
  phase, presents a summary, asks "does this meet expectations?", and
  only checkpoints the phase after an explicit yes (looping on feedback
  the same way `/review` does, including the same 3rd-round nudge).
  Nothing beyond a phase checkpoint is finalized without that.
- **Untagged (the default):** `/implement` runs the phase's tests,
  presents the same summary plus the line "No manual checkpoint
  required — auto-checkpointing," and proceeds straight to checkpointing
  — no pause, no wait for a reply.

Once a phase is ready to checkpoint (explicit yes for a tagged phase;
immediately for an untagged phase):

1. Identify the last task code commit made in this phase (from step 1 of
   the task commit procedure above, for the phase's final task). Do NOT
   create a new empty commit — the checkpoint always points at an
   existing task commit.
2. Attach the phase summary (automated test results + manual verification
   steps, if any) as a **git note** on that commit — not in a commit
   message body: `git notes add -m "<summary>" <sha>`
3. Edit `plan.md`: append `[checkpoint: <sha>]` to the phase's heading —
   after any existing `[manual-checkpoint]` tag — producing exactly:
   `## Phase <N>: <title> [checkpoint: <sha>]` (untagged phase), or
   `## Phase <N>: <title> [manual-checkpoint] [checkpoint: <sha>]`
   (tagged phase). Stage only `plan.md` and commit with message
   `conductor(plan): Mark phase '<N> — <title>' as complete`.

Once all phases are checkpointed, `/implement` stops and hands off to
`/review` for the track-level pass: full test suite, style, security, and
plan compliance across the whole track. `/review` has its own
pause-and-ask gate before the final track-closure commit is made.
`/implement` never invokes `/review` itself — regardless of how many
phases in the track were tagged, the user must separately run
`/review <track_id>`.

## Commit strategy

- `/implement` and `/review` both follow the **task commit procedure**
  above for every task they complete (two commits per task: code, then
  plan update) and the **phase checkpoint procedure** above at the end of
  each phase (one plan-only commit per phase, referencing the last task
  commit — never a new empty commit).
- `/review` makes the final approval-gated track closure commit after
  its full-track pass, including any review-loop fixes and the
  `tracks.md` move to complete.
- Commit messages stay short and clean: task code commits are
  conventional (`feat(...)`, `fix(...)`, etc.); task plan updates use
  `conductor(plan): Mark task '<task>' as complete`; phase plan updates
  use `conductor(plan): Mark phase '<N> — <title>' as complete`; review
  closure uses a concise `conductor(track): <title>` summary with the
  track ID.
- Attach the phase summary or full review report to the corresponding
  commit as a **git note**, not in the commit message body. This keeps
  `git log` readable while preserving a complete, auditable record.
- No task plan-update commit happens before that task's test(s) have
  actually run and passed. No phase plan-update commit happens before the
  user has explicitly approved the current phase summary. No final
  closure commit happens before `/review` has run and the user has
  explicitly approved the current `review.md` after any correction loop.
```

## 8. Tracks registry (`conductor/tracks.md`)
````

Replace it with:

````markdown
## 7. Workflow (`conductor/workflow.md`)

The bundled workflow template lives at `~/.config/opencode/command/conductor/assets/workflow-template.md`.

If `conductor/workflow.md` is missing, explain that the workflow defines the binding "rules of the game" (test enforcement by task type, phase checkpoints, commit strategy) that `/implement` and `/review` follow, then copy it verbatim:

```bash
cp ~/.config/opencode/command/conductor/assets/workflow-template.md conductor/workflow.md
```

Do not paraphrase, summarize, or otherwise alter the copied content — `conductor/workflow.md` is a byte-for-byte copy of the installed template, including its trailing version marker (see `/conductor/update`, which relies on that marker being present and unmodified).

## 8. Tracks registry (`conductor/tracks.md`)
````

- [ ] **Step 5: Verify the replacement**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- old inlined fenced block is gone ---"
grep -n '# Workflow$' .opencode/command/setup.md && echo "FAIL: inlined content still present" || echo "OK: no inlined workflow content"
echo "--- new copy instruction present ---"
grep -n 'cp ~/.config/opencode/command/conductor/assets/workflow-template.md conductor/workflow.md' .opencode/command/setup.md
echo "--- step 8 heading immediately follows step 7 with no orphaned fence ---"
grep -n '^## 7\. Workflow\|^## 8\. Tracks registry' .opencode/command/setup.md
wc -l .opencode/command/setup.md
```

Expected: first grep prints `OK: no inlined workflow content` (the phrase
`# Workflow` as a standalone heading only ever existed inside the removed
fenced block); second grep finds one match; third grep finds both
headings with step 7 immediately before step 8 and no leftover fenced
block between them; `wc -l` reports a file roughly 151 lines shorter than
before (the content moved out, replaced by a much shorter instruction).

- [ ] **Step 6: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add conductor/assets/workflow-template.md .opencode/command/setup.md
git commit -m "Extract workflow.md content into a standalone template asset"
```

---

### Task 2: Stamp the installed workflow template with a version marker

**Files:**
- Modify: `install.sh:24-42` (the `install_opencode_surface` function)

**Interfaces:**
- Consumes: `conductor/assets/workflow-template.md` from Task 1.
- Produces: an installed `assets/workflow-template.md` with a trailing
  `<!-- conductor-workflow-version: <sha> -->` marker, which Task 3
  (`/update`) and Task 4 (`/status`) both read.

- [ ] **Step 1: Confirm current `install_opencode_surface` content**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '24,42p' install.sh
```

- [ ] **Step 2: Replace the function**

Find this exact text (lines 24-42):

```bash
install_opencode_surface() {
  # OpenCode discovers global skills under ~/.config/opencode/skills/<name>/SKILL.md
  # and global commands under ~/.config/opencode/command/**/*.md. Command names are
  # derived from the path after the "command/" prefix, so nesting under conductor/
  # exposes them as /conductor/<name>.
  local config="$HOME/.config/opencode"
  local skill_dir="$config/skills/conductor"
  local command_dir="$config/command/conductor"
  local assets_dir="$command_dir/assets/code_styleguides"

  rm -rf "$skill_dir" "$command_dir"
  mkdir -p "$skill_dir" "$command_dir" "$assets_dir"
  cp "$ROOT/skill/SKILL.md" "$skill_dir/SKILL.md"
  cp "$ROOT"/.opencode/command/*.md "$command_dir/"
  cp "$ROOT"/conductor/assets/code_styleguides/*.md "$assets_dir/"
  echo "  $skill_dir"
  echo "  $command_dir (/conductor/*)"
  echo "  $assets_dir (style guides)"
}
```

Replace it with:

```bash
install_opencode_surface() {
  # OpenCode discovers global skills under ~/.config/opencode/skills/<name>/SKILL.md
  # and global commands under ~/.config/opencode/command/**/*.md. Command names are
  # derived from the path after the "command/" prefix, so nesting under conductor/
  # exposes them as /conductor/<name>.
  local config="$HOME/.config/opencode"
  local skill_dir="$config/skills/conductor"
  local command_dir="$config/command/conductor"
  local styleguides_dir="$command_dir/assets/code_styleguides"
  local sha
  sha="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"

  rm -rf "$skill_dir" "$command_dir"
  mkdir -p "$skill_dir" "$command_dir" "$styleguides_dir"
  cp "$ROOT/skill/SKILL.md" "$skill_dir/SKILL.md"
  cp "$ROOT"/.opencode/command/*.md "$command_dir/"
  cp "$ROOT"/conductor/assets/code_styleguides/*.md "$styleguides_dir/"
  cp "$ROOT/conductor/assets/workflow-template.md" "$command_dir/assets/workflow-template.md"
  echo "<!-- conductor-workflow-version: $sha -->" >> "$command_dir/assets/workflow-template.md"
  echo "  $skill_dir"
  echo "  $command_dir (/conductor/*)"
  echo "  $styleguides_dir (style guides)"
  echo "  $command_dir/assets/workflow-template.md (workflow template, version $sha)"
}
```

(Note: `assets_dir` was renamed to `styleguides_dir` to keep the two asset
kinds — style guides vs. the workflow template — clearly distinct now
that there are two `cp` targets under `$command_dir/assets/`.)

- [ ] **Step 3: Verify the script is still syntactically valid and the new logic is present**

```bash
cd /Users/dt105/git/playground/conductor2
bash -n install.sh && echo "OK: syntax valid"
grep -n 'conductor-workflow-version' install.sh
grep -n 'rev-parse --short HEAD' install.sh
grep -n 'workflow-template.md' install.sh
```

Expected: `OK: syntax valid`; each grep finds at least one match.

- [ ] **Step 4: Smoke-test the install function in isolation**

Run the installer end to end against a throwaway `$HOME` to confirm the
marker actually lands correctly, without touching the real
`~/.config/opencode`:

```bash
cd /Users/dt105/git/playground/conductor2
FAKE_HOME=$(mktemp -d /tmp/conductor-fakehome.XXXXXX)
mkdir -p "$FAKE_HOME/somewhere-else"
HOME="$FAKE_HOME" bash -c "cd '$FAKE_HOME/somewhere-else' && '$(pwd)/install.sh'"
echo "=== installed template's last line ==="
tail -n 1 "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md"
echo "=== installed template minus marker matches source ==="
diff <(sed '$d' "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md") conductor/assets/workflow-template.md && echo "OK: content matches"
rm -rf "$FAKE_HOME"
```

Expected: the last-line output matches `<!-- conductor-workflow-version:
<7-char-sha> -->` (a real short SHA, not `unknown`, since this is a real
git repo); the diff prints no output followed by `OK: content matches`.

- [ ] **Step 5: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add install.sh
git commit -m "Stamp installed workflow-template.md with a version marker"
```

---

### Task 3: Add the `/conductor/update` command

**Files:**
- Create: `.opencode/command/update.md`

**Interfaces:**
- Consumes: the marker format from Task 2 (`<!-- conductor-workflow-version:
  <sha> -->` as the trailing line of both the installed
  `assets/workflow-template.md` and, once present, the target repo's
  `conductor/workflow.md`).
- Produces: the actual sync behavior Task 5's fixtures exercise directly,
  and the commit message format (`conductor(setup): Update workflow.md
  to <sha>`) that Task 5's `/revert` pass-through scenario relies on.

- [ ] **Step 1: Confirm the frontmatter/structure pattern used by other no-argument commands**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '1,10p' .opencode/command/status.md
```

Confirm `status.md` (a no-argument command, like `/update` will be) uses
`agent: build` frontmatter and no `$ARGUMENTS` reference — `update.md`
follows the same shape.

- [ ] **Step 2: Write `.opencode/command/update.md`**

```markdown
---
description: Sync conductor/workflow.md with the currently installed Conductor doctrine, if it has changed since /setup ran
agent: build
---

@conductor/workflow.md

`/conductor/update` keeps `conductor/workflow.md` in sync with whatever
Conductor doctrine is currently installed. It touches only
`conductor/workflow.md` — `product.md`, `tech-stack.md`,
`product-guidelines.md`, `conductor/tracks/`, and
`conductor/code_styleguides/` are never read or modified by this command.

If `conductor/index.md` is missing, offer to run `/setup` (Yes/No) and
HALT if declined.

## 1. Locate both copies

- **Installed template:**
  `~/.config/opencode/command/conductor/assets/workflow-template.md`.
  If this file is missing, tell the user their Conductor installation
  looks incomplete and suggest re-running the installer, then HALT.
- **Target copy:** `conductor/workflow.md` in the current project.

## 2. Compare version markers

Read the last line of each file.

- **Installed template's marker:** expected format
  `<!-- conductor-workflow-version: <sha> -->`. If this line is missing
  from the installed template, treat its SHA as `unknown` and continue
  (this should not normally happen, but is not a reason to halt).
- **Target's marker:** if `conductor/workflow.md`'s last line matches
  that same format, extract `<sha>`. If it does not match (no marker
  line at all — a target repo whose `/setup` ran before this feature
  existed), treat the target as having no marker. **A missing marker
  on the target always counts as stale** — never treat it as an error
  or ask a different question than the stale-path below.

## 3. Report or offer the update

**If the markers match exactly (both present, same `<sha>`):** report
`Workflow doctrine is up to date (<sha>).` and stop. Make no file
changes and no commit.

**Otherwise (markers differ, or the target has no marker):**

1. Show the user a full diff between the two files:
   `diff -u conductor/workflow.md ~/.config/opencode/command/conductor/assets/workflow-template.md`
2. Ask a Yes/No question: "Apply this update to conductor/workflow.md?"
3. **If no:** stop. Make no changes.
4. **If yes:** overwrite `conductor/workflow.md` with the installed
   template's exact content (including its trailing marker line). Stage
   only `conductor/workflow.md` and commit with the message
   `conductor(setup): Update workflow.md to <sha>`, where `<sha>` is the
   installed template's marker value from Step 2 (or `unknown` if it had
   none).

Do not require a clean working tree before doing this — this command
only ever reads and writes `conductor/workflow.md` and stages only that
one file, so unrelated uncommitted changes elsewhere in the repo cannot
be swept into this commit and are not a reason to block.

## 4. Announce completion

State the outcome plainly: either "already up to date" with the shared
SHA, or "updated from `<old-sha-or-none>` to `<new-sha>`" with the commit
that was made, or "update declined, no changes made" if the user said no
in Step 3.
```

- [ ] **Step 3: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- file exists with correct frontmatter ---"
sed -n '1,4p' .opencode/command/update.md
echo "--- missing-marker-is-stale rule present ---"
grep -n 'missing marker on the target always counts as stale' .opencode/command/update.md
echo "--- exact commit message format present ---"
grep -n "conductor(setup): Update workflow.md to <sha>" .opencode/command/update.md
echo "--- no clean-tree precondition language present ---"
grep -n 'Do not require a clean working tree' .opencode/command/update.md
echo "--- scope note excludes other artifacts ---"
grep -n 'product.md.*tech-stack.md.*product-guidelines.md' .opencode/command/update.md
```

Expected: every grep finds a match; the frontmatter shows
`description:` and `agent: build`.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/update.md
git commit -m "Add /conductor/update command to sync workflow.md doctrine"
```

---

### Task 4: Add a staleness nudge to `/conductor/status`

**Files:**
- Modify: `.opencode/command/status.md:37-52` (step 3, "Present the
  summary")

**Interfaces:**
- Consumes: the same marker format from Task 2/3.
- Produces: the exact report-line strings Task 5's fixtures assert on.

- [ ] **Step 1: Confirm current step 3 content**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '37,52p' .opencode/command/status.md
```

- [ ] **Step 2: Insert a new sub-step before "Report, in this order"**

Find this exact text (lines 37-52):

```markdown
## 3. Present the summary

Report, in this order:

1. **Current date/time.**
2. **Project status label** — `On Track` if at least one track has an
   in-progress or planned task and no track is `## Blocked`; `Blocked` if
   any track is under `## Blocked`; `Awaiting Review` if the
   furthest-along active track is in the awaiting-review state and none
   are blocked.
3. **Per active track:** track description, `completed/total
   (percentage%)`, current phase + current/in-progress task, next
   pending task, and any checkpoint inconsistency noted in step 1.
4. **Blockers:** every `Blocker:` note found under `## Blocked`.
5. **Archived tracks:** the list from step 2, or "none" if
   `conductor/archive/` doesn't exist.
```

Replace it with:

```markdown
## 3. Workflow doctrine staleness

Compare the last line of `conductor/workflow.md` against the last line
of `~/.config/opencode/command/conductor/assets/workflow-template.md`
(same marker format `/conductor/update` reads: `<!-- conductor-workflow-version:
<sha> -->`). A missing marker on either side counts as not matching.

- If they match: the report line is `Workflow doctrine: up to date
  (<sha>).`
- If they differ (including a missing marker on the target): the report
  line is `Workflow doctrine: stale (installed <installed-sha>, project
  <project-sha-or-"none">) — run /conductor/update`.

## 4. Present the summary

Report, in this order:

1. **Current date/time.**
2. **Project status label** — `On Track` if at least one track has an
   in-progress or planned task and no track is `## Blocked`; `Blocked` if
   any track is under `## Blocked`; `Awaiting Review` if the
   furthest-along active track is in the awaiting-review state and none
   are blocked.
3. **Per active track:** track description, `completed/total
   (percentage%)`, current phase + current/in-progress task, next
   pending task, and any checkpoint inconsistency noted in step 1.
4. **Blockers:** every `Blocker:` note found under `## Blocked`.
5. **Archived tracks:** the list from step 2, or "none" if
   `conductor/archive/` doesn't exist.
6. **Workflow doctrine line** from step 3, always shown last.
```

- [ ] **Step 3: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- new step 3 heading present ---"
grep -n '^## 3\. Workflow doctrine staleness' .opencode/command/status.md
echo "--- up-to-date line format present ---"
grep -n 'Workflow doctrine: up to date' .opencode/command/status.md
echo "--- stale line format present ---"
grep -n 'Workflow doctrine: stale' .opencode/command/status.md
echo "--- old step 3 renumbered to step 4 ---"
grep -n '^## 4\. Present the summary' .opencode/command/status.md
echo "--- new step 6 references the doctrine line ---"
grep -n 'Workflow doctrine line.*step 3' .opencode/command/status.md
```

Expected: all five greps find a match.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/status.md
git commit -m "Add workflow doctrine staleness line to /status"
```

---

### Task 5: Document `/conductor/update` in the README

**Files:**
- Modify: `README.md:73-81` (the command list under "## Usage")

**Interfaces:**
- Consumes: nothing.
- Produces: documentation only; no behavior.

- [ ] **Step 1: Confirm current content**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '73,81p' README.md
```

- [ ] **Step 2: Insert the new command line**

Find this exact text:

```markdown
- `/conductor/status` — summarize active, blocked, and archived tracks.
- `/conductor/revert` — revert a track, phase, or task.
```

Replace it with:

```markdown
- `/conductor/status` — summarize active, blocked, and archived tracks.
- `/conductor/revert` — revert a track, phase, or task.
- `/conductor/update` — sync `conductor/workflow.md` with the currently
  installed doctrine, if it has changed since `/setup` ran.
```

- [ ] **Step 3: Verify**

```bash
cd /Users/dt105/git/playground/conductor2
grep -n '/conductor/update' README.md
```

Expected: one match.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add README.md
git commit -m "Document /conductor/update in the README"
```

---

### Task 6: Behavioral fixture tests

**Files:**
- No source files modified — this task runs live `opencode run` fixtures
  against the finished Tasks 1-4 and reports pass/fail per scenario from
  the spec's Layer-2 test table.

**Interfaces:**
- Consumes: the finished `conductor/assets/workflow-template.md`,
  `.opencode/command/{update,status}.md`, and `install.sh` from Tasks
  1-4.
- Produces: a pass/fail record for each scenario in the spec's Layer-2
  table; no artifacts land in this repo (all fixtures live under `/tmp`
  and are deleted at the end).

- [ ] **Step 1: Build a fake `$HOME` with the real installer output**

This gives every fixture a real installed template with a real marker,
without touching the developer's actual `~/.config/opencode`:

```bash
cd /Users/dt105/git/playground/conductor2
FAKE_HOME=$(mktemp -d /tmp/conductor-update-fakehome.XXXXXX)
mkdir -p "$FAKE_HOME/elsewhere"
HOME="$FAKE_HOME" bash -c "cd '$FAKE_HOME/elsewhere' && '$(pwd)/install.sh'"
INSTALLED_SHA=$(tail -n 1 "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md" | grep -oE '[0-9a-f]{7,}')
echo "Installed SHA: $INSTALLED_SHA"
echo "$FAKE_HOME" > /tmp/update_fakehome_path.txt
echo "$INSTALLED_SHA" > /tmp/update_installed_sha.txt
```

Expected: `INSTALLED_SHA` prints a real 7+ character short SHA.

- [ ] **Step 2: Scenario A — up to date, no-op**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
INSTALLED_SHA=$(cat /tmp/update_installed_sha.txt)
FIXTURE_A=$(mktemp -d /tmp/conductor-update-fixtureA.XXXXXX)
mkdir -p "$FIXTURE_A/.opencode/command" "$FIXTURE_A/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/update.md .opencode/command/status.md "$FIXTURE_A/.opencode/command/"
cp conductor/index.md conductor/tracks.md "$FIXTURE_A/conductor/"
cp "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md" "$FIXTURE_A/conductor/workflow.md"
cd "$FIXTURE_A"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture A (workflow.md already matches installed template)"
BEFORE_SHA=$(git rev-parse HEAD)
cd /Users/dt105/git/playground/conductor2
HOME="$FAKE_HOME" opencode run --command update "" --format json --dir "$FIXTURE_A" > /tmp/update_scenarioA.json 2>&1
cd "$FIXTURE_A"
AFTER_SHA=$(git rev-parse HEAD)
echo "--- no new commit ---"
[ "$BEFORE_SHA" = "$AFTER_SHA" ] && echo "OK: no commit made" || echo "FAIL: unexpected commit"
echo "--- workflow.md unchanged ---"
diff conductor/workflow.md "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md" && echo "OK: unchanged"
grep -iE "up to date" /tmp/update_scenarioA.json && echo "OK: reported up to date"
```

Expected: `OK: no commit made`, `OK: unchanged`, `OK: reported up to
date`.

- [ ] **Step 3: Scenario B — stale, user approves**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
FIXTURE_B=$(mktemp -d /tmp/conductor-update-fixtureB.XXXXXX)
mkdir -p "$FIXTURE_B/.opencode/command" "$FIXTURE_B/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/update.md .opencode/command/status.md "$FIXTURE_B/.opencode/command/"
cp conductor/index.md conductor/tracks.md "$FIXTURE_B/conductor/"
cat > "$FIXTURE_B/conductor/workflow.md" <<'EOF'
# Workflow

This is a deliberately older/stale workflow.md body, distinct from the
currently installed template, used to exercise the stale-update path.

## Old Section

Old content that the installed template no longer has.
<!-- conductor-workflow-version: 0000000 -->
EOF
cd "$FIXTURE_B"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture B (stale workflow.md, marker 0000000)"
cd /Users/dt105/git/playground/conductor2
HOME="$FAKE_HOME" opencode run --command update "Yes, apply the update." --format json --dir "$FIXTURE_B" > /tmp/update_scenarioB.json 2>&1
cd "$FIXTURE_B"
echo "--- workflow.md now matches installed template ---"
diff conductor/workflow.md "$FAKE_HOME/.config/opencode/command/conductor/assets/workflow-template.md" && echo "OK: matches"
echo "--- commit exists with the exact expected message ---"
git log --oneline | grep -E 'conductor\(setup\): Update workflow.md to [0-9a-f]+' && echo "OK: commit message correct" || echo "FAIL: commit message missing/wrong"
echo "--- that commit staged only workflow.md ---"
LATEST_SHA=$(git log -1 --format=%H --grep='conductor(setup): Update workflow.md to')
git show --stat --format= "$LATEST_SHA" | grep -v '^$'
```

Expected: `OK: matches`; `OK: commit message correct`; the `git show
--stat` output lists exactly one file, `conductor/workflow.md`.

- [ ] **Step 4: Scenario C — stale, user declines**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
FIXTURE_C=$(mktemp -d /tmp/conductor-update-fixtureC.XXXXXX)
mkdir -p "$FIXTURE_C/.opencode/command" "$FIXTURE_C/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/update.md .opencode/command/status.md "$FIXTURE_C/.opencode/command/"
cp conductor/index.md conductor/tracks.md "$FIXTURE_C/conductor/"
cat > "$FIXTURE_C/conductor/workflow.md" <<'EOF'
# Workflow

Stale body, marker 0000000, same as fixture B — used to exercise the
decline path this time.
<!-- conductor-workflow-version: 0000000 -->
EOF
cd "$FIXTURE_C"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture C (stale workflow.md, decline path)"
BEFORE_SHA=$(git rev-parse HEAD)
cd /Users/dt105/git/playground/conductor2
HOME="$FAKE_HOME" opencode run --command update "No, do not apply the update." --format json --dir "$FIXTURE_C" > /tmp/update_scenarioC.json 2>&1
cd "$FIXTURE_C"
AFTER_SHA=$(git rev-parse HEAD)
echo "--- no new commit ---"
[ "$BEFORE_SHA" = "$AFTER_SHA" ] && echo "OK: no commit made" || echo "FAIL: unexpected commit"
echo "--- workflow.md still has the old marker ---"
tail -n 1 conductor/workflow.md | grep -q '0000000' && echo "OK: still stale" || echo "FAIL: file was changed despite decline"
```

Expected: `OK: no commit made`, `OK: still stale`.

- [ ] **Step 5: Scenario D — missing marker (pre-feature repo)**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
FIXTURE_D=$(mktemp -d /tmp/conductor-update-fixtureD.XXXXXX)
mkdir -p "$FIXTURE_D/.opencode/command" "$FIXTURE_D/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/update.md .opencode/command/status.md "$FIXTURE_D/.opencode/command/"
cp conductor/index.md conductor/tracks.md "$FIXTURE_D/conductor/"
cat > "$FIXTURE_D/conductor/workflow.md" <<'EOF'
# Workflow

This body has no version marker at all, simulating a repo whose /setup
ran before the doctrine-update-propagation feature existed.

## Test enforcement by task type

(old content, pre-feature, no trailing marker line below this section)
EOF
cd "$FIXTURE_D"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture D (no marker line at all)"
cd /Users/dt105/git/playground/conductor2
HOME="$FAKE_HOME" opencode run --command update "Yes, apply the update." --format json --dir "$FIXTURE_D" > /tmp/update_scenarioD.json 2>&1
cd "$FIXTURE_D"
echo "--- treated as stale, not an error (a commit was made) ---"
git log --oneline | grep -E 'conductor\(setup\): Update workflow.md to' && echo "OK: missing marker treated as stale" || echo "FAIL: no update applied"
echo "--- workflow.md now has a real marker ---"
tail -n 1 conductor/workflow.md | grep -E 'conductor-workflow-version: [0-9a-f]+' && echo "OK: marker now present"
```

Expected: `OK: missing marker treated as stale`; `OK: marker now
present`.

- [ ] **Step 6: Scenario E — unrelated dirty tree does not block the update**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
FIXTURE_E=$(mktemp -d /tmp/conductor-update-fixtureE.XXXXXX)
mkdir -p "$FIXTURE_E/.opencode/command" "$FIXTURE_E/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/update.md .opencode/command/status.md "$FIXTURE_E/.opencode/command/"
cp conductor/index.md conductor/tracks.md "$FIXTURE_E/conductor/"
cat > "$FIXTURE_E/conductor/workflow.md" <<'EOF'
# Workflow

Stale body for fixture E.
<!-- conductor-workflow-version: 0000000 -->
EOF
cd "$FIXTURE_E"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture E (stale workflow.md)"
echo "unrelated uncommitted change" >> README_UNRELATED.md
cd /Users/dt105/git/playground/conductor2
HOME="$FAKE_HOME" opencode run --command update "Yes, apply the update." --format json --dir "$FIXTURE_E" > /tmp/update_scenarioE.json 2>&1
cd "$FIXTURE_E"
echo "--- update still ran despite dirty tree ---"
git log --oneline | grep -E 'conductor\(setup\): Update workflow.md to' && echo "OK: update applied"
echo "--- unrelated file is still untracked/uncommitted, untouched ---"
git status --porcelain README_UNRELATED.md | grep -q '^??' && echo "OK: unrelated file left alone"
echo "--- update commit staged only workflow.md ---"
LATEST_SHA=$(git log -1 --format=%H --grep='conductor(setup): Update workflow.md to')
git show --stat --format= "$LATEST_SHA" | grep -v '^$'
```

Expected: `OK: update applied`; `OK: unrelated file left alone`; the
`git show --stat` output lists exactly one file, `conductor/workflow.md`
— confirming the unrelated dirty file was never swept into the commit.

- [ ] **Step 7: Scenario F — `/status` staleness nudge, both states**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt)
cd /Users/dt105/git/playground/conductor2

echo "=== stale case (reuse fixture C, still stale from Step 4) ==="
FIXTURE_C=$(ls -d /tmp/conductor-update-fixtureC.* | head -1)
HOME="$FAKE_HOME" opencode run --command status "" --format json --dir "$FIXTURE_C" > /tmp/update_scenarioF_stale.json 2>&1
grep -iE "Workflow doctrine: stale" /tmp/update_scenarioF_stale.json && echo "OK: stale line present" || echo "FAIL: stale line missing"

echo "=== up-to-date case (reuse fixture A, still matching from Step 2) ==="
FIXTURE_A=$(ls -d /tmp/conductor-update-fixtureA.* | head -1)
HOME="$FAKE_HOME" opencode run --command status "" --format json --dir "$FIXTURE_A" > /tmp/update_scenarioF_current.json 2>&1
grep -iE "Workflow doctrine: up to date" /tmp/update_scenarioF_current.json && echo "OK: up-to-date line present" || echo "FAIL: up-to-date line missing"
```

Expected: `OK: stale line present` for fixture C; `OK: up-to-date line
present` for fixture A.

- [ ] **Step 8: Confirm `/revert`'s source text needed no change (spec §5)**

This is a documentation-only check — no fixture run needed, since the
claim being verified is "no source text changed," not a runtime
behavior:

```bash
cd /Users/dt105/git/playground/conductor2
git diff --stat HEAD~5 -- .opencode/command/revert.md .opencode/command/implement.md .opencode/command/new-track.md .opencode/command/review.md
```

Expected: no output (zero lines changed in any of these four files
across this plan's commits so far) — confirms the update commit is
handled by `/revert`'s existing generic mechanism with no special-casing
added anywhere.

- [ ] **Step 9: Clean up all fixtures and the fake home**

```bash
FAKE_HOME=$(cat /tmp/update_fakehome_path.txt 2>/dev/null)
[ -n "$FAKE_HOME" ] && rm -rf "$FAKE_HOME"
for d in /tmp/conductor-update-fixtureA.* /tmp/conductor-update-fixtureB.* /tmp/conductor-update-fixtureC.* /tmp/conductor-update-fixtureD.* /tmp/conductor-update-fixtureE.*; do
  rm -rf "$d"
done
rm -f /tmp/update_fakehome_path.txt /tmp/update_installed_sha.txt /tmp/update_scenario*.json
echo "cleanup done"
```

No commit for this task (no source files were changed).

---

## Self-Review Notes (completed during plan authoring)

- **Spec coverage:** §1 (extract template) → Task 1. §2 (version-stamp)
  → Task 2. §3 (`/update` command, all four numbered behaviors: report
  match, diff+confirm on mismatch, decline path, no clean-tree
  precondition) → Task 3's command doc + Task 6 Scenarios A-E. §4
  (`/status` nudge) → Task 4 + Task 6 Scenario F. §5 (`/revert`
  unaffected) → Task 6 Step 8 (explicit no-source-change verification).
  Interfaces/cross-file impact list → Tasks 1-5 map one-to-one onto the
  spec's five listed files (`workflow-template.md`, `setup.md`,
  `install.sh`, `update.md`, `status.md`, `revert.md` [no-op],
  `README.md`). Testing approach (Layer 1/2) → each task's static
  verification (Layer 1) + Task 6 (Layer 2, covering all six rows of the
  spec's behavioral test table, including the missing-marker and
  unrelated-dirty-tree edge cases). Non-goals (no style-guide sync, no
  passive checks elsewhere, no index.md sync, no workflow.md
  customization) → none introduced anywhere in Tasks 1-5, confirmed by
  each task's grep-based verification only ever touching the files
  listed in Global Constraints.
- **Placeholder scan:** none found; every step has concrete before/after
  text, real bash commands, and real fixture content — no "TBD"/"add
  appropriate handling" language.
- **Type/format consistency:** the marker string
  `<!-- conductor-workflow-version: <sha> -->` and the commit message
  `conductor(setup): Update workflow.md to <sha>` are copied
  character-for-character identically across the spec, Global
  Constraints, Task 2's `install.sh` replacement, Task 3's `update.md`
  content, Task 4's `status.md` replacement, and every fixture/grep in
  Task 6 — confirmed no drift (e.g. no accidental `conductor-workflow-ver`
  truncation or reversed commit-message word order). Variable naming in
  Task 2's `install.sh` diff (`styleguides_dir` replacing `assets_dir`)
  is used consistently within that same task's replacement block, with
  no lingering reference to the old name.
</content>
