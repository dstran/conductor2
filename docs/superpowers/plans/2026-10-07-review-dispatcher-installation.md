# Review Dispatcher Installation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the review-request dispatcher available after curl installation,
copy it into new projects, and let existing projects use the installed copy
without rerunning `/conductor/setup`.

**Architecture:** `install.sh` publishes the runtime dispatcher as an
OpenCode asset at `~/.config/opencode/command/conductor/assets/scripts/`.
`/conductor/setup` copies that asset into a project-local
`conductor/scripts/` directory only when the project copy is absent.
`/conductor/review` prefers the project-local copy and falls back to the
installed asset, so existing projects are repaired by reinstalling Conductor.
The test harness remains repository-only, and `/conductor/update` remains
workflow-only.

**Tech Stack:** Bash installer, POSIX shell dispatcher, Markdown command
instructions, Git, sandbox `HOME` verification.

## Global Constraints

- Make `open-pr.sh` available after the standard curl installation.
- Make new projects receive a project-local dispatcher during `/conductor/setup`.
- Make existing projects work after reinstalling Conductor without requiring
  `/conductor/setup` to be rerun.
- Preserve a project-local dispatcher when one already exists.
- Keep the test harness `test-open-pr.sh` repository-only.
- Preserve `/conductor/update`'s workflow-only responsibility.
- Do not change provider detection, fallback output, or dispatcher behavior.
- Do not overwrite an existing project-local `conductor/scripts/open-pr.sh`.
- Do not change Gemini's existing recursive package behavior.
- `install-latest.sh` remains unchanged; it already clones the full repository
  and invokes `install.sh`.
- The OpenCode runtime asset path is exactly
  `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`.
- `update.md` remains unchanged and continues to state that only
  `conductor/workflow.md` is modified.

---

## File Structure

- Modify: `install.sh` — create the OpenCode scripts asset directory and copy
  only `conductor/scripts/open-pr.sh` into it.
- Modify: `.opencode/command/setup.md` — copy the installed dispatcher into a
  new project only when `conductor/scripts/open-pr.sh` is missing.
- Modify: `.opencode/command/review.md` — resolve the project-local dispatcher
  first, then the installed fallback, and report an explicit missing-install
  error if neither exists.
- Verify: `conductor/scripts/open-pr.sh` — behavior remains unchanged.
- Verify: `conductor/scripts/test-open-pr.sh` — remains a source test harness
  and is not installed into OpenCode's runtime asset directory.
- Do not modify: `.opencode/command/update.md`, `install-latest.sh`, or the
  Gemini/Claude/Codex/Antigravity installation branches.

There are no new test files. The installer is verified with a sandbox `HOME`,
the dispatcher with its existing shell harness, and the command documents with
focused text checks and `git diff --check`.

---

### Task 1: Install the Runtime Dispatcher Asset

**Files:**
- Modify: `install.sh:24-47`, `install_opencode_surface`
- Verify: `conductor/scripts/open-pr.sh`
- Verify: `conductor/scripts/test-open-pr.sh`

**Interfaces:**
- Consumes: source runtime script at
  `conductor/scripts/open-pr.sh`.
- Produces: installed runtime script at
  `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`.
- Does not produce: an installed `test-open-pr.sh` file.

- [ ] **Step 1: Write the failing sandbox assertion**

Run this from the worktree, from a directory outside the repository so the
installer's repo-root guard passes:

```bash
SANDBOX="${TMPDIR:-/tmp}/conductor-dispatcher-install"
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX/run"
cd "$SANDBOX/run"
HOME="$SANDBOX/home" bash \
  /Users/dt105/git/playground/conductor2/.worktrees/fix-embedded-host-code-doctrine/install.sh
test -f "$SANDBOX/home/.config/opencode/command/conductor/assets/scripts/open-pr.sh"
```

Expected: FAIL at `test -f` because the current installer does not copy the
dispatcher asset. Do not treat the installer output alone as a passing test.

- [ ] **Step 2: Add the scripts asset directory and copy**

In `install_opencode_surface`, add this local variable after
`styleguides_dir`:

```bash
local scripts_dir="$command_dir/assets/scripts"
```

Extend the existing `mkdir` command so it creates `"$scripts_dir"`:

```bash
mkdir -p "$skill_dir" "$command_dir" "$styleguides_dir" "$scripts_dir"
```

After the existing style-guide copy, add:

```bash
cp "$ROOT/conductor/scripts/open-pr.sh" "$scripts_dir/open-pr.sh"
```

Do not copy `test-open-pr.sh`. Do not change the Gemini branch, which already
copies the full `conductor/` tree.

- [ ] **Step 3: Run syntax and sandbox installation checks**

Run:

```bash
cd /Users/dt105/git/playground/conductor2/.worktrees/fix-embedded-host-code-doctrine
bash -n install.sh

SANDBOX="${TMPDIR:-/tmp}/conductor-dispatcher-install"
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX/run" "$SANDBOX/home"
INSTALLER="$PWD/install.sh"
( cd "$SANDBOX/run" && HOME="$SANDBOX/home" bash "$INSTALLER" )

INSTALLED="$SANDBOX/home/.config/opencode/command/conductor/assets/scripts"
test -f "$INSTALLED/open-pr.sh"
cmp conductor/scripts/open-pr.sh "$INSTALLED/open-pr.sh"
test ! -e "$INSTALLED/test-open-pr.sh"
```

Expected: every command exits 0. `cmp` proves the installed dispatcher is
byte-identical to the source; the final assertion proves the test harness was
not included in the runtime payload.

- [ ] **Step 4: Clean up the sandbox**

Run:

```bash
rm -rf "${TMPDIR:-/tmp}/conductor-dispatcher-install"
```

- [ ] **Step 5: Verify only installer changes are present**

Run:

```bash
git diff --check
git diff -- install.sh
```

Expected: the diff only adds `scripts_dir`, includes it in `mkdir -p`, and
copies `open-pr.sh`; no existing copy destinations or Gemini behavior change.

- [ ] **Step 6: Commit**

```bash
git add install.sh
GIT_AUTHOR_EMAIL="3491979+dstran@users.noreply.github.com" \
GIT_COMMITTER_EMAIL="3491979+dstran@users.noreply.github.com" \
git commit -m "feat(installer): install review dispatcher asset"
```

Verify the commit identity immediately:

```bash
git log -1 --format='%an <%ae> / %cn <%ce>'
```

Expected: both author and committer use
`3491979+dstran@users.noreply.github.com`.

---

### Task 2: Copy the Dispatcher During New-Project Setup

**Files:**
- Modify: `.opencode/command/setup.md` — insert a new section after the code
  style guide section and before the workflow section.

**Interfaces:**
- Consumes: installed asset at
  `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`.
- Produces: project-local `conductor/scripts/open-pr.sh` when that file is
  missing.
- Preserves: an existing project-local dispatcher and all existing setup
  scaffolding behavior.

- [ ] **Step 1: Write the failing documentation assertion**

Run:

```bash
grep -n "assets/scripts/open-pr.sh" .opencode/command/setup.md
```

Expected: no output and exit status 1 because setup currently has no
dispatcher-copy instructions.

- [ ] **Step 2: Add the dispatcher setup section**

Insert a new section between the existing `## 6. Code Style Guides` section
and `## 7. Workflow` section. The section must communicate this exact
behavior:

```markdown
## 7. Review dispatcher (`conductor/scripts/open-pr.sh`)

The installed review-request dispatcher lives at
`~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`. It is needed
by `/conductor/review` only when a track has both `branch` and `baseBranch`
metadata and reaches Archive cleanup.

If `conductor/scripts/open-pr.sh` is missing, verify that the installed asset
exists. If it is missing too, tell the user to rerun the Conductor installer
and halt setup. Otherwise create the project directory and copy the asset:

```bash
mkdir -p conductor/scripts
cp ~/.config/opencode/command/conductor/assets/scripts/open-pr.sh \
  conductor/scripts/open-pr.sh
```

If `conductor/scripts/open-pr.sh` already exists, leave it unchanged.
```

Renumber the existing workflow and following section headings so the document
remains sequential. Keep the existing workflow copy command byte-for-byte
unchanged.

- [ ] **Step 3: Verify setup instructions and preservation rule**

Run:

```bash
grep -n "Review dispatcher\|assets/scripts/open-pr.sh\|If.*already exists\|leave it unchanged" \
  .opencode/command/setup.md
grep -n "cp ~/.config/opencode/command/conductor/assets/workflow-template.md conductor/workflow.md" \
  .opencode/command/setup.md
```

Expected: the first command finds the new section, installed asset path, and
preservation instruction; the second still finds the original workflow copy
command. Verify by inspection that the new instructions say to stop when the
installed asset is unavailable and never overwrite the project-local copy.

- [ ] **Step 4: Verify the setup section does not alter index scaffolding**

Run:

```bash
grep -n "## 10. Handshake index\|Code Style Guides\|Tracks Directory" \
  .opencode/command/setup.md
git diff --check
```

Expected: the existing index links and integrity-check section remain present,
and `git diff --check` is clean. The dispatcher is not added as an index link.

- [ ] **Step 5: Commit**

```bash
git add .opencode/command/setup.md
GIT_AUTHOR_EMAIL="3491979+dstran@users.noreply.github.com" \
GIT_COMMITTER_EMAIL="3491979+dstran@users.noreply.github.com" \
git commit -m "feat(setup): copy review dispatcher into new projects"
```

Verify the new commit's author and committer are both the noreply address
before continuing.

---

### Task 3: Add the Installed Fallback to Review

**Files:**
- Modify: `.opencode/command/review.md:145-169`
- Do not modify: `.opencode/command/update.md`

**Interfaces:**
- Consumes: project-local dispatcher at
  `conductor/scripts/open-pr.sh` when present; otherwise installed asset at
  `~/.config/opencode/command/conductor/assets/scripts/open-pr.sh`.
- Produces: the same four dispatcher arguments — `<branch>`, `<baseBranch>`,
  track description, and temporary review-body file — with the existing
  Archive-only gate and cleanup behavior.

- [ ] **Step 1: Write the failing fallback assertions**

Run:

```bash
grep -q "assets/scripts/open-pr.sh" .opencode/command/review.md
grep -q "rerun the Conductor installer" .opencode/command/review.md
```

Expected: FAIL with exit status 1 because the installed fallback path and
explicit missing-install behavior are absent; the current text only invokes
`conductor/scripts/open-pr.sh`.

- [ ] **Step 2: Replace the direct invocation with path resolution**

Keep the existing temporary body-file creation/removal instructions and the
Archive-only placement. Replace the direct invocation with instructions
equivalent to this shell logic:

```bash
dispatcher=conductor/scripts/open-pr.sh
if [ ! -f "$dispatcher" ]; then
  dispatcher="$HOME/.config/opencode/command/conductor/assets/scripts/open-pr.sh"
fi
if [ ! -f "$dispatcher" ]; then
  echo "Conductor review dispatcher is missing; rerun the Conductor installer." >&2
  exit 1
fi
sh "$dispatcher" "<branch>" "<baseBranch>" "<track description>" \
  "<temporary-body-file>"
```

The actual command documentation must retain `$ARGUMENTS` and recorded
metadata values rather than literal angle-bracket placeholders. State the
resolution order in prose: project-local first, installed asset second. Keep
the complete dispatcher output-reporting requirement, the existing cleanup
of the temporary body file even on failure, and the existing behavior that
missing `branch`/`baseBranch` skips request creation.

- [ ] **Step 3: Verify existing review invariants**

Run:

```bash
grep -n "Archive\|Delete\|Skip\|branch\|baseBranch\|never merges\|assets/scripts/open-pr.sh\|conductor/scripts/open-pr.sh" \
  .opencode/command/review.md
```

Expected: the review command still limits request creation to Archive,
preserves Delete/Skip behavior, checks both metadata fields, states that
Conductor never merges, and contains both dispatcher paths. Verify by
inspection that the project-local path is checked first.

- [ ] **Step 4: Confirm `/conductor/update` is unchanged**

Run:

```bash
git diff -- .opencode/command/update.md
grep -n "only.*conductor/workflow.md\|only ever reads and writes" \
  .opencode/command/update.md
```

Expected: no diff output and the workflow-only contract remains documented.

- [ ] **Step 5: Commit**

```bash
git add .opencode/command/review.md
GIT_AUTHOR_EMAIL="3491979+dstran@users.noreply.github.com" \
GIT_COMMITTER_EMAIL="3491979+dstran@users.noreply.github.com" \
git commit -m "fix(review): fall back to installed dispatcher"
```

Verify the new commit's author and committer are both the noreply address.

---

## Final Verification

- [ ] **Step 1: Run dispatcher and syntax checks**

```bash
sh conductor/scripts/test-open-pr.sh
sh -n conductor/scripts/open-pr.sh conductor/scripts/test-open-pr.sh
bash -n install.sh
```

Expected: the dispatcher harness prints `PASS: open-pr dispatcher tests`,
both shell scripts pass syntax checking, and the installer has no syntax
errors.

- [ ] **Step 2: Run the fresh sandbox installation check**

```bash
SANDBOX="${TMPDIR:-/tmp}/conductor-dispatcher-final"
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX/run" "$SANDBOX/home"
INSTALLER="$PWD/install.sh"
( cd "$SANDBOX/run" && HOME="$SANDBOX/home" bash "$INSTALLER" )

INSTALLED="$SANDBOX/home/.config/opencode/command/conductor"
test -f "$INSTALLED/assets/scripts/open-pr.sh"
cmp conductor/scripts/open-pr.sh "$INSTALLED/assets/scripts/open-pr.sh"
test ! -e "$INSTALLED/assets/scripts/test-open-pr.sh"
```

Expected: all assertions pass. The runtime dispatcher is installed, byte
identical to source, and the test harness is absent.

- [ ] **Step 3: Verify setup/review wiring and update boundary**

```bash
grep -n "assets/scripts/open-pr.sh" .opencode/command/setup.md .opencode/command/review.md
grep -n "conductor/scripts/open-pr.sh" .opencode/command/setup.md .opencode/command/review.md
git diff -- .opencode/command/update.md
```

Expected: both command files contain the installed asset path and project
path; `update.md` has no diff.

- [ ] **Step 4: Verify no unrelated files, whitespace errors, or leaked author email**

```bash
git diff --check HEAD~3..HEAD
git status --short
git log main..HEAD --format='%H %an <%ae> / %cn <%ce>'
```

Expected: no whitespace errors, only the intended worktree changes are
present (or a clean tree after commits), and every new commit shows
`3491979+dstran@users.noreply.github.com` for both author and committer.

- [ ] **Step 5: Clean up the sandbox**

```bash
rm -rf "${TMPDIR:-/tmp}/conductor-dispatcher-final"
```

- [ ] **Step 6: Push the follow-up commits to PR #18**

```bash
git push
```

Expected: the existing PR #18 updates without force-push or history rewrite.
