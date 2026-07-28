# Full-Parity `/setup` Interview — Design

## Goal

Rewrite `.opencode/command/setup.md` from a 21-line "create these files" stub
into a faithful OpenCode port of the upstream Gemini `conductor-setup` skill's
interactive interview. Bundle upstream's nine `code_styleguides/` assets in the
repo and install them so `/setup` can copy the matching ones. Keep the existing
local `workflow.md`. Drop the Gemini Firebase/GCP agent-skill-selection step.

## Background

Upstream `conductor-setup` (241-line state machine) drives project
initialization through a strict, interactive, one-question-at-a-time interview.
The current local `/setup` only tells the agent to create/refresh a list of
files and pause once — none of the audit, mode selection, or refinement loops.

Verified reference material (upstream clone):
- `skills/conductor-setup/SKILL.md` (241 lines) — the flow being ported.
- `skills/conductor-setup/scripts/resume.py` (54 lines) — trivial "which
  artifact is missing" check; reproduced inline, no script shipped.
- `skills/conductor-setup/assets/code_styleguides/*.md` — nine guides
  (cpp, csharp, dart, general, go, html-css, javascript, python, typescript).
- `skills/conductor-setup/assets/workflow.md` (442 lines) — generic TDD doc,
  NOT adopted (see Decisions).
- `assets/catalog.md` + SKILL §2.6 — Firebase/GCP skill selection, dropped.

## Decisions

1. **Full interview parity.** Port the audit, maturity detection, per-artifact
   Interactive/Autogenerate modes, refinement loops, integrity check, and
   commit.
2. **Keep local `workflow.md`.** Setup writes the existing local 91-line
   task-type-enforcement `conductor/workflow.md` when it is missing, not the
   upstream 442-line generic version. `/implement` and `/review` already depend
   on the local workflow's task-type tags and phase-checkpoint model.
3. **Drop the agent-skill-selection step.** No `catalog.md`, no §2.6. It is
   Gemini-ecosystem plumbing (curl Firebase/GCP skills into `.agents/skills/`)
   irrelevant to an OpenCode port.
4. **Bundle the nine style guides in-repo** and install them; setup copies from
   a fixed installed path.
5. **No `resume.py`.** The agent performs the missing-artifact check inline via
   file reads.

## Interview Flow (setup.md contract)

`/setup` uses OpenCode's native `question` tool for every single/multi-choice
prompt. Each question lists the recommended option first (labeled
"(Recommended)"); the tool supplies the "type your own" affordance. Questions
are asked one at a time.

1. **Audit & resume.** Check existence of `conductor/{product.md,
   product-guidelines.md, tech-stack.md, code_styleguides/, workflow.md,
   tracks.md, index.md}`.
   - If `index.md` exists: announce the project is already initialized and HALT.
   - If partial: summarize done/missing in human-readable terms (no section
     numbers) and resume at the first missing artifact in the chain
     product → product-guidelines → tech-stack → code_styleguides → workflow.
2. **Maturity detection.**
   - Brownfield indicators: dependency manifests (`package.json`, `go.mod`,
     `requirements.txt`, `pom.xml`, `Cargo.toml`), source dirs, or a `.git`
     with uncommitted non-`conductor/` changes (warn, then proceed).
   - Greenfield: none of the above. `git init` if no `.git`; ask "What do you
     want to build?" and hold the answer as the Initial Concept.
   - Brownfield scan is read-only, asks permission first, respects `.gitignore`,
     and skips heavy dirs (`node_modules`, `dist`, `build`).
3. **`product.md`.** Refine a proposed title + one-paragraph summary; choose
   Interactive (batched interview, max ~4 questions) or Autogenerate; then an
   Approve/Revise/Refine loop; write the file (create `conductor/` if missing).
4. **`product-guidelines.md`.** Interactive or Autogenerate; Approve/Revise/
   Refine loop; write the file.
5. **`tech-stack.md`.** Greenfield: interactive stack picker (language,
   backend, frontend, database) or Autogenerate. Brownfield: state the inferred
   stack and confirm. Approve/Manual-edit/Refine loop; write the file.
6. **`code_styleguides/`.** Recommend guides matching the confirmed tech stack.
   Copy the matching files from the installed asset path
   `~/.config/opencode/command/conductor/assets/code_styleguides/` into
   `conductor/code_styleguides/`. Never invent style rules — copy only. Then
   offer optional custom-rule additions (upstream §2.4.4): the agent may append
   user-provided rules to the copied guides.
7. **`workflow.md`.** If `conductor/workflow.md` is missing, write the local
   91-line task-type-enforcement workflow content. Explain its purpose before
   writing.
8. **`tracks.md`.** Ensure the registry file exists (create the empty
   Active/Blocked/Completed skeleton if missing).
9. **Handshake `index.md`.** Write the index with Definition (product,
   product-guidelines, tech-stack), Workflow (workflow, code_styleguides), and
   Tracks (tracks registry, tracks directory) link sections. Integrity check:
   verify every linked file/dir exists on disk.
10. **Commit.** Stage `conductor/` and commit
    `conductor(setup): Initialize project context and standards`.
11. **Completion.** Present a summary and offer to run `/conductor/new-track`.

## Asset Bundling & Install Wiring

- Style guides live in-repo at `conductor/assets/code_styleguides/*.md` (the
  nine upstream files, copied verbatim).
- Extend `install_opencode_surface()` in `install.sh` to copy that tree to the
  fixed path `~/.config/opencode/command/conductor/assets/code_styleguides/`,
  recreating it cleanly on each run alongside the command docs and skill.
- `setup.md` references that fixed absolute path when copying guides.
- The Gemini flavor (`install_gemini_flavor`) already recursively copies
  `$ROOT/.opencode` and `$ROOT/conductor`, so the assets ride along there
  automatically. Claude/Codex/Antigravity are skill-only and unaffected.

## Non-Goals

- No `catalog.md` / agent-skill-selection step.
- No `resume.py` script.
- Not adopting upstream's 442-line `workflow.md`.
- No changes to `/implement`, `/review`, or `/new-track` doctrine.
- Not implementing the review archive step (separate track).

## Verification

1. Read-through of `setup.md` confirming the flow matches the upstream section
   order and every path it references is one the installer produces.
2. Run `install.sh` into a sandbox `HOME`; assert:
   - The nine guides exist at
     `~/.config/opencode/command/conductor/assets/code_styleguides/`.
   - The prior fix still holds: skill at
     `~/.config/opencode/skills/conductor/SKILL.md`, commands at
     `~/.config/opencode/command/conductor/*.md`, nothing under `~/.opencode/`.
   - Claude/Codex/Gemini/Antigravity targets still produced.
3. Confirm `conductor/assets/code_styleguides/` contains the nine files in-repo.
