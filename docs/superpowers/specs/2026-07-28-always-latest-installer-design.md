# Always-Latest Installer (`install-latest.sh`) — Design

## Goal

Provide a single command that always installs the latest Conductor from
GitHub, serving two paths from one script:

- **Path A (newcomer / one-liner):** `curl -fsSL <raw-url>/install-latest.sh | bash`
- **Path B (keeping your own machines current):** run the same script locally;
  each run pulls latest and reinstalls.

## Background

`install.sh` copies from the directory it lives in (`ROOT`) and refuses to run
from the repository root. It therefore only installs whatever a local clone
currently contains — it has no notion of "latest from GitHub." Getting latest
today requires a manual `git pull` followed by running `install.sh` from
outside the repo.

## Architecture

Add one new script, `install-latest.sh`, checked into the repo. It maintains a
canonical clone, syncs it to the requested ref, and delegates to the existing
`install.sh`. `install.sh` is unchanged — it remains the pure "copy from this
tree" core with its repo-root guard. `install-latest.sh` is a thin wrapper that
arranges a fresh source tree and then calls it.

Both paths use the same code:

- Path A pipes `install-latest.sh` from the raw GitHub URL into `bash`.
- Path B runs the same script locally (optionally via a shell alias).

## Decisions

1. **Fetch via `git clone`** (not tarball). Requires git, which is reasonable
   for a dev tool and reuses one code path for both A and B.
2. **One script** (`install-latest.sh`) maintaining a persistent canonical
   clone. No separate bootstrap/update scripts.
3. **Clone location:** `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2`. Disposable
   cache, not a workspace.
4. **Ref:** tracks `main` by default, overridable via `CONDUCTOR_REF`.
5. **Clone URL:** HTTPS `https://github.com/dstran/conductor2.git` by default
   (no SSH-key dependency for the newcomer path), overridable via
   `CONDUCTOR_REPO`.

## `install-latest.sh` behavior

1. Resolve configuration with env-var overrides and defaults:
   - `CONDUCTOR_REPO` → `https://github.com/dstran/conductor2.git`
   - `CONDUCTOR_REF` → `main`
   - clone dir → `${XDG_CACHE_HOME:-$HOME/.cache}/conductor2`
2. Verify `git` is available; if not, print a clear error and exit non-zero.
3. Clone-or-sync the canonical clone:
   - If the clone dir does not exist (or is not a git repo): `git clone <repo> <dir>`.
   - If it exists: `git fetch origin`, then hard-sync to the requested ref
     (`git checkout <ref>` and `git reset --hard origin/<ref>`), so a dirty or
     diverged cache self-heals rather than failing a `pull`.
4. Run `<clone>/install.sh` from a working directory that is NOT the clone root
   (to satisfy install.sh's existing repo-root guard). Use a stable, safe cwd
   such as `$HOME`.
5. Print a short summary: repo, ref, resolved commit SHA, and the existing
   "Restart your AI shell" note.

The script uses `set -e` (like `install.sh`) and quotes all paths.

## Idempotency & safety

- The cache clone is disposable: any local mess is discarded via
  `git reset --hard origin/<ref>`. The script never tries to preserve local
  edits in the cache.
- `install.sh` already `rm -rf`s its install targets before copying, so
  re-running produces a clean install with no stale files.
- HTTPS + public read means no SSH-key dependency for the newcomer path.
- The curl | bash path executes remote code; the README documents this plainly
  and offers a "download and inspect first" alternative.

## README changes

Add an "Install / update (always latest)" section documenting:

- The Path A one-liner:
  `curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh | bash`
- The Path B local invocation (run the script; optional shell-alias hint).
- The env-var overrides: `CONDUCTOR_REF` (default `main`) and `CONDUCTOR_REPO`
  (default the HTTPS URL).
- The "Restart your AI shell" step.
- A "prefer to inspect first?" alternative: `curl -o install-latest.sh <url>`,
  read it, then `bash install-latest.sh`.

Keep the existing "install from a local clone" (`install.sh`) section.

## What stays unchanged

- `install.sh` — no changes; it remains the copy-from-tree core with its
  repo-root guard.
- All installed surfaces and per-tool target paths.

## Non-Goals

- No uninstaller.
- No automatic shell-alias installation (README shows how, optionally).
- No tarball fetch path (git clone only).
- No change to what gets installed or where.

## Verification

Because the script fetches from GitHub, verify against the real remote using a
sandbox `HOME` and a sandbox cache dir (via `XDG_CACHE_HOME`):

1. **Fresh clone:** empty cache dir → run → assert the clone appears at the
   cache dir and the OpenCode surface installs (skill at
   `~/.config/opencode/skills/conductor/SKILL.md`, 6 commands under
   `~/.config/opencode/command/conductor/`, 9 style guides under
   `assets/code_styleguides/`, and nothing under `~/.opencode/`).
2. **Re-run:** run again against the existing cache → assert it syncs the
   existing clone (no clone-already-exists failure) and reinstalls cleanly.
3. **Ref override:** `CONDUCTOR_REF=<a-real-branch>` → assert the cache clone is
   checked out at that ref.
4. **Repo-root guard:** confirm `install.sh` runs successfully (the wrapper
   invokes it from a non-root cwd).
