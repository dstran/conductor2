# Standalone Track Archive Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic `/conductor/archive` recovery command that synchronizes and pushes a track branch, archives the track safely, and pushes the archive commit.

**Architecture:** Put the safety-critical Git/filesystem logic in a project-local Python 3 script so JSON, canonical paths, rollback state, and Git results are handled deterministically. Keep `.opencode/command/archive.md` as the OpenCode-facing wrapper and documentation, and install the script alongside the existing `open-pr.sh` asset. Test the script against temporary bare remotes and cloned worktrees.

**Tech Stack:** Python 3 standard library, Git CLI, POSIX shell test harness, Markdown command/docs.

**Spec:** `docs/superpowers/specs/2026-11-06-standalone-archive-command-safety-design.md`

## Global Constraints

- Run from the track's own worktree and branch; do not use a base-branch archive path.
- Accept metadata statuses `complete` and `awaiting-review`; treat `in-progress` and `blocked` as hard stops.
- Synchronize with the configured remote tracking branch using fast-forward-only behavior; never force-push, reset, rebase, or merge divergent history.
- Push local implementation commits before archiving and push the archive commit afterward.
- Move `conductor/tracks/<track_id>/` to `conductor/archive/<track_id>/` as one directory move.
- Update archived metadata to `"status": "archived"` and refresh `updatedAt`.
- Commit exactly `chore(conductor): Archive track '<track_id>'`.
- Preserve unrelated files and reject symlink/path escapes.
- Support `--dry-run`, `--apply`, and `--resume-push`; `--resume-push` must never repeat the move.

## Review Focus

- A remote-ahead branch must fast-forward only, then re-run validation before mutation. Test in Task 2.
- A divergent branch must stop before archive mutation or push. Test in Task 2.
- A shared branch with another live track must stop before partial cleanup. Test in Task 3.
- A failed final push must leave an explicitly reported local-only archive that `--resume-push` can safely publish. Test in Task 3.
- Symlinks and malformed metadata must not escape the repository or cause partial edits. Test in Task 3.

---

### Task 1: Deterministic archive helper and basic synchronization

**Files:**
- Create: `conductor/scripts/archive-track.py`
- Test: `conductor/scripts/test-archive-track.sh`

**Interfaces:**
- Consumes: `--dry-run`, `--apply`, `--resume-push`, and exactly one `track_id`; current repository/worktree; track metadata; configured upstream.
- Produces: exit `0` only for a completed requested operation; nonzero with `STOP:` diagnostics for failed preflight, synchronization, mutation, or push; structured report lines identifying local/remote state and the resulting commit.

- [ ] **Step 1: Write the failing fixture tests**

  Build a temporary bare remote plus clone/worktree fixture in
  `test-archive-track.sh`. Add tests for:

  - equal local/remote tips with metadata `complete` and `--apply`;
  - equal local/remote tips with metadata `awaiting-review` and its `[~]` registry note;
  - `in-progress` and `blocked` hard stops with no archive directory;
  - `--dry-run` with no synchronization, push, or filesystem mutation;
  - exact archive path, metadata status, registry removal, commit message, and pushed remote tip.

- [ ] **Step 2: Run the fixture tests and verify they fail**

  Run:

  ```bash
  bash conductor/scripts/test-archive-track.sh
  ```

  Expected: FAIL because `conductor/scripts/archive-track.py` does not yet exist.

- [ ] **Step 3: Implement argument, repository, and metadata validation**

  Implement `archive-track.py` using `argparse`, `json`, `pathlib`, and
  `subprocess`. Validate the track ID, repository root, current worktree and
  branch, metadata `id`/`branch`/`worktreePath`, RFC 3339 UTC timestamps, source
  artifacts, lifecycle status, registry block, review report, terminal plan
  tasks/checkpoints, and clean worktree. Reject symlinked path components and
  canonical paths outside the repository. Implement `--dry-run` as a strictly
  read-only report mode.

- [ ] **Step 4: Implement equal-tip archive mutation**

  Add the explicit-confirmation/`--apply` gate, atomic lock, archive directory
  move, complete registry-block removal, metadata update to `archived`, exact
  staging-path check, exact commit message, post-commit verification, and
  ordinary remote push. Use a bounded rollback before commit and report the
  exact local-only state after a post-commit push failure.

- [ ] **Step 5: Run the fixture tests and verify they pass**

  Run the same command. Expected: all basic status, move, metadata, registry,
  commit, and remote-push assertions pass.

- [ ] **Step 6: Commit the task implementation**

  ```bash
  git add conductor/scripts/archive-track.py conductor/scripts/test-archive-track.sh
  git commit -m "feat(conductor): add archive recovery helper"
  ```

### Task 2: Remote synchronization and recovery push

**Files:**
- Modify: `conductor/scripts/archive-track.py`
- Modify: `conductor/scripts/test-archive-track.sh`

**Interfaces:**
- Consumes: Task 1's validation and archive operation.
- Produces: fast-forward-only synchronization, implementation push-before-archive, divergence hard stop, and `--resume-push` behavior.

- [ ] **Step 1: Add failing synchronization tests**

  Add fixtures for remote-ahead, local-ahead, equal, divergent, missing
  upstream/remote branch, and final archive push rejection. Assert filesystem,
  Git index, commit, and remote state—not only output text.

- [ ] **Step 2: Run the new tests and verify the expected failures**

  Run:

  ```bash
  bash conductor/scripts/test-archive-track.sh
  ```

  Expected: the new synchronization and recovery cases fail before their
  behavior is implemented.

- [ ] **Step 3: Implement synchronization**

  Fetch the configured upstream, classify equal/local-ahead/remote-ahead/
  divergent histories with Git ancestry checks, push local-ahead commits,
  fast-forward remote-ahead histories only, and re-run pre-mutation checks after
  a fast-forward. Never recreate a missing upstream or use force-push.

- [ ] **Step 4: Implement `--resume-push`**

  Validate the existing archive directory, absent source/registry entry,
  `archived` metadata, exact archive commit message/path set, and remote
  ancestry. Push only the existing archive commit; do not repeat the move.

- [ ] **Step 5: Run the full synchronization and recovery suite**

  Run:

  ```bash
  bash conductor/scripts/test-archive-track.sh
  ```

  Expected: all synchronization, divergence, push-failure, and resume-push
  assertions pass.

- [ ] **Step 6: Commit the task implementation**

  ```bash
  git add conductor/scripts/archive-track.py conductor/scripts/test-archive-track.sh
  git commit -m "feat(conductor): synchronize archive recovery branches"
  ```

### Task 3: Safety edge cases and shared-branch protection

**Files:**
- Modify: `conductor/scripts/archive-track.py`
- Modify: `conductor/scripts/test-archive-track.sh`

**Interfaces:**
- Consumes: Task 2's synchronization and resume-push behavior.
- Produces: hard stops for shared live tracks, symlink escapes, malformed metadata, orphan registry notes, dirty state, unrelated staged/untracked files, and mutation failures.

- [ ] **Step 1: Add failing edge-case fixtures**

  Add tests for another live track on the same branch, symlinked source/
  metadata/registry/archive paths, mismatched metadata ID or branch, malformed
  JSON, invalid timestamps, orphan awaiting-review notes, dirty worktrees,
  unrelated staged/untracked files, and injected mutation/commit failures.

- [ ] **Step 2: Run the edge-case tests and verify they fail**

  Run the fixture harness and confirm each new case fails for the missing guard,
  not because the fixture itself is malformed.

- [ ] **Step 3: Implement the guards and failure reporting**

  Add canonical-path/symlink checks, exact registry-block parsing, shared-live-
  track detection, strict metadata validation, lock cleanup, rollback state
  reporting, and post-commit failure reporting that distinguishes local and
  remote mutations.

- [ ] **Step 4: Run the complete fixture suite**

  Run:

  ```bash
  bash conductor/scripts/test-archive-track.sh
  ```

  Expected: all required success and failure cases pass, including exact
  filesystem, metadata, registry, index, commit, and remote assertions.

- [ ] **Step 5: Commit the task implementation**

  ```bash
  git add conductor/scripts/archive-track.py conductor/scripts/test-archive-track.sh
  git commit -m "test(conductor): cover archive safety failures"
  ```

### Task 4: OpenCode command and installation integration

**Files:**
- Create: `.opencode/command/archive.md`
- Modify: `install.sh`
- Modify: `README.md`
- Modify: `skill/SKILL.md`
- Modify: `conductor/scripts/test-archive-track.sh`

**Interfaces:**
- Consumes: Task 3's `archive-track.py` CLI and the approved safety design.
- Produces: `/conductor/archive` command documentation, installed helper asset, canonical lifecycle guidance, and command-surface verification.

- [ ] **Step 1: Add failing command-surface assertions**

  Extend the test harness or add a structural shell check asserting the command
  wrapper names all supported modes, invokes the local helper before the
  installed helper fallback, and documents the exact archive commit message.

- [ ] **Step 2: Run the assertions and verify they fail**

  Run the structural check. Expected: FAIL because the archive command wrapper
  and install wiring do not yet exist.

- [ ] **Step 3: Add `.opencode/command/archive.md`**

  Document the track-worktree requirement, confirmation gate, supported modes,
  helper resolution order, status behavior, synchronization behavior, exact
  move/commit/push contract, and local-only `--resume-push` recovery.

- [ ] **Step 4: Wire installation and doctrine**

  Copy `archive-track.py` into the installed command assets, add
  `/conductor/archive` to `README.md`, and update `skill/SKILL.md` to describe
  archive recovery without changing the existing `/conductor/review` archive
  path or `/conductor/cleanup` merge-removal semantics.

- [ ] **Step 5: Verify the installed command surface**

  Run:

  ```bash
  bash conductor/scripts/test-archive-track.sh
  bash -n install.sh
  grep -nE 'conductor/archive|archive-track' README.md skill/SKILL.md install.sh .opencode/command/archive.md
  git diff --check
  ```

  Expected: the helper tests pass, installer syntax is valid, all command/
  installation references are present, and `git diff --check` is clean.

- [ ] **Step 6: Commit the task integration**

  ```bash
  git add .opencode/command/archive.md install.sh README.md skill/SKILL.md conductor/scripts/test-archive-track.sh
  git commit -m "docs(conductor): expose archive recovery command"
  ```

## Final Verification

- [ ] Run `bash conductor/scripts/test-archive-track.sh` with all cases passing.
- [ ] Run `bash -n install.sh`.
- [ ] Run `git diff --check`.
- [ ] Inspect the final diff for unrelated files and confirm the archive helper never force-pushes, resets, rebases, or mutates a base-branch checkout.
