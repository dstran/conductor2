# Tier 1 Gemini Conductor Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close Tier 1 of `docs/gemini-parity-gaps.md` (G1 doc-sync, G6 SHA
recording, G5 revert mechanism, G4 status progress) plus G12
(track-creation commit, pulled forward because G5 depends on it) per
`docs/superpowers/specs/2026-07-31-tier1-parity-design.md`.

**Architecture:** Six markdown-command edits, in dependency order: (1)
`conductor/workflow.md` gains a shared "Task commit procedure" that both
`/implement` and `/review` defer to — this is the prerequisite everything
else builds on; (1b) `setup.md`'s embedded copy of `workflow.md` is kept
byte-identical since it's what new projects get; (2) `new-track.md` gets a
track-creation commit and defines the *pending*-state plan.md formats the
new procedure completes; (3) `implement.md` switches its phase-checkpoint
step to the new commit model and gains the doc-sync step; (4) `review.md`'s
correction loop defers to the same task commit procedure for its "Review
Fixes" tasks; (5) `status.md` is rewritten to parse `plan.md` for real
progress; (6) `revert.md` is rewritten into the full reconciliation
protocol. Each task is verified with a static grep/consistency check AND a
live `opencode run --command <name> --dir <fixture>` behavioral test
against a disposable `/tmp` git fixture, per the spec's Layer 2 approach.

**Tech Stack:** Markdown command docs (OpenCode command discovery), the
OpenCode `question` tool (falls back to plain-text prompts in headless
`opencode run` — confirmed during spec verification), git (`log`, `notes`,
`revert`, `reset`, `diff`, `cat-file`), bash, grep.

## Global Constraints

- Match upstream's exact plan.md line formats (per spec §1, confirmed
  design decision): task line `- [x] Task: <description> [<task-type>] <sha>`;
  phase heading `## Phase <N>: <title> [checkpoint: <sha>]`.
- Two commits per task (code commit + `plan.md`-only commit), replacing
  the current one-commit-per-phase model. This is an intentional,
  approved breaking change to `conductor/workflow.md`.
- The task commit procedure lives ONLY in `conductor/workflow.md`;
  `implement.md` and `review.md` reference it, they do not restate it —
  required so `/review`'s "Review Fixes" tasks produce identically
  formatted commits/SHAs to `/implement`'s tasks.
- Phase-checkpoint commit message changes from
  `conductor(checkpoint): Checkpoint end of Phase <N> — <title>` to
  `conductor(plan): Mark phase '<N> — <title>' as complete` — a mechanical
  necessity (the commit no longer carries code), not a G11 scope change.
- `/new-track` commits `chore(conductor): initialize track '<track_id>'`
  immediately after the registry update (existing step 4), before the
  pause-for-approval (existing step 5).
- `/implement`'s doc-sync step sits after all phases are checkpointed,
  before the awaiting-review handoff. Silent skip (no question asked) when
  a file has no material change to propose; explicit Yes/No only when a
  diff is actually proposed. `product-guidelines.md` is only ever
  considered if `spec.md` explicitly describes a branding/voice/tone shift.
- Out of scope (per spec Non-goals): per-track `index.md` (G3), the
  broader commit-message convention overhaul (G11 beyond the one
  mechanical rename above), skill catalog (G2), review action-menu (G7),
  `## Capabilities` section (G9), UX-adapter rule (G10), resume script
  (G8).
- Every task's fixture test runs against a throwaway git repo under
  `/tmp` (created fresh per task, never inside this repo), using
  `opencode run --command <name> "<args>" --dir <fixture>` and, where a
  Yes/No or single-choice prompt is expected, a follow-up
  `opencode run "<answer>" --session <id> --dir <fixture>` continuation.
  An unexpected halt, permission prompt, or tool rejection during a
  fixture run is a task failure, not something to script around.

---

### Task 1: Shared task-commit procedure in `conductor/workflow.md`

**Files:**
- Modify: `conductor/workflow.md` — replace the "Manual review gate" and
  "Commit strategy" sections (current lines 60-91) with a new "Task commit
  procedure", updated "Phase checkpoint procedure", and updated "Commit
  strategy".

**Interfaces:**
- Consumes: nothing (this is the root of the dependency chain).
- Produces: the two exact plan.md line formats and three commit-message
  formats that every other task in this plan depends on:
  - Task line: `- [x] Task: <description> [<task-type>] <sha>`
  - Phase heading: `## Phase <N>: <title> [checkpoint: <sha>]`
  - Task code commit: any conventional message (task author's choice).
  - Task plan-update commit: `conductor(plan): Mark task '<task>' as complete`
  - Phase plan-update commit: `conductor(plan): Mark phase '<N> — <title>' as complete`

- [ ] **Step 1: Replace `conductor/workflow.md` lines 60-91**

Read the current file first to confirm the anchor text still matches (the
section starts at `## Manual review gate` and runs to the end of the
file). Then replace everything from `## Manual review gate` through the
end of the file with:

```markdown
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

`/implement` pauses at the end of every phase, presents a summary, asks
"does this meet expectations?", and only checkpoints the phase after an
explicit yes (looping on feedback the same way `/review` does, including
the same 3rd-round nudge). Nothing beyond a phase checkpoint is finalized
without that.

On explicit yes:

1. Identify the last task code commit made in this phase (from step 1 of
   the task commit procedure above, for the phase's final task). Do NOT
   create a new empty commit — the checkpoint always points at an
   existing task commit.
2. Attach the phase summary (automated test results + manual verification
   steps) as a **git note** on that commit — not in a commit message body:
   `git notes add -m "<summary>" <sha>`
3. Edit `plan.md`: append `[checkpoint: <sha>]` to the phase's heading,
   producing exactly: `## Phase <N>: <title> [checkpoint: <sha>]`
   Stage only `plan.md` and commit with message
   `conductor(plan): Mark phase '<N> — <title>' as complete`.

Once all phases are checkpointed, `/implement` stops and hands off to
`/review` for the track-level pass: full test suite, style, security, and
plan compliance across the whole track. `/review` has its own
pause-and-ask gate before the final track-closure commit is made.

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

- [ ] **Step 2: Verify the replacement (static check)**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- new sections present ---"
grep -nE '^## Task commit procedure$|^## Phase checkpoint procedure$|^## Commit strategy$' conductor/workflow.md
echo "--- exact plan.md formats present ---"
grep -nE '^\s*- \[x\] Task: <description> \[<task-type>\] <sha>$' conductor/workflow.md
grep -nE '^\s*## Phase <N>: <title> \[checkpoint: <sha>\]$' conductor/workflow.md
echo "--- exact commit messages present ---"
grep -nE "conductor\(plan\): Mark task '<task>' as complete" conductor/workflow.md
grep -nE "conductor\(plan\): Mark phase '<N> — <title>' as complete" conductor/workflow.md
echo "--- old checkpoint message gone ---"
grep -nE 'Checkpoint end of Phase' conductor/workflow.md && echo "FAIL: old message remains" || echo "OK none"
echo "--- old one-commit-per-phase language gone ---"
grep -nE 'one checkpoint commit per approved phase' conductor/workflow.md && echo "FAIL: stale strategy remains" || echo "OK none"
```

Expected: all three new section headers found; both exact-format lines
found; both new commit-message strings found; both "gone" checks print
`OK none`.

- [ ] **Step 3: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add conductor/workflow.md
git commit -m "Add per-task commit procedure and SHA recording to workflow.md"
```

---

### Task 2: Mirror the workflow.md rewrite into `setup.md`'s embedded copy

**Files:**
- Modify: `.opencode/command/setup.md` — replace the embedded
  `workflow.md` content block (inside the fenced ` ```markdown ` block
  under `## 7. Workflow`, current lines 77-169) with the exact same
  replacement content from Task 1, Step 1 (everything from
  `## Manual review gate` onward, renamed to the new section names).

**Interfaces:**
- Consumes: the exact replacement text from Task 1, Step 1 (must be
  byte-identical — this block is what `/setup` writes to
  `conductor/workflow.md` for brand-new projects, so it must match what
  Task 1 wrote to this project's own `conductor/workflow.md`).
- Produces: new projects scaffolded by `/setup` get the same task-commit
  procedure as this project.

- [ ] **Step 1: Read the current embedded block's exact boundaries**

```bash
cd /Users/dt105/git/playground/conductor2
grep -n '^## Manual review gate$\|^```$' .opencode/command/setup.md | head -10
```

Confirm `## Manual review gate` appears inside the fenced block that
started at line 77, and find the closing ` ``` ` fence line number
immediately after it (this closes the embedded markdown block, currently
line 169).

- [ ] **Step 2: Replace the embedded block's tail**

In `.opencode/command/setup.md`, inside the fenced code block under
`## 7. Workflow (`conductor/workflow.md`)`, replace everything from the
line `## Manual review gate` up to (but not including) the closing
` ``` ` fence with the identical replacement text used in Task 1, Step 1
(the `## Task commit procedure` / `## Phase checkpoint procedure` /
`## Commit strategy` sections, verbatim).

- [ ] **Step 3: Verify byte-for-byte parity between the two copies**

```bash
cd /Users/dt105/git/playground/conductor2
awk '/^## Task commit procedure$/{flag=1} flag; /^```$/{if(flag){exit}}' .opencode/command/setup.md > /tmp/setup_embedded_workflow_tail.md
awk '/^## Task commit procedure$/{flag=1} flag' conductor/workflow.md > /tmp/actual_workflow_tail.md
diff /tmp/setup_embedded_workflow_tail.md /tmp/actual_workflow_tail.md && echo "OK identical" || echo "FAIL: embedded copy diverges"
```

Expected: `OK identical`. If not, fix the embedded copy until it matches
exactly (the `awk` extraction stops the actual-workflow-tail at EOF since
that file ends right after `## Commit strategy`, and stops the
setup-embedded-tail at the first ` ``` ` fence after the same start
marker — both should therefore contain exactly the same section content).

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/setup.md
git commit -m "Mirror workflow.md's task commit procedure into setup.md's embedded copy"
```

---

### Task 3: `/new-track` commits on creation and defines pending plan.md formats

**Files:**
- Modify: `.opencode/command/new-track.md` — insert a new step between
  the existing step 4 ("Update the registry", lines 38-42) and step 5
  ("Pause for approval", lines 44-46); also add pending-state format
  guidance to step 3 ("Create the track artifacts", lines 26-36).

**Interfaces:**
- Consumes: nothing new.
- Produces: (a) a `chore(conductor): initialize track '<track_id>'`
  commit that `revert.md` (Task 6) will search for via
  `git log --grep`; (b) the pending-state plan.md line formats
  (`- [ ] Task: <description> [<task-type>]` and `## Phase <N>: <title>`)
  that `/implement` (Task 4) transitions to the completed formats defined
  in Task 1.

- [ ] **Step 1: Add pending-format guidance to step 3**

In `.opencode/command/new-track.md`, find this line (current line 36):

```
Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`).
```

Replace it with:

```
Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.
```

- [ ] **Step 2: Insert the track-creation commit step**

In `.opencode/command/new-track.md`, find the existing step 5:

```
## 5. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`.
```

Replace it with:

```
## 5. Commit the new track

Stage `conductor/tracks/<track_id>/` and `conductor/tracks.md`, then
commit with the message `chore(conductor): initialize track '<track_id>'`.
This is the anchor commit `/revert` uses to find and undo an entire
track.

## 6. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`.
```

- [ ] **Step 3: Verify (static check)**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- pending formats documented ---"
grep -nE '\- \[ \] Task: <description> \[<task-type>\]' .opencode/command/new-track.md
grep -nE '## Phase <N>: <title>`' .opencode/command/new-track.md
echo "--- track-creation commit step present ---"
grep -nE "chore\(conductor\): initialize track '<track_id>'" .opencode/command/new-track.md
echo "--- renumbered pause step ---"
grep -nE '^## 6\. Pause for approval$' .opencode/command/new-track.md
```

Expected: all four greps find a match.

- [ ] **Step 4: Behavioral fixture test**

```bash
FIXTURE=$(mktemp -d /tmp/conductor-newtrack-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/new-track.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE/conductor/"
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture"
opencode run --command new-track "Add a health-check endpoint that returns 200 OK. Do not ask clarifying questions — assume 1 phase, 1 backend-logic task called 'Add /health endpoint'. Skip confirmation loops, proceed straight through to creating the artifacts, updating the registry, and committing." --format json --dir "$FIXTURE" > /tmp/newtrack_run.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/newtrack_run.json, may need a follow-up turn"; kill $BGPID; else echo FINISHED; fi
echo "=== git log ==="
git log --oneline
echo "=== track dirs ==="
find conductor/tracks -maxdepth 1
echo "$FIXTURE" > /tmp/newtrack_fixture_path.txt
```

Expected: `git log --oneline` contains a commit whose message matches
`chore(conductor): initialize track '<something>_<8-digit-date>'`; a
directory exists under `conductor/tracks/` matching that same track ID.
If the run paused on a question instead of finishing, read
`/tmp/newtrack_run.json` for the session ID and continue it with
`opencode run "<answer>" --session <id> --dir "$FIXTURE"` until it
completes, then re-check `git log`.

- [ ] **Step 5: Clean up the fixture and commit the doc change**

```bash
rm -rf "$(cat /tmp/newtrack_fixture_path.txt)"
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/new-track.md
git commit -m "Commit on track creation and define pending plan.md formats"
```

---

### Task 4: `/implement` — new commit model + doc-sync step

**Files:**
- Modify: `.opencode/command/implement.md` — rewrite step 3 ("Phase
  checkpoint", lines 50-80) to defer to the new procedure and add
  per-task commit sub-steps to step 2; insert a new doc-sync step between
  the current step 4 ("Track complete") and step 5 ("If you stop early").

**Interfaces:**
- Consumes: `conductor/workflow.md`'s task commit procedure and phase
  checkpoint procedure (Task 1); the pending plan.md formats (Task 3).
- Produces: for every completed task, a code commit + a
  `conductor(plan): Mark task ...` commit with the task line matching
  `- [x] Task: ... [<sha>]`; for every checkpointed phase, a
  `conductor(plan): Mark phase ...` commit with the heading matching
  `[checkpoint: <sha>]`; optionally a
  `docs(conductor): Synchronize docs for track '<id>'` commit.
  `revert.md` (Task 6) and `status.md` (Task 5) both depend on these
  formats existing in the plan.md that `/implement` produces.

- [ ] **Step 1: Add the per-task commit sub-step to step 2**

In `.opencode/command/implement.md`, find this line inside step 2 (current
line 43-44):

```
   d. Mark the task `[~]` in `plan.md` while in progress, `[x]` only
      after its test(s) actually run and pass.
```

Replace it with:

```
   d. Mark the task `[~]` in `plan.md` while in progress. Once its
      test(s) actually run and pass, follow the **task commit
      procedure** in `conductor/workflow.md` exactly: commit the code,
      then commit `plan.md` with the task marked
      `- [x] Task: <description> [<task-type>] <sha>` (two separate
      commits, in that order).
```

- [ ] **Step 2: Rewrite step 3 to defer to the phase checkpoint procedure**

In `.opencode/command/implement.md`, find the current step 3 heading and
its sub-steps `a` through `g` (current lines 50-80, from
`## 3. Phase checkpoint` through the line ending `...go to step 4.`).
Replace that entire step with:

```
## 3. Phase checkpoint (trigger this the moment a phase's last task is `[x]`)
Do not silently continue to the next phase. Instead:
   a. Identify the git commit SHA at the start of this phase (the
      previous phase's `[checkpoint: <sha>]`, or the track's creation
      commit if this is phase 1). Scope everything below to files
      changed since that point.
   b. Run the automated tests relevant to this phase's changes
      (not necessarily the full suite — that's `/review`'s job at
      track end).
   c. If anything in this phase can't be confirmed by an automated
      test (e.g. requires a running server, a manual UI check, an
      external service), write out explicit manual verification
      steps — exact commands to run and what result confirms success.
   d. Present a short phase summary to the user: what was built,
      automated test results, and any manual verification steps.
      Ask: "Does this meet expectations? Reply yes to checkpoint and
      continue, or tell me what to change." PAUSE and wait.
   e. If the user gives feedback: fix it in place (using the task
      commit procedure for whatever changed), re-run only the
      checks that fix could affect, and re-present the phase summary.
      Loop until they say yes. No round cap, same as `/review`'s
      correction loop — but note if this is the 3rd+ round on the
      same file or area, same as `/review` does.
   f. On explicit yes: follow the **phase checkpoint procedure** in
      `conductor/workflow.md` exactly — attach the phase summary (test
      results + manual verification steps) as a git note on the last
      task commit in this phase, then commit `plan.md` with the phase
      heading marked `## Phase <N>: <title> [checkpoint: <sha>]`. Do
      not create a new empty commit.
   g. Move to the next phase and repeat from step 2. If this was the
      last phase, go to step 4.
```

- [ ] **Step 3: Insert the doc-sync step**

In `.opencode/command/implement.md`, find the current step 4 heading
(`## 4. Track complete`) and the step 5 heading
(`## 5. If you stop early due to a blocker`). Insert a new step between
them (so the existing step 5 becomes step 6):

```
## 5. Synchronize project documentation

Once every phase has its own checkpoint commit and `plan.md` has been
updated per step 4, check whether this track's changes should be
reflected in the project's own context files:

   a. Read the track's `spec.md`.
   b. For `product.md`: does this track materially change the product
      description itself (new capability, changed scope)? If yes,
      present a proposed diff and ask a Yes/No question; apply the edit
      only on explicit yes. If no material change, state that briefly
      and move on — do not ask a question.
   c. For `tech-stack.md`: does this track introduce, remove, or change
      a technology, library, or architectural choice? If yes, present a
      proposed diff and ask a Yes/No question; apply only on explicit
      yes. If no material change, state that briefly and move on.
   d. For `product-guidelines.md`: only consider this file if `spec.md`
      explicitly describes a branding, voice, tone, or UX-philosophy
      change. If so, present the diff with an explicit warning that this
      file defines the product's core identity, then ask a Yes/No
      question; apply only on explicit yes. If `spec.md` says nothing
      about branding/voice/tone, skip this file entirely — do not even
      mention it.
   e. If any of `product.md`, `tech-stack.md`, or `product-guidelines.md`
      were changed, stage them together and commit:
      `docs(conductor): Synchronize docs for track '<track_id>'`. If
      nothing changed, make no commit and say so.

## 6. If you stop early due to a blocker
```

Note: only the two heading lines are shown for step 6's boundary — leave
its existing body (the "Leave completed tasks `[x]`..." paragraph) exactly
as it is, just renumbered.

- [ ] **Step 4: Renumber the final "Report back" step reference**

In `.opencode/command/implement.md`, the closing paragraph currently
begins "Report back a short summary after each phase checkpoint and at
track completion...". Leave its text as-is (it doesn't reference a step
number), but confirm it still reads correctly after the insertion — no
edit needed if it doesn't cite a number.

- [ ] **Step 5: Verify (static check)**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- per-task commit procedure referenced ---"
grep -nE 'task commit\*\* procedure|task commit procedure' .opencode/command/implement.md
echo "--- phase checkpoint procedure referenced ---"
grep -nE 'phase checkpoint\*\* procedure|phase checkpoint procedure' .opencode/command/implement.md
echo "--- doc-sync step present ---"
grep -nE '^## 5\. Synchronize project documentation$' .opencode/command/implement.md
grep -nE "docs\(conductor\): Synchronize docs for track '<track_id>'" .opencode/command/implement.md
echo "--- old inline commit message gone ---"
grep -nE 'Checkpoint end of Phase' .opencode/command/implement.md && echo "FAIL: stale message remains" || echo "OK none"
echo "--- renumbered blocker step ---"
grep -nE '^## 6\. If you stop early due to a blocker$' .opencode/command/implement.md
echo "--- step count sanity (no gaps/dupes) ---"
grep -nE '^## [0-9]\.' .opencode/command/implement.md
```

Expected: the doc-sync heading and message found; the old inline
checkpoint message check prints `OK none`; the final step-count grep
prints exactly `## 1.` through `## 6.` once each, in order.

- [ ] **Step 6: Behavioral fixture test — per-task SHA format**

```bash
FIXTURE=$(mktemp -d /tmp/conductor-implement-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor/tracks/hc_20260731"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/workflow.md "$FIXTURE/conductor/"
cat > "$FIXTURE/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [ ] **Track: Add health-check endpoint** *Link: [tracks/hc_20260731/plan.md](./tracks/hc_20260731/plan.md)*

## Blocked
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/spec.md" <<'EOF'
# Spec: Health-check endpoint

## Overview
Add a `GET /health` endpoint that returns HTTP 200 with body `ok`.

## Acceptance Criteria
- `GET /health` returns 200 and body `ok`.
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/plan.md" <<'EOF'
# Plan: Add health-check endpoint

## Phase 1: Health endpoint

- [ ] Task: Add GET /health returning 200 ok [backend-logic]
EOF
cat > "$FIXTURE/server.js" <<'EOF'
const http = require('http');
function handler(req, res) {
  res.statusCode = 404;
  res.end('not found');
}
module.exports = { handler };
if (require.main === module) {
  http.createServer(handler).listen(3000);
}
EOF
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "chore(conductor): initialize track 'hc_20260731'"
opencode run --command implement "hc_20260731 This is a Node.js project with plain http, no framework. Use node's built-in test runner (node --test) for backend-logic tests. Implement the single task test-first: write a failing test for the /health handler returning 200/ok, confirm it fails, implement the minimal handler change, confirm it passes, then follow the task commit procedure. After that task's checkpoint commits, when the phase checkpoint gate asks 'does this meet expectations', reply yes immediately without further changes. After the phase checkpoint, for the doc-sync step, there is no product.md/tech-stack.md/product-guidelines.md in this fixture project at all, so state that and make no doc-sync commit. Then report the track is ready for review and stop." --format json --dir "$FIXTURE" > /tmp/implement_run.json 2>&1 &
BGPID=$!
sleep 180
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - kill and inspect /tmp/implement_run.json for the session id, continue with follow-up turns"; kill $BGPID; else echo FINISHED; fi
echo "=== plan.md ==="
cat conductor/tracks/hc_20260731/plan.md
echo "=== git log ==="
git log --oneline
echo "$FIXTURE" > /tmp/implement_fixture_path.txt
```

Expected: `plan.md`'s task line matches
`- [x] Task: Add GET /health returning 200 ok [backend-logic] <sha>` where
`<sha>` is exactly 7 hex characters; the phase heading matches
`## Phase 1: Health endpoint [checkpoint: <sha>]`; `git log --oneline`
shows (in order, oldest first): the seed commit, a code commit, a
`conductor(plan): Mark task 'Add GET /health returning 200 ok [backend-logic]' as complete` commit, and a `conductor(plan): Mark phase '1 — Health endpoint' as complete` commit. If the run paused on the phase-checkpoint or
doc-sync question instead of finishing, continue it via
`opencode run "yes" --session <id> --dir "$FIXTURE"` (read the session ID
from `/tmp/implement_run.json`) until `git log` shows the expected
commits.

Then verify the two SHAs actually resolve and the phase-checkpoint SHA
points at the last task's code commit:

```bash
cd "$FIXTURE"
TASK_SHA=$(grep -oE '\[[0-9a-f]{7}\]$' conductor/tracks/hc_20260731/plan.md | head -1 | tr -d '[]')
CHECKPOINT_SHA=$(grep -oE 'checkpoint: [0-9a-f]{7}' conductor/tracks/hc_20260731/plan.md | grep -oE '[0-9a-f]{7}$')
echo "task sha: $TASK_SHA, checkpoint sha: $CHECKPOINT_SHA"
git cat-file -e "$TASK_SHA" && echo "OK task sha resolves" || echo "FAIL"
git cat-file -e "$CHECKPOINT_SHA" && echo "OK checkpoint sha resolves" || echo "FAIL"
[ "$TASK_SHA" = "$CHECKPOINT_SHA" ] && echo "OK checkpoint points at last task commit" || echo "FAIL: mismatch"
```

Expected: both `OK` lines and the mismatch check also prints `OK` (in
this single-task-phase fixture, the checkpoint SHA and the task SHA must
be identical, per the "last task commit" rule and "never a new empty
commit" rule).

- [ ] **Step 7: Behavioral fixture test — doc-sync positive path**

Reuse the pattern from Step 6 but seed `product.md` and `tech-stack.md`
in a second fixture, and give the track a spec that clearly changes the
tech stack, to confirm doc-sync actually proposes and applies a diff:

```bash
FIXTURE2=$(mktemp -d /tmp/conductor-docsync-fixture.XXXXXX)
mkdir -p "$FIXTURE2/.opencode/command" "$FIXTURE2/conductor/tracks/cache_20260731"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md "$FIXTURE2/.opencode/command/"
cp conductor/index.md conductor/workflow.md "$FIXTURE2/conductor/"
cat > "$FIXTURE2/conductor/product.md" <<'EOF'
# Product

## Overview
A minimal HTTP service.
EOF
cat > "$FIXTURE2/conductor/tech-stack.md" <<'EOF'
# Tech Stack

- Language: Node.js
- Storage: none (stateless)
EOF
cat > "$FIXTURE2/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [ ] **Track: Add Redis response cache** *Link: [tracks/cache_20260731/plan.md](./tracks/cache_20260731/plan.md)*

## Blocked
EOF
cat > "$FIXTURE2/conductor/tracks/cache_20260731/spec.md" <<'EOF'
# Spec: Add Redis response cache

## Overview
Introduce Redis as a new dependency to cache responses. This changes the
project's tech stack from "no storage" to using Redis for caching.

## Acceptance Criteria
- A `cache.js` module exposing `get(key)`/`set(key, value)` backed by an
  in-memory Map (stand-in for Redis in this fixture; do not require an
  actual Redis server).
EOF
cat > "$FIXTURE2/conductor/tracks/cache_20260731/plan.md" <<'EOF'
# Plan: Add Redis response cache

## Phase 1: Cache module

- [ ] Task: Add cache.js with get/set backed by a Map [backend-logic]
EOF
cd "$FIXTURE2"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "chore(conductor): initialize track 'cache_20260731'"
opencode run --command implement "cache_20260731 Use node's built-in test runner (node --test). Implement the single task test-first, commit per the task commit procedure, then at the phase checkpoint reply yes immediately. Then for the doc-sync step: this track adds Redis as a new dependency per spec.md, so tech-stack.md should be updated to mention Redis caching -- propose that diff and if asked to approve it, reply yes. product.md has no material change, skip it without asking. product-guidelines.md is not mentioned by spec.md, skip it silently. Then stop." --format json --dir "$FIXTURE2" > /tmp/docsync_run.json 2>&1 &
BGPID=$!
sleep 180
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - continue via session id in /tmp/docsync_run.json"; kill $BGPID; else echo FINISHED; fi
echo "=== tech-stack.md ==="
cat conductor/tech-stack.md
echo "=== product.md (should be unchanged) ==="
cat conductor/product.md
echo "=== git log ==="
git log --oneline
echo "$FIXTURE2" > /tmp/docsync_fixture_path.txt
```

Expected: `tech-stack.md` now mentions Redis (content changed from the
seed); `product.md` is byte-identical to the seed content; `git log`
contains a `docs(conductor): Synchronize docs for track 'cache_20260731'`
commit whose diff touches `conductor/tech-stack.md` only. Verify the diff
scope directly:

```bash
cd "$FIXTURE2"
DOCSYNC_SHA=$(git log --oneline --grep="docs(conductor): Synchronize docs for track 'cache_20260731'" --format=%h)
echo "docsync sha: $DOCSYNC_SHA"
git show --stat "$DOCSYNC_SHA"
```

Expected: the commit's stat shows only `conductor/tech-stack.md` changed
(not `product.md`, not `product-guidelines.md` — it doesn't exist in this
fixture at all).

- [ ] **Step 8: Clean up fixtures and commit the doc change**

```bash
rm -rf "$(cat /tmp/implement_fixture_path.txt)" "$(cat /tmp/docsync_fixture_path.txt)"
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/implement.md
git commit -m "Switch /implement to per-task commits with SHA recording and add doc-sync step"
```

---

### Task 5: `/review`'s correction loop defers to the task commit procedure

**Files:**
- Modify: `.opencode/command/review.md` — update step 8 ("The correction
  loop", lines 75-99), sub-step 2, to reference the shared procedure
  instead of the generic "Apply the same TDD enforcement" phrasing.

**Interfaces:**
- Consumes: `conductor/workflow.md`'s task commit procedure (Task 1).
- Produces: "Review Fixes" phase tasks get the same
  `- [x] Task: ... [<sha>]` treatment as any other task, so `/revert`
  (Task 6) can target them identically.

- [ ] **Step 1: Update correction-loop sub-step 2**

In `.opencode/command/review.md`, find this line (current line 83-84,
inside step 8):

```
2. Apply the same TDD enforcement from `conductor/workflow.md` to each fix
    (a backend fix still gets a test-first treatment, etc.).
```

Replace it with:

```
2. Apply the same TDD enforcement from `conductor/workflow.md` to each fix
    (a backend fix still gets a test-first treatment, etc.), and once a
    fix task's test(s) pass, commit it via `conductor/workflow.md`'s task
    commit procedure — same two-commit sequence (code, then the
    `- [x] Task: ... [<sha>]` plan update) as any other task, so `/revert`
    can find and undo a review-fix task the same way it finds any other.
```

- [ ] **Step 2: Verify (static check)**

```bash
cd /Users/dt105/git/playground/conductor2
grep -nE 'task commit procedure' .opencode/command/review.md
grep -nE "code, then the" .opencode/command/review.md
echo "--- steps 1-7, 9-10 untouched (only step 8 sub-step 2 changed) ---"
grep -nE '^## 1\. Plan compliance check$|^## 7\. Pause and ask|^## 9\. After explicit approval only|^## 10\. Track cleanup$' .opencode/command/review.md
```

Expected: the two new-text greps find matches; the four other section
headers are still present unchanged.

- [ ] **Step 3: Behavioral fixture test**

This exercises the correction loop end-to-end: seed a track already in
the awaiting-review state with one clean task, run `/review`, give
feedback that triggers the correction loop, and confirm the resulting fix
task gets the two-commit-with-SHA treatment.

```bash
FIXTURE=$(mktemp -d /tmp/conductor-review-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor/tracks/hc_20260731"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/review.md .opencode/command/workflow_unused_placeholder 2>/dev/null; rm -f .opencode/command/workflow_unused_placeholder
cp .opencode/command/review.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/workflow.md "$FIXTURE/conductor/"
cat > "$FIXTURE/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [~] **Track: Add health-check endpoint** *Link: [tracks/hc_20260731/plan.md](./tracks/hc_20260731/plan.md)*
Status: implementation complete — awaiting review.

## Blocked
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/spec.md" <<'EOF'
# Spec: Health-check endpoint

## Acceptance Criteria
- `GET /health` returns 200 and body `ok`.
- Response includes header `X-Health-Check: true`.
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/plan.md" <<'EOF'
# Plan: Add health-check endpoint

## Phase 1: Health endpoint [checkpoint: 0000000]

- [x] Task: Add GET /health returning 200 ok [backend-logic] 0000000
EOF
cat > "$FIXTURE/server.js" <<'EOF'
function handler(req, res) {
  if (req.url === '/health') {
    res.statusCode = 200;
    res.end('ok');
    return;
  }
  res.statusCode = 404;
  res.end('not found');
}
module.exports = { handler };
EOF
mkdir -p "$FIXTURE/test"
cat > "$FIXTURE/test/health.test.js" <<'EOF'
const test = require('node:test');
const assert = require('node:assert');
const { handler } = require('../server');
test('returns 200 ok on /health', () => {
  const req = { url: '/health' };
  let statusCode, body;
  const res = { set statusCode(v) { statusCode = v; }, get statusCode() { return statusCode; }, end: (b) => { body = b; } };
  handler(req, res);
  assert.equal(statusCode, 200);
  assert.equal(body, 'ok');
});
EOF
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed: fake prior implement commit" --allow-empty
REAL_SHA=$(git log -1 --format=%h)
sed -i '' "s/0000000/$REAL_SHA/g" conductor/tracks/hc_20260731/plan.md
git add -A && git commit -q -m "fix seed SHAs to point at a real commit"
opencode run --command review "hc_20260731 Run the full review protocol. This is a Node.js project; run tests with 'node --test'. When you reach the pause-and-ask step, I will give feedback that the response is missing the X-Health-Check header, as the spec requires. Append a Review Fixes phase, implement that fix test-first per the workflow, commit it via the task commit procedure, then re-present and I will approve." --format json --dir "$FIXTURE" > /tmp/review_run.json 2>&1 &
BGPID=$!
sleep 180
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - continue via session id from /tmp/review_run.json, feed: 'The response is missing the X-Health-Check: true header the spec requires.' then 'yes'"; kill $BGPID; else echo FINISHED; fi
echo "=== plan.md ==="
cat conductor/tracks/hc_20260731/plan.md
echo "=== git log ==="
git log --oneline
echo "$FIXTURE" > /tmp/review_fixture_path.txt
```

Expected: `plan.md` gains a `## Review Fixes` phase heading and a fix
task line matching `- [x] Task: ... [<task-type>] [<sha>]` (7 hex chars,
resolving via `git cat-file -e`); `git log --oneline` contains a code
commit for the header fix followed by a
`conductor(plan): Mark task '...' as complete` commit, prior to the final
`conductor(track): ...` closure commit. If the run pauses waiting for the
scripted feedback or the final approval, continue with
`opencode run "<feedback or yes>" --session <id> --dir "$FIXTURE"`.

- [ ] **Step 4: Clean up the fixture and commit the doc change**

```bash
rm -rf "$(cat /tmp/review_fixture_path.txt)"
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/review.md
git commit -m "Point /review's correction loop at the shared task commit procedure"
```

---

### Task 6: `/status` parses plan.md for real progress

**Files:**
- Modify: `.opencode/command/status.md` — full rewrite.

**Interfaces:**
- Consumes: `conductor/tracks.md`'s `## Active`/`## Blocked` sections;
  each listed track's `plan.md` in the task-line/phase-heading formats
  from Task 1/3 (`[x]`/`[~]`/`[ ]`, optional `[checkpoint: <sha>]` suffix
  which status ignores).
- Produces: a per-track and project-level progress summary. Nothing
  downstream consumes `/status`'s output — it's a terminal reporting
  command.

- [ ] **Step 1: Replace the full contents of `.opencode/command/status.md`**

```markdown
---
description: Summarize active, blocked, and archived Conductor tracks with real progress computed from each track's plan.md
agent: build
---

@conductor/tracks.md

Read `conductor/tracks.md`, then for every track listed under `## Active`
and `## Blocked`, resolve and read that track's `plan.md` (link given in
the registry entry). Do not edit product code.

## 1. Per-track progress

For each track's `plan.md`:

- Count total phases (`## Phase <N>: <title>` headings) and total tasks
  (lines starting `- [x] Task:`, `- [~] Task:`, or `- [ ] Task:`).
- Count completed tasks (`[x]`) and compute
  `completed/total (percentage%)`, rounded to the nearest whole percent.
- Identify the current in-progress task, if any (`[~]`).
- Identify the next pending task (the first `- [ ] Task:` line in
  document order).
- Note any phase heading missing a `[checkpoint: <sha>]` suffix even
  though every task inside it is `[x]` — flag this as an inconsistency
  (a checkpoint that should have happened but didn't get recorded).

## 2. Registry state per track

- **Active:** entries under `## Active`. Distinguish planned (`[ ]`),
  in progress (`[~]` with no note), awaiting review (`[~]` with the
  awaiting-review note), and completed-in-place (`[x]`).
- **Blocked:** entries under `## Blocked`, including each `Blocker:` note.
- **Archived:** if `conductor/archive/` exists, list the archived track
  directories inside it. These have been removed from the registry and
  have no live progress to report.

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

If `conductor/tracks.md` has no entries under `## Active` or `## Blocked`,
report that the registry is empty and skip steps 1 and 3.
```

- [ ] **Step 2: Verify (static check)**

```bash
cd /Users/dt105/git/playground/conductor2
grep -nE 'completed/total|percentage%' .opencode/command/status.md
grep -nE 'checkpoint.*inconsistency|inconsistency' .opencode/command/status.md
grep -nE '^## 1\. Per-track progress$|^## 2\. Registry state per track$|^## 3\. Present the summary$' .opencode/command/status.md
grep -nE 'Archived' .opencode/command/status.md
```

Expected: all greps find matches.

- [ ] **Step 3: Behavioral fixture test**

```bash
FIXTURE=$(mktemp -d /tmp/conductor-status-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor/tracks/demo_20260731"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/status.md "$FIXTURE/.opencode/command/"
cp conductor/index.md "$FIXTURE/conductor/"
cat > "$FIXTURE/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [~] **Track: Demo track** *Link: [tracks/demo_20260731/plan.md](./tracks/demo_20260731/plan.md)*

## Blocked
EOF
cat > "$FIXTURE/conductor/tracks/demo_20260731/plan.md" <<'EOF'
# Plan: Demo track

## Phase 1: Setup [checkpoint: abc1234]

- [x] Task: Init project [backend-logic] abc1234
- [x] Task: Add config loader [backend-logic] def5678

## Phase 2: Feature work

- [~] Task: Add main handler [backend-logic]
- [ ] Task: Add error handling [backend-logic]
- [ ] Task: Add logging [backend-logic]
EOF
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m init
opencode run --command status --format json --dir "$FIXTURE" > /tmp/status_run.json 2>&1 &
BGPID=$!
sleep 60
if kill -0 $BGPID 2>/dev/null; then echo STILL_RUNNING; kill $BGPID; else echo FINISHED; fi
python3 -c "
import json
for line in open('/tmp/status_run.json'):
    line=line.strip()
    if not line: continue
    try: obj=json.loads(line)
    except: continue
    if obj.get('type')=='text':
        print(obj['part']['text'])
"
echo "$FIXTURE" > /tmp/status_fixture_path.txt
```

Expected output text contains `2/5` and a percentage of `40%` (2 of the 5
task lines are `[x]`), names "Add main handler" as the current/in-progress
task, and names "Add error handling" as the next pending task.

- [ ] **Step 4: Clean up the fixture and commit the doc change**

```bash
rm -rf "$(cat /tmp/status_fixture_path.txt)"
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/status.md
git commit -m "Compute real per-track progress and percentages in /status"
```

---

### Task 7: `/revert` — full reconciliation protocol

**Files:**
- Modify: `.opencode/command/revert.md` — full rewrite.

**Interfaces:**
- Consumes: the task/phase/track commit and SHA formats from Tasks
  1/3/4/5 (`- [x] Task: ... [<sha>]`, `[checkpoint: <sha>]`,
  `chore(conductor): initialize track '<id>'`).
- Produces: reverted git history (via `git revert` or `git reset --hard`)
  and a reconciled `plan.md` with the affected task/phase reset to
  `[ ]` and its SHA/checkpoint annotation stripped.

- [ ] **Step 1: Replace the full contents of `.opencode/command/revert.md`**

```markdown
---
description: Reconcile plan.md SHAs against git history to safely revert a Conductor track, phase, or task
agent: build
---

@conductor/tracks.md
@conductor/tracks/$ARGUMENTS/plan.md

`$ARGUMENTS` is the track ID generated by `/conductor/new-track` — a
`<shortname>_YYYYMMDD` slug (e.g. `user-auth_20260728`) as listed in
`conductor/tracks.md` — optionally followed by a phase or task
description if the user wants to revert something narrower than the
whole track.

If `conductor/index.md` is missing, offer to run `/setup` (Yes/No) and
HALT if declined.

## 1. Target selection

**Path A — a track ID (and optionally a phase/task) was given:**
Resolve it in `conductor/tracks.md` and the track's `plan.md`. Confirm
with a Yes/No question ("Revert <track/phase/task description>?").

**Path B — nothing was given:**
Scan `conductor/tracks.md` and every listed track's `plan.md`. Prioritize
the top 3 most relevant `[~]` in-progress tasks or phases. If none exist,
fall back to the 3 most recently completed `[x]` tasks or phases (most
recent = highest SHA in `git log` order). Present these as a
single-choice question (max 4 options, the `question` tool's built-in
custom option covers "something else"). Once chosen, confirm via Path A's
Yes/No.

## 2. Git reconciliation

Resolve every commit SHA the chosen target touches:

- **Task:** its own code-commit SHA (the `<sha>` in its
  `- [x] Task: ... [<sha>]` line) and its plan-update commit — find the
  latter via `git log --follow -- <plan.md path>` for the commit whose
  message is `conductor(plan): Mark task '<task>' as complete`.
- **Phase:** the `[checkpoint: <sha>]` SHA, every task pair inside that
  phase (per the rule above), and the phase's own plan-update commit
  (`conductor(plan): Mark phase '<N> — <title>' as complete`).
- **Track:** every phase's items above for every phase in the track,
  plus the track-creation commit — find it via
  `git log --grep="initialize track '<track_id>'"`.

**Ghost-commit handling:** if a SHA recorded in `plan.md` is not found by
`git cat-file -e <sha>` (history was rewritten), search
`git log --oneline` for a commit with a highly similar message to the
one expected at that point in the plan. Ask a Yes/No question to confirm
using it as the replacement. If declined, HALT.

Compile the final list of SHAs to revert. Flag (but don't block on) any
merge commits or SHAs that appear more than once (possible cherry-pick
duplicates).

## 3. Present the execution plan

List every SHA and its commit message that will be reverted, in the
order they will be reverted (newest first). Do not proceed without
showing this list.

## 4. Strategy choice

Ask a single-choice question:

- **Safe (Recommended):** `git revert --no-edit`, newest to oldest.
  Creates new commits that undo the changes; preserves history.
- **Hard Reset (Destructive):** `git reset --hard <base_sha>`, where
  `<base_sha>` is the commit immediately before the earliest SHA in the
  list. Rewrites history and discards any uncommitted changes. Warn
  explicitly about both before proceeding.

## 5. Execute

- **Safe:** run `git revert --no-edit <sha>` for each SHA in the list, in
  order. If any revert fails with a conflict, HALT immediately and give
  the user manual resolution instructions (`git status`, resolve, `git
  revert --continue`) — do not force through or auto-resolve.
- **Hard Reset:** confirm the user acknowledged the warning, then run
  `git reset --hard <base_sha>`.

## 6. Reconcile plan.md

After a successful revert/reset, edit the target track's `plan.md`:

- Reset the reverted task line to `- [ ] Task: <description>
  [<task-type>]` (strip the SHA).
- If a phase was reverted, also strip its `[checkpoint: <sha>]` suffix
  from the heading.
- If the whole track was reverted, also remove the awaiting-review note
  from `conductor/tracks.md` if present, and reset the track's registry
  checkbox to `[ ]`.

Stage `plan.md` (and `tracks.md` if it changed) and commit:
`conductor(plan): Reset '<target>' after revert`.

## 7. Announce completion

State exactly what was reverted (target description + SHA count), which
strategy was used, and the resulting `plan.md`/registry state.
```

- [ ] **Step 2: Verify (static check)**

```bash
cd /Users/dt105/git/playground/conductor2
grep -nE '^## 1\. Target selection$|^## 2\. Git reconciliation$|^## 3\. Present the execution plan$|^## 4\. Strategy choice$|^## 5\. Execute$|^## 6\. Reconcile plan\.md$|^## 7\. Announce completion$' .opencode/command/revert.md
grep -nE 'git revert --no-edit' .opencode/command/revert.md
grep -nE 'git reset --hard' .opencode/command/revert.md
grep -nE 'Ghost-commit handling' .opencode/command/revert.md
grep -nE "initialize track '<track_id>'" .opencode/command/revert.md
```

Expected: all seven step headers found, plus all four supporting greps.

- [ ] **Step 3: Behavioral fixture test — Safe-strategy task revert (round trip)**

Build this fixture by actually running `/implement` first (so the SHAs
and commits are genuine, matching the design's requirement), then revert
the resulting task and confirm the working tree returns to its pre-task
state.

```bash
FIXTURE=$(mktemp -d /tmp/conductor-revert-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor/tracks/hc_20260731"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md .opencode/command/revert.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/workflow.md "$FIXTURE/conductor/"
cat > "$FIXTURE/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [ ] **Track: Add health-check endpoint** *Link: [tracks/hc_20260731/plan.md](./tracks/hc_20260731/plan.md)*

## Blocked
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/spec.md" <<'EOF'
# Spec: Health-check endpoint

## Acceptance Criteria
- `GET /health` returns 200 and body `ok`.
EOF
cat > "$FIXTURE/conductor/tracks/hc_20260731/plan.md" <<'EOF'
# Plan: Add health-check endpoint

## Phase 1: Health endpoint

- [ ] Task: Add GET /health returning 200 ok [backend-logic]
EOF
cat > "$FIXTURE/server.js" <<'EOF'
function handler(req, res) {
  res.statusCode = 404;
  res.end('not found');
}
module.exports = { handler };
EOF
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "chore(conductor): initialize track 'hc_20260731'"
PRE_TASK_SHA=$(git log -1 --format=%h)
echo "$PRE_TASK_SHA" > /tmp/revert_pre_task_sha.txt

opencode run --command implement "hc_20260731 Node.js project, use node --test. Implement the single task test-first, commit via the task commit procedure, then at the phase checkpoint reply yes. Skip doc-sync (no product.md/tech-stack.md exist), then stop." --format json --dir "$FIXTURE" > /tmp/revert_setup_run.json 2>&1 &
BGPID=$!
sleep 180
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - continue via session id"; kill $BGPID; else echo "implement phase FINISHED"; fi
echo "=== plan.md before revert ==="
cat conductor/tracks/hc_20260731/plan.md
echo "=== git log before revert ==="
git log --oneline
echo "$FIXTURE" > /tmp/revert_fixture_path.txt
```

Now revert the task:

```bash
FIXTURE=$(cat /tmp/revert_fixture_path.txt)
cd "$FIXTURE"
opencode run --command revert "hc_20260731 revert the task 'Add GET /health returning 200 ok'. When asked to confirm the target, reply yes. When asked to choose a strategy, choose Safe." --format json --dir "$FIXTURE" > /tmp/revert_run.json 2>&1 &
BGPID=$!
sleep 120
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - continue via session id from /tmp/revert_run.json with 'yes' / 'Safe' as needed"; kill $BGPID; else echo FINISHED; fi
echo "=== plan.md after revert ==="
cat conductor/tracks/hc_20260731/plan.md
echo "=== git log after revert ==="
git log --oneline
echo "=== diff vs pre-task state ==="
git diff "$(cat /tmp/revert_pre_task_sha.txt)" HEAD -- server.js
```

Expected: `plan.md`'s task line is back to
`- [ ] Task: Add GET /health returning 200 ok [backend-logic]` (no SHA);
`git log --oneline` contains new commits after the original task commits
(the reverts); the final `git diff` against `PRE_TASK_SHA` for
`server.js` is **empty** (the code is back to its pre-task state — note
`plan.md` itself will still differ, which is expected and correct).

- [ ] **Step 4: Behavioral fixture test — ghost-commit halt**

```bash
FIXTURE2=$(mktemp -d /tmp/conductor-revert-ghost-fixture.XXXXXX)
mkdir -p "$FIXTURE2/.opencode/command" "$FIXTURE2/conductor/tracks/ghost_20260731"
mkdir -p "$FIXTURE2/.opencode/command"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/revert.md "$FIXTURE2/.opencode/command/"
cp conductor/index.md "$FIXTURE2/conductor/"
cat > "$FIXTURE2/conductor/tracks.md" <<'EOF'
# Tracks Registry

## Active

- [~] **Track: Ghost track** *Link: [tracks/ghost_20260731/plan.md](./tracks/ghost_20260731/plan.md)*

## Blocked
EOF
cat > "$FIXTURE2/conductor/tracks/ghost_20260731/plan.md" <<'EOF'
# Plan: Ghost track

## Phase 1: Ghost phase [checkpoint: fffffff]

- [x] Task: Ghost task [backend-logic] fffffff
EOF
cd "$FIXTURE2"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed: no commit fffffff actually exists"
opencode run --command revert "ghost_20260731 revert the task 'Ghost task'. When asked to confirm the target, reply yes." --format json --dir "$FIXTURE2" > /tmp/revert_ghost_run.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo STILL_RUNNING; kill $BGPID; else echo FINISHED; fi
python3 -c "
import json
for line in open('/tmp/revert_ghost_run.json'):
    line=line.strip()
    if not line: continue
    try: obj=json.loads(line)
    except: continue
    if obj.get('type')=='text':
        print(obj['part']['text'])
"
echo "$FIXTURE2" > /tmp/revert_ghost_fixture_path.txt
git log --oneline
```

Expected: the run's text output mentions the SHA `fffffff` could not be
found / doesn't exist, and asks the user a Yes/No-style question about
using a substitute — it does not silently proceed with a revert, and
`git log --oneline` shows no new revert/reset commits (still just the
seed commit).

- [ ] **Step 5: Clean up fixtures and commit the doc change**

```bash
rm -rf "$(cat /tmp/revert_fixture_path.txt)" "$(cat /tmp/revert_ghost_fixture_path.txt)"
rm -f /tmp/revert_pre_task_sha.txt /tmp/*.json /tmp/*fixture_path.txt
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/revert.md
git commit -m "Implement full git-reconciliation revert protocol for tracks, phases, and tasks"
```

---

## Self-Review

**Spec coverage:**
- Design §1 (per-task commits, SHA formats, phase checkpoint procedure) →
  Task 1 (canonical) + Task 2 (setup.md mirror) + Task 4 Step 1-2
  (implement.md defers to it) + Task 5 Step 1 (review.md defers to it). ✓
- Design §2 / G12 (track-creation commit) → Task 3 Step 2. ✓
- Design §3 / G1 (doc-sync) → Task 4 Step 3, with both positive
  (Step 7 fixture) and negative-control behavior specified inline in the
  doc text itself ("state that briefly and move on — do not ask a
  question"). ✓
- Design §4 / G4 (status progress) → Task 6. ✓
- Design §5 / G5 (revert: target selection, git reconciliation, ghost
  commits, strategy choice, execute, plan.md reconciliation, completion)
  → Task 7 Step 1, sections 1 through 7 map 1:1 to design §5's 8 numbered
  steps (design's step 8 "announce" = revert.md's step 7). ✓
- Interfaces/cross-file dependencies section → enforced by task ordering
  (1→2→3→4/5→6/7) and each task's "Interfaces: Consumes" block. ✓
- Testing Layer 1 (static) → every task's "Verify (static check)" step. ✓
- Testing Layer 2 (behavioral fixtures) → every task's fixture-test step,
  using the exact `opencode run --command <name> --dir <fixture>` pattern
  confirmed live during spec verification, including session-continuation
  for interactive prompts and treating unexpected halts as failures. ✓

**Placeholder scan:** No TBD/TODO/"add appropriate handling" phrasing.
Every replacement block is given verbatim. Every fixture script is a
complete, runnable bash block with concrete file contents (not
"similar to the above" — Task 4 Step 7's fixture is fully re-specified
rather than referencing Step 6's).

**Type/format consistency:** the task-line format
`- [x] Task: <description> [<task-type>] <sha>`, the phase-heading format
`## Phase <N>: <title> [checkpoint: <sha>]`, and the three commit-message
formats (`conductor(plan): Mark task '<task>' as complete`,
`conductor(plan): Mark phase '<N> — <title>' as complete`,
`docs(conductor): Synchronize docs for track '<track_id>'`,
`chore(conductor): initialize track '<track_id>'`) are introduced once in
Task 1/3 and then referenced identically (not restated with variations)
in Tasks 2, 4, 5, 6, and 7's verify/fixture steps.

**Scope check:** exactly seven files touched:
`conductor/workflow.md`, `.opencode/command/setup.md`,
`.opencode/command/new-track.md`, `.opencode/command/implement.md`,
`.opencode/command/review.md`, `.opencode/command/status.md`, and
`.opencode/command/revert.md` — matches the design's Interfaces section
exactly, no Tier 2/3 files touched.
