# Per-Feature Brainstorming in `/new-track` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the design in
`docs/superpowers/specs/2026-08-19-new-track-brainstorming-design.md`: add
a zero-ambiguity, per-fork brainstorming step to `/new-track` that runs
before track-ID generation, so the resulting `spec.md` is
implementation-ready (i.e. `/implement` → `/review` can run without
stopping to ask the user anything) — without ever auto-invoking
`/implement`.

**Architecture:** A single markdown-command edit to
`.opencode/command/new-track.md`: insert a new Step 1 ("Track
brainstorming") before the existing ID-generation step, renumber the
existing steps 1-6 to 2-7, and change Step 2 (ID generation) to consume
the *approved* understanding rather than raw `$ARGUMENTS`. `spec.md`'s
authored content gains two new provenance sections. No other command doc
(`workflow.md`, `implement.md`, `review.md`, `revert.md`, `status.md`)
changes — their artifact contracts are unaffected. Verified per the
spec's two-layer approach: static grep/consistency checks, then live
`opencode run --command new-track --dir <fixture>` behavioral tests
against disposable `/tmp` git fixtures, mirroring the precedent in
`docs/superpowers/plans/2026-07-31-tier1-conductor-parity.md`.

**Tech Stack:** Markdown command docs (OpenCode command discovery), the
OpenCode `question` tool (plain-text prompt fallback in headless
`opencode run`), git, bash, grep.

## Global Constraints

- **Exit gate (spec §2):** the brainstorming step ends only when BOTH (a)
  a mental `/implement` dry-run over the draft spec surfaces zero
  stop-and-ask points, and (b) every ambiguity category (data shapes, API
  contracts, error handling, edge cases, acceptance criteria, tech/library
  choices, out-of-scope boundaries, test expectations) is resolved or
  explicitly N/A. Both run internally; only the resulting questions and a
  final readiness summary are shown to the user.
- **No approach cap (spec §3):** at each fork with >1 viable option,
  present options + trade-offs + a recommendation, one question at a time.
  A single-option fork is stated, not offered as a choice. No "2-3
  approaches" ceiling.
- **Per-fork responses (spec §3):** the user may answer; say "you decide
  this one"; say "you decide the rest"; say "I don't know" (treated as
  "you decide this one"); or say "exit brainstorming now" (treated as "you
  decide the rest" for everything still open). Absent these, the loop is
  unbounded.
- **Provenance sections (spec §4), exact headers:**
  - `## Assumptions & agent-made decisions`
  - `## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK`
  A fully user-answered spec leaves both empty (present, no bullet
  content). The second section is populated only via "you decide the
  rest" / "exit brainstorming now"; when non-empty, `metadata.json` and
  the `tracks.md` entry must carry a review flag (see Task 3).
- **`$ARGUMENTS` is a seed, not a locked title (spec §1):** the track
  ID/shortname is generated AFTER design approval, from the approved
  understanding — never from the raw, pre-dialogue `$ARGUMENTS`.
- **Explicit skip hatch (spec §1):** if the user's invocation signals the
  spec is already decided (e.g. "skip brainstorming"), skip straight to
  ID generation using `$ARGUMENTS` as final — today's behavior, preserved
  verbatim as an escape hatch.
- **No auto-start of `/implement` (spec Non-goals, hard constraint):** the
  existing Step 6 pause (renumbered to Step 7) — "tell the user the track
  ID, next step is `/implement`, then stop" — is preserved byte-for-byte
  in intent. Nothing in the new step, and nothing in this plan, causes
  `/new-track` to invoke `/implement`.
- **Self-review before presenting (spec §5):** after drafting `spec.md`
  and before the design-approval gate, do one inline pass — placeholder
  scan, internal consistency, ambiguity check — fixing issues inline, no
  separate re-review loop.
- **Two distinct, sequential, both-return-to-user gates (spec §6):** Gate
  A (new, end of brainstorming) approves the design before artifact
  creation; Gate B (existing, renumbered Step 7) is unchanged and terminal.
- Out of scope (per spec Non-goals): scope-decomposition for
  oversized/multi-subsystem descriptions; the visual-companion browser
  tool; any change to `workflow.md`/`implement.md`/`review.md`/`revert.md`/`status.md`.

---

### Task 1: Insert the "Track brainstorming" step and renumber

**Files:**
- Modify: `.opencode/command/new-track.md` — insert a new step between the
  current header block (lines 1-12, unchanged) and the current step "## 1.
  Track description" (line 14); renumber all six existing steps (1→2, 2→3,
  3→4, 4→5, 5→6, 6→7); rewrite the (renumbered) ID-generation step to
  consume the approved understanding instead of raw `$ARGUMENTS`.

**Interfaces:**
- Consumes: nothing new from other files.
- Produces: the exact section header `## 1. Track brainstorming` that
  Task 2 (spec provenance sections) and Task 4 (fixture tests) depend on;
  the renumbered `## 7. Pause for approval` heading that Task 3's
  registry-flag step and Task 4's no-auto-start fixture test depend on.

- [ ] **Step 1: Read the current file to confirm anchor text**

```bash
cd /Users/dt105/git/playground/conductor2
cat -n .opencode/command/new-track.md
```

Confirm it matches the 53-line version quoted below (if it has drifted,
adjust the replacement in Step 2 to the actual current text rather than
blindly overwriting).

```
1: ---
2: description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
3: agent: build
4: ---
5:
6: `/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.
7:
8: Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.
9:
10: If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.
11:
12: If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.
13:
14: ## 1. Track description
15:
16: Treat `$ARGUMENTS` as the track **description** — the feature, bug fix, or chore the user wants to plan. It is NOT the folder name. If `$ARGUMENTS` is empty, ask the user for a brief description of the track before continuing. Infer and confirm the track type (feature, bug, chore, refactor, MVP).
17:
18: ## 2. Generate the track ID
19:
20: Derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.
21:
22: Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).
23:
24: **Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.
25:
26: ## 3. Create the track artifacts
27:
28: Under the generated track ID, create:
29:
30: - `conductor/tracks/<track_id>/spec.md`
31: - `conductor/tracks/<track_id>/plan.md`
32: - `conductor/tracks/<track_id>/metadata.json`
33:
34: `metadata.json` records the track ID, type, status (`new`), and created/updated timestamps.
35:
36: Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.
37:
38: ## 4. Update the registry
39:
40: Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:
41:
42: `- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`
43:
44: ## 5. Commit the new track
45:
46: Stage `conductor/tracks/<track_id>/` and `conductor/tracks.md`, then
47: commit with the message `chore(conductor): initialize track '<track_id>'`.
48: This is the anchor commit `/revert` uses to find and undo an entire
49: track.
50:
51: ## 6. Pause for approval
52:
53: Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`.
```

- [ ] **Step 2: Replace the whole file**

Write the following as the complete new content of
`.opencode/command/new-track.md`:

```markdown
---
description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.

## 1. Track brainstorming

Treat `$ARGUMENTS` as a **seed** for this step, not a final description and not the track's shortname. If `$ARGUMENTS` is empty, ask the user for a brief description of what they want to build before continuing.

**Skip hatch:** if the user's request explicitly says the spec is already decided and to skip brainstorming (e.g. "skip brainstorming", "spec is already decided"), do not run the loop below — proceed directly to Step 2 using `$ARGUMENTS` as the final description, exactly as this command behaved before this step existed.

Otherwise, run the following loop before generating a track ID or creating any artifact:

1. **Draft understanding.** From the seed, identify the purpose, constraints, and success criteria as currently understood.
2. **Find decision forks.** Do two things internally (do not narrate this mechanism to the user — only its results):
   - **Mental `/implement` dry-run:** walk the draft spec as if implementing it, task by task. Every point where you would have to guess, or where `/implement` would have to stop and ask the user, is a decision fork.
   - **Ambiguity-category checklist:** confirm each of the following is resolved or explicitly not applicable: data shapes/models, external or internal API contracts, error handling and failure paths, edge cases and boundaries, acceptance/success criteria, tech and library choices, out-of-scope boundaries, test expectations. Any unresolved category is a decision fork.
   - If both the dry-run and the checklist come back clean, there are no more forks — go to step 4.
3. **Resolve forks, one question at a time.** For each fork:
   - If there is more than one viable option, present the options with trade-offs and your recommendation, then ask.
   - If there is exactly one sane option, state it — do not offer it as a choice.
   - The user may respond in one of four ways:
     - **Answer the question** — record the answer and continue to the next fork.
     - **"You decide this one" (or "I don't know" / "I don't care")** — pick the option you recommended (or the only sane one), record it under a running "Assumptions & agent-made decisions" list (value + one-line rationale), and continue.
     - **"You decide the rest"** — for every fork still open (this one and all remaining), pick the recommended/sane option and record each under a running "Open questions auto-decided by agent" list (value + one-line rationale). Stop asking and go to step 4.
     - **"Exit brainstorming now"** — treat exactly like "you decide the rest": auto-decide everything still open, record each, stop asking, go to step 4.
   - Repeat step 2 (re-check the dry-run and checklist against the now-updated draft) after each answered fork — resolving one fork can surface new ones. There is no cap on how many rounds this takes.
4. **Draft `spec.md` content** from the fully-resolved understanding. Include, verbatim as section headers:
   - `## Assumptions & agent-made decisions` — every fork resolved via "you decide this one"/"I don't know", each as a bullet: the decision and a one-line rationale. Leave the header with no bullets beneath it if this never happened.
   - `## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK` — every fork resolved via "you decide the rest"/"exit brainstorming now", each as a bullet: the decision and a one-line rationale. Leave the header with no bullets beneath it if this never happened.
5. **Self-review the draft once**, inline, before presenting it: scan for placeholders ("TBD", "TODO", incomplete sections), internal contradictions, and any requirement that could be read two ways — fix issues directly in the draft, no separate re-review pass.
6. **Present the design** (the drafted spec content) to the user and ask for approval. If they ask for changes, revise and re-present — loop with no round cap until they approve. This is Gate A; it is separate from, and earlier than, the pause-for-approval in Step 7 below — approving here does not start `/implement`, it only unlocks artifact creation in Step 3.

Do not proceed to Step 2 until either the skip hatch was used, or Gate A above has an explicit approval.

## 2. Generate the track ID

Using the approved understanding from Step 1 (not the raw seed, if it changed during brainstorming), derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.

Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).

**Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.

## 3. Create the track artifacts

Under the generated track ID, create:

- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`

Write `spec.md` using the exact content approved in Step 1's Gate A (do not re-draft it here), including its two provenance sections.

`metadata.json` records the track ID, type, status (`new`), and created/updated timestamps. If Step 1's "Open questions auto-decided by agent — PLEASE DOUBLE-CHECK" section is non-empty, also record `"needsReview": true` in `metadata.json`.

Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.

## 4. Update the registry

Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:

`- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

If `metadata.json` was written with `"needsReview": true`, append `— **needs review: contains auto-decided open questions**` to the entry label so this is visible directly in the registry.

## 5. Commit the new track

Stage `conductor/tracks/<track_id>/` and `conductor/tracks.md`, then
commit with the message `chore(conductor): initialize track '<track_id>'`.
This is the anchor commit `/revert` uses to find and undo an entire
track.

## 6. Announce readiness

Tell the user, in a short summary: the ambiguity-category checklist categories that were resolved vs. marked not-applicable (the readiness summary — do not show the dry-run reasoning itself), and whether `spec.md` contains any agent-auto-decided open questions that need double-checking.

## 7. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`. Do not invoke `/implement` yourself under any circumstances — this command ends here and the user must separately run `/implement`.
```

- [ ] **Step 3: Static verification**

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- new step present ---"
grep -nE '^## 1\. Track brainstorming$' .opencode/command/new-track.md
echo "--- skip hatch present ---"
grep -nE 'Skip hatch' .opencode/command/new-track.md
echo "--- dual exit gate present ---"
grep -nE 'Mental .`/implement`. dry-run' .opencode/command/new-track.md
grep -nE 'Ambiguity-category checklist' .opencode/command/new-track.md
echo "--- per-fork responses present ---"
grep -nE '"You decide this one"' .opencode/command/new-track.md
grep -nE '"You decide the rest"' .opencode/command/new-track.md
grep -nE '"Exit brainstorming now"' .opencode/command/new-track.md
echo "--- provenance section headers present verbatim ---"
grep -nE '^## Assumptions & agent-made decisions$' .opencode/command/new-track.md
grep -nE '^## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK$' .opencode/command/new-track.md
echo "--- seed-not-locked wording present ---"
grep -nE 'not the raw seed' .opencode/command/new-track.md
echo "--- renumbered steps 2-7 present, old numbering gone ---"
grep -nE '^## [2-7]\. ' .opencode/command/new-track.md
grep -nE '^## 1\. Track description$' .opencode/command/new-track.md && echo "FAIL: old step 1 heading remains" || echo "OK old heading gone"
echo "--- no-auto-start language present ---"
grep -nE 'Do not invoke `/implement` yourself' .opencode/command/new-track.md
```

Expected: every grep except the two explicitly marked "FAIL"/"OK" pair
finds at least one match; the old-heading check prints `OK old heading
gone`.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/new-track.md
git commit -m "Add zero-ambiguity per-feature brainstorming step to /new-track"
```

---

### Task 2: Log the addition in the parity ledger

**Files:**
- Modify: `docs/gemini-parity-gaps.md` — append one bullet to the "Port
  improvements over upstream (keep — do not regress)" section (current
  end of file).

**Interfaces:**
- Consumes: nothing.
- Produces: an honest record that this is net-new scope, not upstream
  parity — matching how `unbias` is already logged there.

- [ ] **Step 1: Read the current end of the file**

```bash
cd /Users/dt105/git/playground/conductor2
tail -n 10 docs/gemini-parity-gaps.md
```

Confirm the last line is:
```
- `unbias` contract in `skill/SKILL.md` — genuine addition, not in upstream.
```

- [ ] **Step 2: Append the new bullet**

Add this line immediately after the `unbias` bullet, at the end of the file:

```
- Zero-ambiguity per-feature brainstorming step in `/new-track` (see
  `docs/superpowers/specs/2026-08-19-new-track-brainstorming-design.md`) —
  genuine addition, not in upstream. Does not auto-invoke `/implement`.
```

- [ ] **Step 3: Verify**

```bash
cd /Users/dt105/git/playground/conductor2
grep -nE 'Zero-ambiguity per-feature brainstorming' docs/gemini-parity-gaps.md
```

Expected: one match, at the last line of the file.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add docs/gemini-parity-gaps.md
git commit -m "Log per-feature brainstorming step as a genuine addition in the parity ledger"
```

---

### Task 3: Behavioral fixture tests

**Files:**
- No source files modified — this task only runs live `opencode run`
  fixtures against the edited `.opencode/command/new-track.md` and
  reports pass/fail per scenario from the spec's test table.

**Interfaces:**
- Consumes: the finished `.opencode/command/new-track.md` from Task 1.
- Produces: a pass/fail record for each of the four scenarios; no
  artifacts land in this repo (all fixtures live under `/tmp` and are
  deleted at the end).

- [ ] **Step 1: Build the shared fixture skeleton**

```bash
FIXTURE=$(mktemp -d /tmp/conductor-brainstorm-fixture.XXXXXX)
mkdir -p "$FIXTURE/.opencode/command" "$FIXTURE/conductor"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/new-track.md .opencode/command/implement.md "$FIXTURE/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE/conductor/"
cd "$FIXTURE"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture"
echo "$FIXTURE" > /tmp/brainstorm_fixture_path.txt
echo "$FIXTURE"
```

- [ ] **Step 2: Scenario A — vague seed produces forks then an implementation-ready spec**

```bash
FIXTURE=$(cat /tmp/brainstorm_fixture_path.txt)
cd /Users/dt105/git/playground/conductor2
opencode run --command new-track "add caching" --format json --dir "$FIXTURE" > /tmp/brainstorm_scenarioA.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/brainstorm_scenarioA.json for the session id, continue with a follow-up opencode run \"<answer>\" --session <id> --dir \"$FIXTURE\" turn(s) answering each clarifying question until it finishes"; else echo FINISHED; fi
```

When prompted, answer the clarifying questions with real decisions (e.g.
what to cache, TTL, eviction policy, storage backend) rather than
deflecting, so this scenario tests the normal answer-every-fork path.
Continue issuing follow-up turns until the run reports the track is ready
and pauses for `/implement` approval.

```bash
cd "$FIXTURE"
echo "=== track dirs ==="
find conductor/tracks -maxdepth 1
TRACK_DIR=$(find conductor/tracks -maxdepth 1 -mindepth 1 -type d | head -1)
echo "=== spec.md placeholder scan ==="
grep -inE 'TBD|TODO' "$TRACK_DIR/spec.md" && echo "FAIL: placeholder found" || echo "OK none"
echo "=== provenance sections present ==="
grep -nE '^## Assumptions & agent-made decisions$' "$TRACK_DIR/spec.md"
grep -nE '^## Open questions auto-decided by agent' "$TRACK_DIR/spec.md"
```

Expected: exactly one track directory found; placeholder scan prints `OK
none`; both provenance section headers are present in `spec.md` (bullets
under them may be empty in this scenario since every fork was answered
directly).

- [ ] **Step 3: Scenario B — chained autonomy (the core property)**

Using the same `TRACK_DIR` produced in Step 2 (a fully-answered spec, no
auto-decisions), run `/implement` against it and confirm it does not stop
to ask the user anything:

```bash
FIXTURE=$(cat /tmp/brainstorm_fixture_path.txt)
TRACK_ID=$(basename "$(find "$FIXTURE/conductor/tracks" -maxdepth 1 -mindepth 1 -type d | head -1)")
cd /Users/dt105/git/playground/conductor2
opencode run --command implement "$TRACK_ID Use node's built-in test runner (node --test) for any backend-logic tasks. Do not ask me anything — if a phase-checkpoint confirmation is reached, that is an expected approval gate, reply yes to it yourself and continue; that is not the same as an ambiguity question. If you reach a point where you would need to ask a genuine content question (not a yes/no checkpoint), STOP and report exactly what you needed to ask instead of guessing." --format json --dir "$FIXTURE" > /tmp/brainstorm_scenarioB.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/brainstorm_scenarioB.json"; kill $BGPID; else echo FINISHED; fi
grep -ioE '[^.!?"\\]{5,}\?(\\n|")' /tmp/brainstorm_scenarioB.json | grep -viE 'phase.*checkpoint|does this meet expectations|shall i (proceed|continue)|(ready|ok|okay) to (proceed|continue)|sound good\??|look(s)? good\??|proceed\??$|continue\??$' && echo "FAIL: implement asked a genuine content question" || echo "OK: no unresolved content ambiguity surfaced"
```

Expected: `OK: no unresolved content ambiguity surfaced` — the only
questions `/implement` should raise, if any, are the existing
phase-checkpoint yes/no gates, not content ambiguity.

NOTE on this grep's role: this is a **secondary heuristic signal only**,
not the primary evidence for the scenario's pass/fail verdict. The
pattern above scans for sentence fragments ending in a literal `?`
inside the JSON-encoded transcript (matching either an escaped newline
or a closing quote right after the `?`, since `opencode run --format
json` emits one JSON object per line with prose embedded in string
fields — a bare `"(question|ask|clarify)"` token match, as used in an
earlier draft of this check, can never fire on natural-language prose
and was confirmed structurally unable to catch a real embedded
question during Task 3's execution). Even broadened, this grep can
still emit false positives (unanticipated checkpoint phrasing) or false
negatives (a genuine question that doesn't end in a literal `?`, e.g.
"Which do you want:"). The **primary evidence** for this scenario's
verdict must be a human (or subagent) reading the actual transcript
turn-by-turn and judging whether any turn raised a genuine unresolved
content question — the mechanical grep above is a quick triage aid to
point attention at candidate lines, not a substitute for that reading.
Record the manual read's conclusion explicitly in the task report even
when the grep prints `OK`.

- [ ] **Step 4: Scenario C — "exit brainstorming now" populates the double-check section**

```bash
FIXTURE2=$(mktemp -d /tmp/conductor-brainstorm-fixture2.XXXXXX)
mkdir -p "$FIXTURE2/.opencode/command" "$FIXTURE2/conductor"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/new-track.md "$FIXTURE2/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE2/conductor/"
cd "$FIXTURE2"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture"
echo "$FIXTURE2" > /tmp/brainstorm_fixture2_path.txt
opencode run --command new-track "add a notifications feature" --format json --dir "$FIXTURE2" > /tmp/brainstorm_scenarioC.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/brainstorm_scenarioC.json for the session id"; else echo FINISHED; fi
```

On the first clarifying question, answer normally once, then on the
second respond with exactly "exit brainstorming now" via a follow-up
`opencode run "exit brainstorming now" --session <id> --dir "$FIXTURE2"`
turn. Continue any remaining turns until the run completes.

```bash
cd "$FIXTURE2"
TRACK_DIR2=$(find conductor/tracks -maxdepth 1 -mindepth 1 -type d | head -1)
echo "=== double-check section populated ==="
awk '/^## Open questions auto-decided by agent/{flag=1;next} /^## /{flag=0} flag' "$TRACK_DIR2/spec.md" | grep -qE '\S' && echo "OK: section has content" || echo "FAIL: section empty despite exit"
echo "=== metadata.json review flag ==="
grep -nE '"needsReview":\s*true' "$TRACK_DIR2/metadata.json"
echo "=== registry entry flagged ==="
grep -nE 'needs review' conductor/tracks.md
```

Expected: `OK: section has content`; `needsReview` true in
`metadata.json`; the registry entry in `tracks.md` contains the "needs
review" label.

- [ ] **Step 5: Scenario D — skip hatch (regression guard)**

```bash
FIXTURE3=$(mktemp -d /tmp/conductor-brainstorm-fixture3.XXXXXX)
mkdir -p "$FIXTURE3/.opencode/command" "$FIXTURE3/conductor"
cd /Users/dt105/git/playground/conductor2
cp .opencode/command/new-track.md "$FIXTURE3/.opencode/command/"
cp conductor/index.md conductor/tracks.md conductor/workflow.md "$FIXTURE3/conductor/"
cd "$FIXTURE3"
git init -q && git config user.email t@t.com && git config user.name t
git add -A && git commit -q -m "seed fixture"
opencode run --command new-track "Skip brainstorming, spec is already decided: Add a health-check endpoint that returns 200 OK. Assume 1 phase, 1 backend-logic task called 'Add /health endpoint'. Proceed straight through to creating the artifacts, updating the registry, and committing." --format json --dir "$FIXTURE3" > /tmp/brainstorm_scenarioD.json 2>&1 &
BGPID=$!
sleep 90
if kill -0 $BGPID 2>/dev/null; then echo "STILL_RUNNING - inspect /tmp/brainstorm_scenarioD.json, may need a follow-up turn for the collision-check/registry question flow"; kill $BGPID; else echo FINISHED; fi
cd "$FIXTURE3"
git log --oneline
```

Expected: `git log --oneline` shows the `chore(conductor): initialize
track '...'` commit with no intervening clarifying-question turns needed
beyond what Task 3 of the Tier 1 fixture already established as normal
for this command (collision check, track-type confirmation) — i.e. no
brainstorming forks were raised.

- [ ] **Step 6: No-auto-start guard, across all scenarios**

```bash
for f in /tmp/brainstorm_fixture_path.txt /tmp/brainstorm_fixture2_path.txt; do
  FX=$(cat "$f" 2>/dev/null) || continue
  echo "=== $FX ==="
  (cd "$FX" && git log --oneline)
done
```

Expected: in every fixture except the one where Scenario B's `/implement`
run was deliberately executed, `git log --oneline` contains only
`/new-track`-originated commits (`chore(conductor): initialize track
'...'`) — no task-commit or phase-checkpoint commits, which would only
exist if `/implement` had run. Confirms `/new-track` never invoked
`/implement` on its own in any scenario.

- [ ] **Step 7: Clean up all fixtures**

```bash
for f in /tmp/brainstorm_fixture_path.txt /tmp/brainstorm_fixture2_path.txt /tmp/brainstorm_fixture3_path.txt; do
  FX=$(cat "$f" 2>/dev/null) && rm -rf "$FX"
done
rm -f /tmp/brainstorm_fixture*_path.txt /tmp/brainstorm_scenario*.json /tmp/newtrack_run.json 2>/dev/null
echo "cleanup done"
```

No commit for this task (no source files were changed).

---

## Self-Review Notes (completed during plan authoring)

- **Spec coverage:** §1 flow/seed-timing/skip-hatch → Task 1 Steps 1-2
  (new Step 1 + renumbered Step 2 wording). §2 dual exit gate → Task 1
  Step 2's numbered loop items 1-2. §3 per-fork model → Task 1 Step 2's
  loop item 3. §4 provenance sections → Task 1 Step 2's loop item 4 +
  Task 3's `spec.md` header content checks. §5 self-review → loop item 5.
  §6 two gates / no-auto-start → loop item 6 + renumbered Step 7's
  explicit "do not invoke `/implement`" sentence + Task 3 Step 6. Testing
  approach (Layer 1/2) → Task 1 Step 3 (static) + Task 3 (behavioral,
  covering all four table rows from the spec plus the no-auto-start guard).
- **Placeholder scan:** none found in this plan; every step has concrete
  commands/content, not "add appropriate X".
- **Type/format consistency:** the two provenance section header strings
  are copied verbatim identically in the spec, the Global Constraints
  section, Task 1's replacement file content, and Task 1's/Task 3's grep
  checks — confirmed character-for-character matching (including the em
  dash in the second header).
