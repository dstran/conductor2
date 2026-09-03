---
description: Sync conductor/workflow.md with the currently installed Conductor doctrine, if it has changed since /setup ran
agent: build
---

@conductor/workflow.md

`/conductor/update` keeps `conductor/workflow.md` in sync with whatever
Conductor doctrine is currently installed. It touches only
`conductor/workflow.md` — `product.md`, `tech-stack.md`, `product-guidelines.md`,
`conductor/tracks/`, and `conductor/code_styleguides/` are never read or
modified by this command.

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
  existed), treat the target as having no marker.
  **A missing marker on the target always counts as stale** — never
  treat it as an error or ask a different question than the stale-path
  below.

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
