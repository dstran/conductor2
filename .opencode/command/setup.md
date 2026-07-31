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

## 8. Tracks registry (`conductor/tracks.md`)

If `conductor/tracks.md` is missing, create it with the standard registry skeleton (`# Tracks Registry` header plus empty `## Active` and `## Blocked` sections and the lifecycle-encoding notes). Do not add any track entries — `/new-track` owns those.

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
