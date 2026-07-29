# Always-Latest Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `install-latest.sh`, a single script that always installs the latest Conductor from GitHub — usable both as a `curl | bash` one-liner and as a local "update my machine" command — then document it in the README.

**Architecture:** `install-latest.sh` maintains a canonical clone at `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2`, clone-or-hard-syncs it to the requested ref, then runs the existing `install.sh` from a non-repo-root cwd. `install.sh` is unchanged. The README gets an "always latest" section.

**Tech Stack:** Bash, git, GitHub HTTPS clone, OpenCode command/skill discovery.

## Global Constraints

- Do NOT modify `install.sh`. It stays the copy-from-tree core with its repo-root guard.
- Defaults, each overridable via env var: `CONDUCTOR_REPO=https://github.com/dstran/conductor2.git`, `CONDUCTOR_REF=main`, clone dir `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2`.
- Clone URL is HTTPS by default (no SSH-key dependency).
- The cache clone is disposable: sync via `git fetch` + `git reset --hard origin/<ref>` so a dirty/diverged cache self-heals; never try to preserve local edits in the cache.
- `install-latest.sh` must run `install.sh` from a cwd that is NOT the clone root (satisfy install.sh's repo-root guard). Use `$HOME`.
- Use `set -e` and quote all paths.
- Change set: add `install-latest.sh` (executable); update `README.md`. Nothing else.

---

### Task 1: Create install-latest.sh

**Files:**
- Create: `install-latest.sh` (mode 755)

**Interfaces:**
- Consumes: the repo's existing `install.sh` (run from the cache clone).
- Produces: the `install-latest.sh` entry point used by both the curl one-liner and local updates. README (Task 2) documents its invocations and env vars: `CONDUCTOR_REPO`, `CONDUCTOR_REF`.

- [ ] **Step 1: Write `install-latest.sh` with exactly this content**

```bash
#!/bin/bash
# Fetch the latest Conductor from GitHub and install it.
#
# Usage (always latest):
#   curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh | bash
# or, from a local copy:
#   bash install-latest.sh
#
# Overridable via environment variables:
#   CONDUCTOR_REPO  git URL to clone   (default: https://github.com/dstran/conductor2.git)
#   CONDUCTOR_REF   branch/tag/ref     (default: main)
#   XDG_CACHE_HOME  cache base dir     (default: $HOME/.cache)

set -e

REPO="${CONDUCTOR_REPO:-https://github.com/dstran/conductor2.git}"
REF="${CONDUCTOR_REF:-main}"
CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}"
CLONE_DIR="$CACHE_BASE/conductor2"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but was not found on PATH." >&2
  exit 1
fi

echo "Fetching Conductor ($REF) from $REPO ..."

if [ -d "$CLONE_DIR/.git" ]; then
  git -C "$CLONE_DIR" remote set-url origin "$REPO"
  git -C "$CLONE_DIR" fetch --quiet origin
  git -C "$CLONE_DIR" checkout --quiet "$REF"
  git -C "$CLONE_DIR" reset --hard --quiet "origin/$REF"
else
  rm -rf "$CLONE_DIR"
  mkdir -p "$CACHE_BASE"
  git clone --quiet "$REPO" "$CLONE_DIR"
  git -C "$CLONE_DIR" checkout --quiet "$REF"
fi

SHA="$(git -C "$CLONE_DIR" rev-parse --short HEAD)"
echo "Synced to $REF ($SHA)."

# install.sh refuses to run from the repo root, so invoke it from $HOME.
( cd "$HOME" && bash "$CLONE_DIR/install.sh" )

echo "Installed Conductor from $REPO@$REF ($SHA)."
```

- [ ] **Step 2: Make it executable**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
chmod +x install-latest.sh
test -x install-latest.sh && echo "OK executable" || echo "FAIL not executable"
```

Expected: `OK executable`.

- [ ] **Step 3: Syntax-check the script**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
bash -n install-latest.sh && echo "OK syntax" || echo "FAIL syntax"
```

Expected: `OK syntax`.

- [ ] **Step 4: Fresh-clone install test (real remote, sandbox HOME + cache)**

This clones `origin/main` from GitHub (which already contains `install.sh` and the full surface) into a sandbox cache, then installs into a sandbox HOME. Run:

```bash
SANDBOX=/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/install-latest-verify
rm -rf "$SANDBOX"; mkdir -p "$SANDBOX/cache" "$SANDBOX/home"
HOME="$SANDBOX/home" XDG_CACHE_HOME="$SANDBOX/cache" \
  bash /Users/dt105/git/playground/conductor2/install-latest.sh
echo "--- cache clone present ---"; test -d "$SANDBOX/cache/conductor2/.git" && echo OK || echo FAIL
CMD="$SANDBOX/home/.config/opencode/command/conductor"
echo "--- 6 commands ---"; ls "$CMD"/*.md | wc -l | tr -d ' '
echo "--- 9 style guides ---"; ls "$CMD/assets/code_styleguides/"*.md | wc -l | tr -d ' '
echo "--- skill ---"; test -f "$SANDBOX/home/.config/opencode/skills/conductor/SKILL.md" && echo OK || echo FAIL
echo "--- no ~/.opencode ---"; [ -e "$SANDBOX/home/.opencode" ] && echo FAIL || echo OK
```

Expected: cache clone `OK`; command count `6`; guide count `9`; skill `OK`; `OK` no `~/.opencode`.

- [ ] **Step 5: Re-run (idempotent sync) test**

Run again against the SAME sandbox cache — it must sync the existing clone, not fail on clone-already-exists:

```bash
SANDBOX=/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/install-latest-verify
HOME="$SANDBOX/home" XDG_CACHE_HOME="$SANDBOX/cache" \
  bash /Users/dt105/git/playground/conductor2/install-latest.sh
echo "--- second run exit ok + still installed ---"
ls "$SANDBOX/home/.config/opencode/command/conductor"/*.md | wc -l | tr -d ' '
```

Expected: the script completes without error and command count is still `6`.

- [ ] **Step 6: Ref-override test**

Point at a real branch other than main and confirm the cache clone checks it out:

```bash
SANDBOX=/var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/install-latest-verify
HOME="$SANDBOX/home" XDG_CACHE_HOME="$SANDBOX/cache" CONDUCTOR_REF=always-latest-installer \
  bash /Users/dt105/git/playground/conductor2/install-latest.sh || echo "(ref may not be pushed yet — see note)"
echo "--- checked-out ref ---"
git -C "$SANDBOX/cache/conductor2" rev-parse --abbrev-ref HEAD
```

Expected: if the `always-latest-installer` branch is pushed to origin, HEAD is `always-latest-installer`. If it is NOT yet pushed, the fetch/checkout of that ref will fail — in that case this step is deferred; note it and re-run after the branch is pushed. (Steps 4-5 against `main` are the load-bearing checks.)

- [ ] **Step 7: Clean up the sandbox**

Run: `rm -rf /var/folders/7v/jgj55gd12n5438pdh778gt5mzf5y4m/T/opencode/install-latest-verify`

- [ ] **Step 8: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add install-latest.sh
git commit -m "Add install-latest.sh for always-latest installs from GitHub"
```

---

### Task 2: Document the always-latest installer in README

**Files:**
- Modify: `README.md` — insert a new section immediately before the existing `## Installation` heading (line 15).

**Interfaces:**
- Consumes: `install-latest.sh` (Task 1) and its env vars `CONDUCTOR_REF`, `CONDUCTOR_REPO`.
- Produces: user-facing docs for both install paths.

- [ ] **Step 1: Insert the new section before `## Installation`**

In `README.md`, immediately before this existing line (line 15):

```
## Installation
```

insert the following block (followed by a blank line, so the existing
`## Installation` heading remains intact right after it):

```
## Install / update (always latest)

Install or update to the latest version from GitHub with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh | bash
```

Run the same command again any time to update. It keeps a cache clone at
`~/.cache/conductor2` (honoring `$XDG_CACHE_HOME`), syncs it to the latest, and
runs the installer. Then restart your AI shell.

Overrides (environment variables):

- `CONDUCTOR_REF` — branch or tag to install (default `main`).
- `CONDUCTOR_REPO` — git URL to clone (default `https://github.com/dstran/conductor2.git`).

Prefer to inspect before running remote code? Download, read, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh -o install-latest.sh
less install-latest.sh
bash install-latest.sh
```

```

Note for the implementer: the inserted block contains fenced code blocks. When
editing the Markdown, make sure the triple-backtick fences inside the block are
written literally as-is so the section renders correctly, and that a blank line
separates the inserted block from the following `## Installation` heading.

- [ ] **Step 2: Retitle the existing manual section for clarity**

The existing `## Installation` section documents installing from a local clone.
Rename its heading so the two sections read as siblings. Replace the line:

```
## Installation
```

with:

```
## Install from a local clone
```

- [ ] **Step 3: Verify the README**

Run:

```bash
cd /Users/dt105/git/playground/conductor2
echo "--- always-latest section present ---"
grep -nE '## Install / update \(always latest\)' README.md
echo "--- one-liner present ---"
grep -nE 'install-latest\.sh \| bash' README.md
echo "--- env overrides documented ---"
grep -nE 'CONDUCTOR_REF|CONDUCTOR_REPO' README.md
echo "--- inspect-first alternative present ---"
grep -nE '-o install-latest\.sh' README.md
echo "--- local-clone section retitled, old heading gone ---"
grep -nE '^## Install from a local clone' README.md && (grep -nxE '## Installation' README.md && echo "FAIL old heading remains" || echo "OK old heading gone")
```

Expected: the always-latest heading, the one-liner, both env vars, and the inspect-first line all appear; the local-clone heading is present and the bare `## Installation` heading is gone.

- [ ] **Step 4: Commit**

```bash
cd /Users/dt105/git/playground/conductor2
git add README.md
git commit -m "Document always-latest installer in README"
```

---

## Self-Review

**Spec coverage:**
- New `install-latest.sh`, install.sh unchanged → Task 1 (creates script only). ✓
- git clone fetch; clone-or-hard-sync to origin/<ref>; run install.sh from `$HOME` → Task 1 Step 1 script body. ✓
- Defaults + env overrides `CONDUCTOR_REPO`/`CONDUCTOR_REF`, cache at `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2` → Task 1 Step 1. ✓
- Idempotent re-run + fresh clone + ref override verification → Task 1 Steps 4-6. ✓
- README always-latest section: one-liner, local run, env overrides, restart note, inspect-first alternative → Task 2 Step 1; keep the local-clone section (retitled) → Task 2 Step 2. ✓
- Change set exactly install-latest.sh + README → each task's Files + scope. ✓

**Placeholder scan:** No TBD/TODO/vague directives. Full script and README block are given verbatim; all verification commands are concrete. The Step 6 ref-override is explicitly conditional (deferred if the branch isn't pushed) rather than a placeholder. ✓

**Type consistency:** `CONDUCTOR_REPO`/`CONDUCTOR_REF`/`XDG_CACHE_HOME` and the clone dir `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2` are identical between the Global Constraints, the script body (Task 1), and the README (Task 2). The install-target assertions (6 commands, 9 guides, skill path, no `~/.opencode`) match the current installer surface. ✓
