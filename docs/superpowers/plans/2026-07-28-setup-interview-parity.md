# Setup Interview Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `.opencode/command/setup.md` into a faithful OpenCode port of the upstream Gemini `conductor-setup` interactive interview, and install the bundled `code_styleguides/` assets so `/setup` can copy them.

**Architecture:** `setup.md` is a command-doc prompt (no runtime code). It drives an interview using OpenCode's native `question` tool and an inline ``!`...` `` shell snippet for the resume check. The nine style-guide assets already live in-repo at `conductor/assets/code_styleguides/`; `install.sh` copies them to a fixed global path that `setup.md` reads from. The existing local 91-line `conductor/workflow.md` is the workflow content setup writes.

**Tech Stack:** Bash (install.sh), Markdown command docs, OpenCode command/skill discovery, OpenCode `question` tool, OpenCode ``!`...` `` shell-output syntax.

## Global Constraints

- Change scope is `/setup` and its assets only. Do NOT modify `/implement`, `/review`, `/new-track`, or `conductor/workflow.md` content.
- Setup writes the existing local 91-line task-type-enforcement `conductor/workflow.md`, never the upstream 442-line version.
- No `catalog.md` / agent-skill-selection step. No `resume.py` script.
- Style guides are copied, never invented. The nine bundled files are: `cpp.md`, `csharp.md`, `dart.md`, `general.md`, `go.md`, `html-css.md`, `javascript.md`, `python.md`, `typescript.md`.
- Fixed installed asset path: `~/.config/opencode/command/conductor/assets/code_styleguides/`.
- Installer must not run from the repo root (existing guard). Prior fix must stay intact: skill at `~/.config/opencode/skills/conductor/SKILL.md`, commands at `~/.config/opencode/command/conductor/*.md`, nothing under `~/.opencode/`.
- Commit message for setup completion inside the flow: `conductor(setup): Initialize project context and standards`.
- The `conductor/index.md` handshake written by setup uses relative links: Definition (`./product.md`, `./product-guidelines.md`, `./tech-stack.md`), Workflow (`./workflow.md`, `./code_styleguides/`), Tracks (`./tracks.md`, `./tracks/`).

---

### Task 1: Install the bundled style guides via install.sh

**Files:**
- Modify: `install.sh` (the `install_opencode_surface()` function, currently lines 24-39)
- Reference (already in-repo, do not recreate): `conductor/assets/code_styleguides/*.md`

**Interfaces:**
- Consumes: `$ROOT/conductor/assets/code_styleguides/*.md` (the nine bundled guides committed earlier).
- Produces: guides installed at `~/.config/opencode/command/conductor/assets/code_styleguides/`, which Task 2's `setup.md` reads from.

- [ ] **Step 1: Add the asset copy to `install_opencode_surface`**

Edit `install.sh`. The current function is:

```bash
install_opencode_surface() {
  # OpenCode discovers global skills under ~/.config/opencode/skills/<name>/SKILL.md
  # and global commands under ~/.config/opencode/command/**/*.md. Command names are
  # derived from the path after the "command/" prefix, so nesting under conductor/
  # exposes them as /conductor/<name>.
  local config="$HOME/.config/opencode"
  local skill_dir="$config/skills/conductor"
  local command_dir="$config/command/conductor"

  rm -rf "$skill_dir" "$command_dir"
  mkdir -p "$skill_dir" "$command_dir"
  cp "$ROOT/skill/SKILL.md" "$skill_dir/SKILL.md"
  cp "$ROOT"/.opencode/command/*.md "$command_dir/"
  echo "  $skill_dir"
  echo "  $command_dir (/conductor/*)"
}
```

Replace it with (adds an `assets_dir` under `command_dir` and copies the guides):

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

- [ ] **Step 2: Verify the installer lays down assets and preserves the prior fix**

Run (sandbox HOME, from a non-repo dir so the guard passes):

```bash
SANDBOX=/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/setup-install-verify
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX/run"
cd "$SANDBOX/run"
HOME="$SANDBOX" bash /Users/dt105/git/playground/conductor2/install.sh
echo "--- assets ---"; ls "$SANDBOX/.config/opencode/command/conductor/assets/code_styleguides/"
echo "--- guide count (expect 9) ---"; ls "$SANDBOX/.config/opencode/command/conductor/assets/code_styleguides/" | wc -l
echo "--- commands (expect 6) ---"; ls "$SANDBOX/.config/opencode/command/conductor/"*.md | wc -l
echo "--- skill ---"; ls "$SANDBOX/.config/opencode/skills/conductor/SKILL.md"
echo "--- must be absent ---"; [ -e "$SANDBOX/.opencode" ] && echo "FAIL ~/.opencode exists" || echo "OK no ~/.opencode"
```

Expected: 9 guides listed, guide count `9`, command count `6`, the skill path prints, and `OK no ~/.opencode`.

- [ ] **Step 3: Clean up the sandbox**

Run: `rm -rf /var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/setup-install-verify`

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add install.sh
git commit -m "Install bundled style guides for /setup"
```

---

### Task 2: Rewrite setup.md as the full interview

**Files:**
- Modify (full rewrite): `.opencode/command/setup.md`

**Interfaces:**
- Consumes: the installed asset path from Task 1 (`~/.config/opencode/command/conductor/assets/code_styleguides/`).
- Produces: the `/conductor/setup` command prompt. Downstream `/conductor/new-track`, `/conductor/implement`, `/conductor/review` rely on setup having produced `conductor/index.md`, `conductor/product.md`, `conductor/product-guidelines.md`, `conductor/tech-stack.md`, `conductor/tech-stack.md`, `conductor/workflow.md`, `conductor/code_styleguides/`, and `conductor/tracks.md`.

- [ ] **Step 1: Replace the entire contents of `.opencode/command/setup.md`**

Write exactly this file:

````markdown
---
description: Initialize the Conductor project through an interactive interview that audits the codebase, defines product/tech context, copies code style guides, writes the workflow, and builds the handshake index
agent: build
---

`/setup` is the first step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

You are the **Conductor Architect**. Initialize this project for spec-driven development by following this protocol precisely and sequentially. Treat the current working directory as the project root; never create or ask for a different project directory.

## Interaction rules (apply throughout)

- Ask questions ONE AT A TIME using the `question` tool. Wait for the answer before the next question.
- For every choice, list the recommended option first and label it `(Recommended)` with a brief reason. The tool already offers a "type your own" option; do not add an "Other" choice yourself.
- Before creating or modifying an infrastructure file, briefly explain its purpose (the "why"), then act.
- Use relative paths from the project root (e.g. `conductor/product.md`).
- Validate every tool call. On failure, self-correct once or halt and ask.

## 1. Audit and resume

Check which Conductor artifacts already exist:

!`for f in product.md product-guidelines.md tech-stack.md code_styleguides workflow.md index.md; do if [ -e "conductor/$f" ]; then echo "present: $f"; else echo "missing: $f"; fi; done`

- If `conductor/index.md` is present, the project is already initialized. Announce that and HALT.
- Otherwise, summarize what is already done and what is missing in plain language (do not mention this checklist's mechanics). Resume at the first missing artifact in this order: Product Definition, Product Guidelines, Technology Stack, Code Style Guides, Workflow. If nothing exists, start at Product Definition.

## 2. Maturity detection

Determine whether this is a Brownfield (existing) or Greenfield (new) project.

- **Brownfield indicators:** dependency manifests (`package.json`, `go.mod`, `requirements.txt`, `pom.xml`, `Cargo.toml`), source directories (`src/`, `app/`, `lib/`, `bin/`) with code, or a `.git` directory. If `.git` exists, run `git status --porcelain`; ignore changes under `conductor/`. If other uncommitted changes exist, warn: "You have uncommitted changes — consider committing or stashing before proceeding," then continue and classify as Brownfield.
- **Greenfield:** none of the above (ignoring `conductor/`, a clean `.git`, and `README.md`).

**If Brownfield:** ask permission for a read-only scan. On approval, analyze efficiently: use `git ls-files`, respect `.gitignore`, skip `node_modules`/`dist`/`build`, and read `README.md` plus manifests to infer the tech stack and architecture. Hold the findings in context.

**If Greenfield:** if there is no `.git`, run `git init`. Then ask an open question: "What do you want to build?" Hold the answer as the Initial Concept.

## 3. Product Definition (`conductor/product.md`)

1. Propose a project title and a one-paragraph summary from the Initial Concept (Greenfield) or the scan (Brownfield). Ask a Yes/No question confirming it captures their vision.
2. Ask a single-choice question: **Interactive** (a batched interview of up to 4 questions) or **Autogenerate** (draft standard best practices). `(Recommended)` Interactive for Greenfield.
3. Draft `product.md` (Overview, Vision, Target Users, Core Value). Present it and ask a single-choice question: **Approve**, **Revise**, or **Refine**. Loop until Approved.
4. On approval, create `conductor/` if needed and write `conductor/product.md`.

## 4. Product Guidelines (`conductor/product-guidelines.md`)

1. Ask a single-choice question: **Interactive** (ask about voice, tone, UX principles) or **Autogenerate**.
2. Draft the content; present it; ask **Approve** / **Revise** / **Refine**. Loop until Approved.
3. Write `conductor/product-guidelines.md`.

## 5. Technology Stack (`conductor/tech-stack.md`)

1. **Greenfield:** ask a single-choice question: **Interactive** (hand-pick components) or **Autogenerate** (recommend a standard stack for the goal). If Interactive, ask multiple-choice questions in turn for Language(s), Backend Framework(s), Frontend Framework(s), and Database.
   **Brownfield:** state the stack you inferred and ask a Yes/No question to confirm; if wrong, ask an open question for the correct stack.
2. Present the drafted stack; ask **Approve** / **Manual Edit** / **Refine**. Loop until Approved.
3. Write `conductor/tech-stack.md`.

## 6. Code Style Guides (`conductor/code_styleguides/`)

The bundled guides live at `~/.config/opencode/command/conductor/assets/code_styleguides/`. Available guides: `cpp`, `csharp`, `dart`, `general`, `go`, `html-css`, `javascript`, `python`, `typescript`.

1. Recommend the guides that match the confirmed tech stack (always include `general`). Do NOT invent style rules — only copy from the bundled assets.
2. Ask a multiple-choice question to confirm which guides to copy (Brownfield: confirm the matches and ask if more are needed; Greenfield: present the recommended set and allow hand-picking).
3. Copy each selected guide into `conductor/code_styleguides/`, e.g.:

   ```bash
   mkdir -p conductor/code_styleguides
   cp ~/.config/opencode/command/conductor/assets/code_styleguides/typescript.md conductor/code_styleguides/
   ```

4. Ask a Yes/No question whether to add custom rules. If yes, ask an open question for the rules and append them to the relevant copied guide(s).

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

## Manual review gate

`/implement` pauses at the end of every phase, presents a summary,
asks "does this meet expectations?", and only commits that phase's
checkpoint after an explicit yes (looping on feedback the same way
`/review` does, including the same 3rd-round nudge). Nothing beyond
a phase checkpoint is finalized without that.

Once all phases are checkpointed, `/implement` stops and hands off
to `/review` for the track-level pass: full test suite, style,
security, and plan compliance across the whole track. `/review` has
its own pause-and-ask gate before the final track-closure commit is
made.

## Commit strategy

- `/implement` makes one checkpoint commit per approved phase.
- `/review` makes the final approval-gated track closure commit after
  its full-track pass, including any review-loop fixes and the
  `tracks.md` move to complete.
- Commit messages stay short and clean: phase checkpoints use
  `conductor(checkpoint): Checkpoint end of Phase <N> - <title>`;
  review closure uses a concise `conductor(track): <title>` summary
  with the track ID.
- Attach the phase summary or full review report to the corresponding
  commit as a **git note**, not in the commit message body. This keeps
  `git log` readable while preserving a complete, auditable record.
- No checkpoint commit happens before the user has explicitly approved
  the current phase summary.
- No final closure commit happens before `/review` has run and the
  user has explicitly approved the current `review.md` after any
  correction loop.
```

## 8. Tracks registry (`conductor/tracks.md`)

If `conductor/tracks.md` is missing, create it with the standard registry skeleton (`# Tracks Registry` header plus empty `## Active`, `## Blocked`, and `## Completed` sections and the lifecycle-encoding notes). Do not add any track entries — `/new-track` owns those.

## 9. Handshake index (`conductor/index.md`)

Write `conductor/index.md` — the single source of truth later commands read:

```markdown
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

Integrity check: verify every linked file and directory above exists on disk. If any is missing, create or repair it before continuing.

## 10. Commit setup

Stage the `conductor/` directory and commit with the message `conductor(setup): Initialize project context and standards`.

## 11. Completion

Present a short summary of the initialized scaffolding, then ask a Yes/No question offering to plan the first track now with `/conductor/new-track`.
````

- [ ] **Step 2: Verify every path setup.md references is installer-produced or repo-relative**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- asset path referenced ---"
grep -n 'command/conductor/assets/code_styleguides' .opencode/command/setup.md
echo "--- conductor-relative artifacts referenced ---"
grep -nE 'conductor/(product|product-guidelines|tech-stack|workflow|tracks|index)\.md|conductor/code_styleguides' .opencode/command/setup.md | head
echo "--- no forbidden references (catalog / resume.py / 442-line workflow) ---"
grep -niE 'catalog|resume\.py' .opencode/command/setup.md && echo "FAIL forbidden ref found" || echo "OK none"
```

Expected: the asset path matches Task 1's install target; the conductor-relative artifacts all appear; `OK none` for forbidden references.

- [ ] **Step 3: Confirm the embedded workflow matches the repo's canonical workflow.md**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
# Extract the fenced workflow block from setup.md and diff against the canonical file.
awk '/^# Workflow$/{f=1} f{print} /No final closure commit happens/{if(f){exit}}' .opencode/command/setup.md > /tmp/setup_workflow.md
diff <(sed -n '1,91p' conductor/workflow.md) /tmp/setup_workflow.md && echo "OK workflow matches" || echo "REVIEW: differences above"
```

Expected: `OK workflow matches`. If differences appear, correct the embedded block in `setup.md` to match `conductor/workflow.md` verbatim, then re-run.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add .opencode/command/setup.md
git commit -m "Rewrite /setup as full interactive interview"
```

---

### Task 3: End-to-end install + surface verification

**Files:**
- No file changes. Verification only.

**Interfaces:**
- Consumes: the committed `install.sh` (Task 1) and `setup.md` (Task 2).
- Produces: confidence that a clean install exposes the full setup surface.

- [ ] **Step 1: Clean install into a sandbox HOME and assert the full surface**

```bash
SANDBOX=/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/setup-e2e-verify
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX/run"
cd "$SANDBOX/run"
HOME="$SANDBOX" bash /Users/dt105/git/playground/conductor2/install.sh
CMD="$SANDBOX/.config/opencode/command/conductor"
echo "--- setup.md installed ---"; test -f "$CMD/setup.md" && echo OK || echo FAIL
echo "--- 6 commands ---"; ls "$CMD"/*.md | wc -l
echo "--- 9 style guides ---"; ls "$CMD/assets/code_styleguides/"*.md | wc -l
echo "--- skill ---"; test -f "$SANDBOX/.config/opencode/skills/conductor/SKILL.md" && echo OK || echo FAIL
echo "--- no ~/.opencode ---"; [ -e "$SANDBOX/.opencode" ] && echo FAIL || echo OK
echo "--- gemini flavor still complete ---"; test -f "$SANDBOX/.gemini/extensions/conductor/SKILL.md" && echo OK || echo FAIL
```

Expected: `setup.md` OK, command count `6`, guide count `9`, skill OK, `OK` no `~/.opencode`, gemini OK.

- [ ] **Step 2: Clean up the sandbox**

Run: `rm -rf /var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/setup-e2e-verify`

- [ ] **Step 3: No commit**

This task changes no tracked files; nothing to commit.

---

## Self-Review

**Spec coverage:**
- Full interview parity (audit/resume, maturity, product, guidelines, tech-stack, styleguides, workflow, tracks, index, commit, completion) → Task 2 setup.md sections 1–11. ✓
- Keep local workflow.md → Task 2 section 7 embeds the 91-line content; Task 2 Step 3 diffs it against `conductor/workflow.md`. ✓
- Drop skill-catalog step → Task 2 Step 2 asserts no `catalog`/`resume.py` refs. ✓
- Bundle nine guides in-repo → committed earlier; Task 1 installs them; verified in Tasks 1 & 3. ✓
- Inline shell resume check → Task 2 section 1 uses ``!`...` ``. ✓
- Fixed installed asset path → Task 1 installs to it, Task 2 reads from it, Task 2 Step 2 asserts they match. ✓
- Install wiring + prior fix intact → Task 1 Step 2 and Task 3 Step 1 assert skill/commands present and no `~/.opencode`. ✓

**Placeholder scan:** No TBD/TODO/"handle edge cases". All file content is given verbatim; all verification commands are concrete. ✓

**Type consistency:** The asset path `~/.config/opencode/command/conductor/assets/code_styleguides/` is identical in Task 1 (install target), Task 2 (setup.md reads it), and Task 2 Step 2 (assertion). The nine guide names match the spec and the in-repo files. ✓
