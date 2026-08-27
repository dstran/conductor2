# Phase Auto-Checkpoint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the design in
`docs/superpowers/specs/2026-08-21-phase-auto-checkpoint-design.md`: add a
static `[manual-checkpoint]` phase-heading tag, written by `/new-track` at
plan-generation time, that lets `/implement` skip the manual "does this
meet expectations?" pause for untagged (low-risk) phases while preserving
today's full manual gate for tagged phases — without ever changing
`/implement`'s track-end behavior of always requiring the user to run
`/review` themselves.

**Architecture:** Doctrine-only changes across four markdown command/workflow
docs, each independently reviewable and committable:

1. `conductor/workflow.md`'s "Phase checkpoint procedure" section (and its
   verbatim mirror embedded in `.opencode/command/setup.md`) gains the
   tag-check rule replacing the old blanket "always pause" language.
2. `.opencode/command/implement.md` step 3 branches on the tag instead of
   always pausing.
3. `.opencode/command/new-track.md` gains the tagging heuristic when it
   writes phase headings.
4. `docs/gemini-parity-gaps.md` logs this as a genuine addition, matching
   how prior net-new features (`unbias`, per-feature brainstorming) are
   logged there.

No change to `revert.md` or `status.md` source text — Task 5 verifies via
live fixtures that the new tag is inert to their existing parsing, per the
spec's Interfaces/cross-file impact section. Verified with the same
two-layer approach as prior plans in this repo: static grep/consistency
checks per doc edit, then live `opencode run --command <name> --dir
<fixture>` behavioral tests against disposable `/tmp` git fixtures,
mirroring `docs/superpowers/plans/2026-08-19-new-track-brainstorming.md`.

**Tech Stack:** Markdown command docs (OpenCode command discovery), git,
bash, grep, `opencode run` for live behavioral fixtures.

## Global Constraints

- **Tag format (spec §1):** `[manual-checkpoint]` on a phase heading,
  positioned before the completion tag: untagged checkpointed phase stays
  `## Phase <N>: <title> [checkpoint: <sha>]` (today's format, unchanged);
  tagged checkpointed phase becomes
  `## Phase <N>: <title> [manual-checkpoint] [checkpoint: <sha>]`.
- **Default is untagged = auto-checkpoint (spec §1, §3):** no pause, no
  wait for a reply, when a phase heading has no `[manual-checkpoint]` tag
  at checkpoint time.
- **Tagging heuristic, exact rule (spec §2):** `/new-track` tags a phase
  `[manual-checkpoint]` if it contains an `e2e-flow` task, OR it contains
  both a `frontend-ui` task and an `api-client`/`api-contract` task in the
  same phase. All other phases are left untagged.
- **Static, plan-time only — no runtime re-tagging (spec Non-goals):**
  `/implement` never adds the tag itself mid-run. It reads the heading
  fresh at each phase's checkpoint step and never remembers a tag that was
  since removed by hand-editing `plan.md`.
- **No track-wide flag (spec Non-goals):** there is no
  `Checkpoint mode: manual` line or equivalent anywhere. Per-phase tags are
  the only mechanism.
- **`/implement` never auto-invokes `/review`, in any tagging mix (spec
  Non-goals, hard constraint):** whether zero, some, or all phases were
  tagged, track completion still ends with `/implement` updating
  `tracks.md` to the awaiting-review state and telling the user to run
  `/review <track_id>` themselves, then stopping. Nothing in this plan
  changes that.
- **No change to task-level execution:** the strict test-first/test-after
  loops and per-task commit procedure are untouched — only the
  phase-boundary checkpoint step (`implement.md` step 3 / `workflow.md`'s
  "Phase checkpoint procedure") is affected.
- Out of scope (per spec Non-goals): any change to `revert.md`'s or
  `status.md`'s source text (Task 5 only *verifies* they remain
  unaffected); any runtime heuristic re-evaluation by `/implement`.

---

### Task 1: Update the phase checkpoint procedure in `workflow.md` and its `setup.md` mirror

**Files:**
- Modify: `conductor/workflow.md:83-108` (the "Phase checkpoint procedure"
  section, up to the blank line before "## Commit strategy")
- Modify: `.opencode/command/setup.md:160-185` (the verbatim embedded copy
  of the same section, inside the fenced `workflow.md` content block)

**Interfaces:**
- Consumes: nothing new from other files.
- Produces: the tag-check rule and the `[manual-checkpoint]` tag format
  documentation that Task 2 (`implement.md`) and Task 5 (fixtures) rely on
  as the doctrinal source of truth.

- [ ] **Step 1: Confirm both sections are still identical before editing**

```bash
cd /Users/dt105/git/playground/conductor2
diff <(sed -n '83,108p' conductor/workflow.md) <(sed -n '160,185p' .opencode/command/setup.md)
```

Expected: no output (files match). If they differ, stop and reconcile
before proceeding — the two copies must start identical for this task's
single replacement text to apply cleanly to both.

- [ ] **Step 2: Replace the section in `conductor/workflow.md`**

Find this exact text (lines 83-108):

```markdown
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
```

Replace it with:

```markdown
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
```

- [ ] **Step 3: Apply the identical replacement inside `.opencode/command/setup.md`**

Same old text and new text as Step 2, applied at `setup.md:160-185` (inside
the fenced `workflow.md` content block setup.md writes out on first run).

- [ ] **Step 4: Re-confirm the two copies still match**

```bash
cd /Users/dt105/git/playground/conductor2
diff <(sed -n '/^## Phase checkpoint procedure$/,/^## Commit strategy$/p' conductor/workflow.md | sed '$d') \
     <(sed -n '/^## Phase checkpoint procedure$/,/^## Commit strategy$/p' .opencode/command/setup.md | sed '$d')
```

Expected: no output.

- [ ] **Step 5: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- tag-check rule present in both files ---"
grep -nE 'Tagged .\[manual-checkpoint\].' conductor/workflow.md .opencode/command/setup.md
echo "--- untagged-default language present ---"
grep -nE 'Untagged \(the default\)' conductor/workflow.md .opencode/command/setup.md
echo "--- never-auto-invoke-review language present ---"
grep -nE 'never invoke .`/review`. itself' conductor/workflow.md .opencode/command/setup.md
echo "--- old blanket-pause sentence removed ---"
grep -nE '^`/implement` pauses at the end of every phase, presents a summary, asks$' conductor/workflow.md .opencode/command/setup.md && echo "FAIL: old text remains" || echo "OK old text gone"
```

Expected: every grep except the last finds matches in both files; the last
prints `OK old text gone`.

- [ ] **Step 6: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add conductor/workflow.md .opencode/command/setup.md
git commit -m "Add [manual-checkpoint] tag-check to phase checkpoint procedure"
```

---

### Task 2: Branch `/implement`'s phase checkpoint step on the tag

**Files:**
- Modify: `.opencode/command/implement.md:54-84` (step 3, items a-g)

**Interfaces:**
- Consumes: the tag format and rule documented in Task 1's
  `conductor/workflow.md` edit.
- Produces: the branching behavior Task 5's fixtures exercise directly.

- [ ] **Step 1: Confirm current text**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '54,84p' .opencode/command/implement.md
```

Confirm it matches the current step 3 (items a-g) as read during
brainstorming — if it has drifted, adjust the old-text match below to the
actual current wording.

- [ ] **Step 2: Replace step 3**

Find this exact text (lines 54-84):

```markdown
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

Replace it with:

```markdown
## 3. Phase checkpoint (trigger this the moment a phase's last task is `[x]`)
Do not silently continue to the next phase. Instead:
   a. Identify the git commit SHA at the start of this phase (the
      previous phase's `[checkpoint: <sha>]`, or the track's creation
      commit if this is phase 1). Scope everything below to files
      changed since that point.
   b. Run the automated tests relevant to this phase's changes
      (not necessarily the full suite — that's `/review`'s job at
      track end).
   c. Read the phase heading in `plan.md` fresh (do not reuse an earlier
      read) to check for a `[manual-checkpoint]` tag — the user may have
      added or removed it since this phase started.
   d. **If tagged `[manual-checkpoint]`:** write out explicit manual
      verification steps (exact commands to run and what result
      confirms success). Present a short phase summary to the user:
      what was built, automated test results, and the manual
      verification steps. Ask: "Does this meet expectations? Reply yes
      to checkpoint and continue, or tell me what to change." PAUSE and
      wait.
      - If the user gives feedback: fix it in place (using the task
        commit procedure for whatever changed), re-run only the checks
        that fix could affect, and re-present the phase summary. Loop
        until they say yes. No round cap, same as `/review`'s
        correction loop — but note if this is the 3rd+ round on the
        same file or area, same as `/review` does.
      - Do not proceed to step f until the user has given an explicit
        yes.
   e. **If untagged:** present the same short phase summary as above,
      plus the line "No manual checkpoint required —
      auto-checkpointing." Do not pause or wait for a reply — proceed
      immediately to step f.
   f. Follow the **phase checkpoint procedure** in `conductor/workflow.md`
      exactly — attach the phase summary (test results + manual
      verification steps, if any) as a git note on the last task commit
      in this phase, then commit `plan.md` with the phase heading marked
      `## Phase <N>: <title> [checkpoint: <sha>]` (appended after any
      existing `[manual-checkpoint]` tag). Do not create a new empty
      commit.
   g. Move to the next phase and repeat from step 2. If this was the
      last phase, go to step 4.
```

- [ ] **Step 3: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- tag-check step present ---"
grep -nE 'check for a .\[manual-checkpoint\]. tag' .opencode/command/implement.md
echo "--- tagged branch present ---"
grep -nE '\*\*If tagged .\[manual-checkpoint\].:\*\*' .opencode/command/implement.md
echo "--- untagged branch present ---"
grep -nE '\*\*If untagged:\*\*' .opencode/command/implement.md
echo "--- auto-checkpointing line present ---"
grep -nE 'No manual checkpoint required' .opencode/command/implement.md
echo "--- old runtime judgment-call sentence removed ---"
grep -nE "can't be confirmed by an automated" .opencode/command/implement.md && echo "FAIL: old text remains" || echo "OK old text gone"
echo "--- step 4 (track complete) still says hand off manually ---"
grep -nE "ready for .`/review \\\$ARGUMENTS`." .opencode/command/implement.md
```

Expected: every grep except the "old text removed" check finds matches;
that one prints `OK old text gone`.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/implement.md
git commit -m "Branch /implement's phase checkpoint on the [manual-checkpoint] tag"
```

---

### Task 3: Add the tagging heuristic to `/new-track`'s plan generation

**Files:**
- Modify: `.opencode/command/new-track.md:26-36` (step 3, "Create the track
  artifacts")

**Interfaces:**
- Consumes: the `[manual-checkpoint]` tag format from Task 1.
- Produces: the actual tag-writing behavior Task 5's fixtures verify by
  inspecting generated `plan.md` headings.

- [ ] **Step 1: Confirm current text**

```bash
cd /Users/dt105/git/playground/conductor2
sed -n '26,36p' .opencode/command/new-track.md
```

- [ ] **Step 2: Insert the heuristic**

Find this exact text (the last paragraph of step 3, currently ending the
section):

```markdown
Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.
```

Replace it with the same paragraph followed by a new one:

```markdown
Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.

**Phase checkpoint tagging:** when writing each phase heading, tag it `## Phase <N>: <title> [manual-checkpoint]` if the phase contains an `e2e-flow` task, or contains both a `frontend-ui` task and an `api-client`/`api-contract` task (i.e. a UI wired to a real backend call within that phase). Otherwise leave the heading untagged: `## Phase <N>: <title>`. Untagged is the default — `/implement` auto-checkpoints untagged phases without pausing (see `conductor/workflow.md`'s phase checkpoint procedure). These tags are visible in the plan the user already reviews before approval; the user may add or remove `[manual-checkpoint]` on any phase heading by hand at any time before `/implement` reaches that phase's checkpoint step.
```

- [ ] **Step 3: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- heuristic paragraph present ---"
grep -nE '\*\*Phase checkpoint tagging:\*\*' .opencode/command/new-track.md
echo "--- e2e-flow condition present ---"
grep -nE 'contains an .`e2e-flow`. task' .opencode/command/new-track.md
echo "--- frontend-ui + api pairing condition present ---"
grep -nE 'frontend-ui.*task and an .`api-client`/`api-contract`. task' .opencode/command/new-track.md
echo "--- untagged-default language present ---"
grep -nE 'Untagged is the default' .opencode/command/new-track.md
```

Expected: all four greps find a match.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/new-track.md
git commit -m "Add [manual-checkpoint] tagging heuristic to /new-track's plan generation"
```

---

### Task 4: Log the addition in the parity ledger

**Files:**
- Modify: `docs/gemini-parity-gaps.md` — append one bullet to the "Port
  improvements over upstream (keep — do not regress)" section (current end
  of file).

**Interfaces:**
- Consumes: nothing.
- Produces: an honest record that this is net-new scope, matching how
  `unbias` and the per-feature brainstorming step are already logged there.

- [ ] **Step 1: Confirm the current end of the file**

```bash
cd /Users/dt105/git/playground/conductor2
tail -n 5 docs/gemini-parity-gaps.md
```

Confirm the last line is:
```
- `unbias` contract in `skill/SKILL.md` — genuine addition, not in upstream.
```

(If a later bullet, e.g. the brainstorming-step entry, has already been
appended after this by the time this task runs, append after whichever
bullet is actually last — do not overwrite existing entries.)

- [ ] **Step 2: Append the new bullet**

Add this line at the end of the file:

```
- Static `[manual-checkpoint]` phase tagging in `/new-track` +
  auto-checkpoint in `/implement` (see
  `docs/superpowers/specs/2026-08-21-phase-auto-checkpoint-design.md`) —
  genuine addition, not in upstream. `/implement` still never
  auto-invokes `/review`.
```

- [ ] **Step 3: Verify**

```bash
cd /Users/dt105/git/playground/conductor2
grep -nE 'Static .\[manual-checkpoint\]. phase tagging' docs/gemini-parity-gaps.md
```

Expected: one match, at the last line of the file.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add docs/gemini-parity-gaps.md
git commit -m "Log phase auto-checkpoint tagging as a genuine addition in the parity ledger"
```

---

### Task 5: Behavioral fixture tests

**Files:**
- No source files modified — this task only runs live `opencode run`
  fixtures against the edited docs from Tasks 1-3 and reports pass/fail per
  scenario from the spec's test table.

**Interfaces:**
- Consumes: the finished `conductor/workflow.md`, `.opencode/command/{setup,implement,new-track}.md` from Tasks 1-3.
- Produces: a pass/fail record for each scenario in the spec's Layer-2
  table; no artifacts land in this repo (all fixtures live under `/tmp`
  and are deleted at the end).

- [ ] **Step 1: Build the shared fixture skeleton**

```bash
FIXTURE=$(mktemp -d /tmp/conductor-checkpoint-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor/tracks"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md .opencode/command/status.md .opencode/command/revert.md .opencode/command/new-track.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE/conductor/"
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture"
echo "$FIXTURE" > /tmp/checkpoint_fixture_path.txt
echo "$FIXTURE"
```

- [ ] **Step 2: Hand-author a mixed-tag track fixture**

Create a track with one untagged phase (backend-only) and one tagged phase
(e2e-flow), so Scenarios A/B/E can all run against a single fixture track:

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
mkdir -p "$FIXTURE/conductor/tracks/checkpoint-demo_20260821"
cat > "$FIXTURE/conductor/tracks/checkpoint-demo_20260821/spec.md" <<'EOF'
# Spec: Checkpoint demo

A trivial two-phase track used to exercise phase auto-checkpoint tagging.
Phase 1 is backend-only. Phase 2 exercises a full user flow (e2e-flow).
EOF
cat > "$FIXTURE/conductor/tracks/checkpoint-demo_20260821/plan.md" <<'EOF'
# Plan: Checkpoint demo

## Phase 1: Add a pure function
- [ ] Task: Add an `add(a, b)` function that returns `a + b` [backend-logic]

## Phase 2: Exercise the full flow [manual-checkpoint]
- [ ] Task: Write an e2e script that calls `add(2, 3)` and checks the result is `5` [e2e-flow]
EOF
cat > "$FIXTURE/conductor/tracks/checkpoint-demo_20260821/metadata.json" <<'EOF'
{"trackId": "checkpoint-demo_20260821", "type": "feature", "status": "new"}
EOF
cd "$FIXTURE"
git add -A && git commit -q -m "seed checkpoint-demo track"
echo "seeded"
```

- [ ] **Step 3: Scenario A — untagged phase auto-checkpoints, no pause**

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
cd /Users/dt105/git/playground/conductor2
opencode run --command implement "checkpoint-demo_20260821 Use plain shell/node for the add function and a simple assert for its test. Only implement Phase 1 in this run, then stop before starting Phase 2." --format json --dir "$FIXTURE" > /tmp/checkpoint_scenarioA.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/checkpoint_scenarioA.json"; kill $BGPID; else echo FINISHED; fi
cd "$FIXTURE"
echo "=== Phase 1 heading ==="
grep -nE '^## Phase 1:' conductor/tracks/checkpoint-demo_20260821/plan.md
```

Expected: `## Phase 1: Add a pure function [checkpoint: <sha>]` — no
`[manual-checkpoint]` tag present, and no "does this meet expectations?"
prompt should appear in the transcript for Phase 1 (spot-check
`/tmp/checkpoint_scenarioA.json` for that exact phrase — it should be
absent for Phase 1).

- [ ] **Step 4: Scenario B — tagged phase still pauses for explicit yes**

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
cd /Users/dt105/git/playground/conductor2
opencode run --command implement "checkpoint-demo_20260821 Continue with Phase 2. Use a plain shell/node script for the e2e-flow task." --format json --dir "$FIXTURE" > /tmp/checkpoint_scenarioB.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/checkpoint_scenarioB.json, likely paused awaiting the phase-2 checkpoint reply"; else echo FINISHED; fi
grep -inE 'does this meet expectations' /tmp/checkpoint_scenarioB.json && echo "OK: manual gate was presented" || echo "FAIL: no manual gate prompt found for tagged phase"
```

If still running (paused for the reply), send the approval as a follow-up
turn using the session id printed in `/tmp/checkpoint_scenarioB.json`,
then re-check:

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
cd "$FIXTURE"
echo "=== Phase 2 heading ==="
grep -nE '^## Phase 2:' conductor/tracks/checkpoint-demo_20260821/plan.md
```

Expected: `## Phase 2: Exercise the full flow [manual-checkpoint] [checkpoint: <sha>]`
— tag preserved, completion SHA appended after it.

- [ ] **Step 5: Scenario C — hand-edit removes the tag before /implement reaches the phase**

```bash
FIXTURE2=$(mktemp -d /tmp/conductor-checkpoint-fixture2.XXXXXX)
mkdir -p "$FIXTURE2/.opencode/command" "$FIXTURE2/conductor/tracks/checkpoint-untag_20260821"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md .opencode/command/status.md .opencode/command/revert.md "$FIXTURE2/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE2/conductor/"
cat > "$FIXTURE2/conductor/tracks/checkpoint-untag_20260821/spec.md" <<'EOF'
# Spec: Untag demo
Single e2e-flow phase, tag removed by hand before /implement runs.
EOF
cat > "$FIXTURE2/conductor/tracks/checkpoint-untag_20260821/plan.md" <<'EOF'
# Plan: Untag demo

## Phase 1: Exercise the full flow
- [ ] Task: Write an e2e script that checks `1 + 1 == 2` [e2e-flow]
EOF
cat > "$FIXTURE2/conductor/tracks/checkpoint-untag_20260821/metadata.json" <<'EOF'
{"trackId": "checkpoint-untag_20260821", "type": "feature", "status": "new"}
EOF
cd "$FIXTURE2"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed untag fixture (no [manual-checkpoint] tag despite e2e-flow task)"
echo "$FIXTURE2" > /tmp/checkpoint_fixture2_path.txt
cd /Users/dt105/git/playground/conductor2
opencode run --command implement "checkpoint-untag_20260821 Use a plain shell/node script for the e2e-flow task." --format json --dir "$FIXTURE2" > /tmp/checkpoint_scenarioC.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING"; kill $BGPID; else echo FINISHED; fi
grep -inE 'does this meet expectations' /tmp/checkpoint_scenarioC.json && echo "FAIL: paused despite no tag" || echo "OK: no pause for untagged phase"
cd "$FIXTURE2"
grep -nE '^## Phase 1:' conductor/tracks/checkpoint-untag_20260821/plan.md
```

Expected: `OK: no pause for untagged phase`; heading ends as
`## Phase 1: Exercise the full flow [checkpoint: <sha>]` — no tag, despite
the phase containing an `e2e-flow` task that `/new-track`'s heuristic would
have tagged. This proves a hand-removed tag is honored.

- [ ] **Step 6: Scenario D — hand-edit adds the tag to an otherwise-untagged phase**

```bash
FIXTURE3=$(mktemp -d /tmp/conductor-checkpoint-fixture3.XXXXXX)
mkdir -p "$FIXTURE3/.opencode/command" "$FIXTURE3/conductor/tracks/checkpoint-forcetag_20260821"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/implement.md "$FIXTURE3/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE3/conductor/"
cat > "$FIXTURE3/conductor/tracks/checkpoint-forcetag_20260821/spec.md" <<'EOF'
# Spec: Force-tag demo
Single backend-logic phase, [manual-checkpoint] added by hand despite the heuristic not flagging it.
EOF
cat > "$FIXTURE3/conductor/tracks/checkpoint-forcetag_20260821/plan.md" <<'EOF'
# Plan: Force-tag demo

## Phase 1: Add a pure function [manual-checkpoint]
- [ ] Task: Add a `double(x)` function that returns `x * 2` [backend-logic]
EOF
cat > "$FIXTURE3/conductor/tracks/checkpoint-forcetag_20260821/metadata.json" <<'EOF'
{"trackId": "checkpoint-forcetag_20260821", "type": "feature", "status": "new"}
EOF
cd "$FIXTURE3"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed force-tag fixture ([manual-checkpoint] on a backend-only phase)"
echo "$FIXTURE3" > /tmp/checkpoint_fixture3_path.txt
cd /Users/dt105/git/playground/conductor2
opencode run --command implement "checkpoint-forcetag_20260821 Use plain shell/node for the double function and its test." --format json --dir "$FIXTURE3" > /tmp/checkpoint_scenarioD.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/checkpoint_scenarioD.json, likely paused awaiting the checkpoint reply"; else echo FINISHED; fi
grep -inE 'does this meet expectations' /tmp/checkpoint_scenarioD.json && echo "OK: manual gate honored despite heuristic not flagging this phase" || echo "FAIL: no pause found"
```

Expected: `OK: manual gate honored despite heuristic not flagging this
phase` — proves a hand-added tag forces the pause even for a phase that
would otherwise auto-checkpoint.

- [ ] **Step 7: Scenario E — no auto-invocation of `/review`, and `status.md`/`revert.md` stay unaffected**

Using the mixed-tag fixture from Steps 2-4 (now with both phases
checkpointed):

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
cd "$FIXTURE"
echo "=== no review-closure commit or git note exists ==="
git log --oneline | grep -iE 'conductor\(track\)' && echo "FAIL: review closure commit found" || echo "OK: no review closure commit"
git notes list 2>/dev/null | wc -l
echo "(git notes count above should equal the number of checkpointed phases, i.e. 2 — one phase-summary note each, none from /review)"
echo "=== tracks.md shows awaiting-review, not completed ==="
grep -nE 'awaiting review' conductor/tracks.md
echo "=== status.md parses the tagged, checkpointed phase with no false inconsistency flag ==="
cd /Users/dt105/git/playground/conductor2
opencode run --command status "" --format json --dir "$FIXTURE" > /tmp/checkpoint_scenarioE_status.json 2>&1
grep -inE 'inconsistency|missing.*checkpoint' /tmp/checkpoint_scenarioE_status.json && echo "FAIL: false checkpoint-inconsistency flag raised" || echo "OK: no false flag"
```

Expected: `OK: no review closure commit`; git notes count is 2 (one per
checkpointed phase); `tracks.md` shows the awaiting-review note; `OK: no
false flag` from `/status`.

- [ ] **Step 8: `revert.md` pass-through check on the tagged phase**

```bash
FIXTURE=$(cat /tmp/checkpoint_fixture_path.txt)
cd /Users/dt105/git/playground/conductor2
opencode run --command revert "checkpoint-demo_20260821 Phase 2" --format json --dir "$FIXTURE" > /tmp/checkpoint_scenarioE_revert.json 2>&1 &
BGPID=$!
sleep 60
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - answer the confirmation/strategy-choice prompts (Yes to revert, Safe strategy) via a follow-up opencode run turn with the session id, then re-run the check below"; else echo FINISHED; fi
cd "$FIXTURE"
grep -nE '^## Phase 2:' conductor/tracks/checkpoint-demo_20260821/plan.md
```

Expected: `## Phase 2: Exercise the full flow [manual-checkpoint]` — the
`[checkpoint: <sha>]` suffix is stripped by `/revert` as designed, and the
`[manual-checkpoint]` tag is left untouched (proving the tag describes
checkpoint *policy*, not completion state, per the spec's
Interfaces/cross-file impact section).

- [ ] **Step 9: Clean up all fixtures**

```bash
for f in /tmp/checkpoint_fixture_path.txt /tmp/checkpoint_fixture2_path.txt /tmp/checkpoint_fixture3_path.txt; do
  FX=$(cat "$f" 2>/dev/null) && rm -rf "$FX"
done
rm -f /tmp/checkpoint_fixture*_path.txt /tmp/checkpoint_scenario*.json 2>/dev/null
echo "cleanup done"
```

No commit for this task (no source files were changed).

---

## Self-Review Notes (completed during plan authoring)

- **Spec coverage:** §1 (tag format, coexistence with `[checkpoint: <sha>]`)
  → Task 1's `workflow.md`/`setup.md` edit + Task 2's `implement.md` step
  3f wording. §2 (heuristic) → Task 3's `new-track.md` paragraph. §3
  (execution flow branching) → Task 2's steps c/d/e. §4 (manual override,
  read-fresh, no runtime re-tag) → Task 2's step c wording + Task 5
  Scenarios C/D. §5 (track-end unchanged, no auto-`/review`) → Task 1's
  closing paragraph + Task 5 Scenario E. Non-goals (no track-wide flag, no
  runtime re-tagging, no task-level change) → explicitly not introduced
  anywhere in Tasks 1-3, confirmed by the "old text removed"/absence greps
  in each task's static verification. Interfaces/cross-file impact
  (`status.md`/`revert.md` pass-through) → Task 5 Steps 7-8. Testing
  approach (Layer 1/2) → each task's static verification (Layer 1) + Task
  5 (Layer 2, covering all six rows of the spec's behavioral test table).
- **Placeholder scan:** none found; every step has concrete before/after
  text, real bash commands, and real fixture content — no "TBD"/"add
  appropriate handling" language.
- **Type/format consistency:** the tag string `[manual-checkpoint]` and its
  position relative to `[checkpoint: <sha>]` are copied character-for-
  character identically across the spec, Global Constraints, Task 1's
  workflow.md replacement, Task 2's implement.md replacement, Task 3's
  new-track.md addition, and every fixture/grep in Task 5 — confirmed no
  drift (e.g. no accidental `[checkpoint-manual]` or reversed ordering).
