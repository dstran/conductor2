# Standalone Track Archive Recovery Command — Safety Design

## Intent

Provide a standalone Conductor command for resuming the cleanup phase of
`/conductor/review` when a completed review no longer offers Archive as a user
choice.

The command runs on the track's own worktree and branch. Before archiving, it
must synchronize that branch with its configured remote tracking branch and
push any local implementation commits. After the archive commit is created, it
must push that commit as well.

The command must be conservative: read-only verification happens before
mutation. If preflight verification fails, the command stops and must not move
the track directory, edit `metadata.json`, edit `conductor/tracks.md`, create an
archive directory, create a commit, or push anything. Synchronization and
pushing begin only after all checks pass and the user confirms (or supplies
`--apply`).

Proposed invocations:

```text
/conductor/archive <track_id>
/conductor/archive --apply <track_id>
/conductor/archive --dry-run <track_id>
/conductor/archive --resume-push <track_id>
```

Require exactly one track ID. `--dry-run` performs no synchronization or
mutation. Applying the archive operation requires an explicit confirmation or
`--apply`. `--resume-push` is only valid after a prior run created the archive
commit locally but could not push it.

## Goals

- Detect whether the requested track is eligible for archival, even when its
  metadata status is `complete` or `awaiting-review` rather than the other.
- Prove that the current track branch and its configured remote tracking branch
  can be synchronized without a non-fast-forward merge before changing any
  track files.
- Preserve the complete track folder under `conductor/archive/<track_id>/`.
- Remove the active registry entry only after successful verification.
- Mark archived metadata as `"status": "archived"`.
- Produce one focused commit:
  `chore(conductor): Archive track '<track_id>'`.
- Push the synchronized implementation state before archiving and push the
  archive commit after it is created.
- Report the verification evidence and the resulting commit.

## Non-goals

- Do not repair implementation, plan, review, or metadata defects.
- Do not close or merge a pull/merge request.
- Do not delete a track; deletion needs a separate explicitly irreversible
  command.
- Do not archive tracks that are still in progress, blocked, or have an
  unknown/missing lifecycle status.
- Do not stage or commit unrelated working-tree changes.

## Required preflight verification

All checks below must pass before the command creates `conductor/archive/` or
changes any tracked file. Fetching remote state may update Git's
remote-tracking refs, but must not modify the worktree, index, or tracked
project files during preflight.

### 1. Repository, worktree, and argument checks

- Run from inside the repository that owns the track.
- Require exactly one valid `track_id`.
- Reject path traversal, absolute paths, separators, `.` and `..`.
- If `metadata.json` records `worktreePath`, require the current directory to
  be that worktree. Require the current branch to match the metadata `branch`.
- Resolve the branch's configured remote tracking branch. Do not silently use a
  different remote or branch. Stop if no usable upstream can be resolved.
- Require `metadata.json` to be valid JSON, with `id` exactly equal to
  `<track_id>`, a string `branch` matching the current branch, and a valid
  optional `worktreePath`. If `updatedAt` exists, require an RFC 3339 UTC
  timestamp; write the refreshed value in the same format.
- Require the repository worktree to be clean. If unrelated changes exist,
  stop and tell the user to commit or move them first.
- Resolve the repository root and reject symlinks in `conductor/`, the source
  track directory, `metadata.json`, `conductor/tracks.md`, or the archive
  destination. Canonical source and destination paths must remain beneath the
  repository root.

### 2. Track and registry checks

- Require `conductor/tracks/<track_id>/` to exist and be a directory.
- Require `metadata.json`, `plan.md`, `spec.md`, and `review.md` to exist.
- Require exactly one matching registry entry in `conductor/tracks.md`.
- Reject a track already listed in `conductor/archive/`.
- Accept only metadata status `complete` or `awaiting-review`; these are both
  eligible because this command recovers the review cleanup choice. Treat
  `in-progress` and `blocked` as hard stops. Treat missing, unknown, `new`, and
  other statuses as hard stops.
- Require the registry entry to be either the completed `[x]` entry in
  `## Active`, or the documented awaiting-review `[~]` entry with its exact
  `Status: implementation complete — awaiting review.` note. Do not accept a
  blocked entry.
- In normal archive mode, require the archive destination not to exist.
- In normal archive mode, require no other live track entry under `## Active`
  or `## Blocked` in this branch's registry. Shared branches must archive their
  live tracks through a coordinated cleanup; this command must not push a
  partial shared-branch cleanup.

`--resume-push` is a separate recovery path: require the archive destination to
exist, the source directory and registry entry to be absent, the archived
metadata status to be `archived`, and the latest local commit to have the exact
archive message and expected paths. It must skip the normal source-directory
checks and must not perform another move or metadata edit.

### 3. Remote-branch synchronization checks

Read the track `branch` from `metadata.json` and resolve its configured
upstream. The command must fetch the remote branch and compare its tip with the
local `HEAD`.

The states are:

1. Equal tips: the branch is synchronized.
2. Remote tip is an ancestor of local `HEAD`: local implementation commits are
   ahead and must be pushed after confirmation.
3. Local `HEAD` is an ancestor of the remote tip: fast-forward local with
   `git pull --ff-only` (or an equivalent fetch plus `merge --ff-only`) after
   confirmation, then re-run the relevant checks.
4. Neither tip is an ancestor of the other: stop for divergent history.

The command must never force-push, reset, rebase, or merge divergent history.
If a push fails because the remote changed after the check, stop and report the
observed state without archiving.

```text
local_track_tip == remote_track_tip
```

The proof must use a freshly fetched remote tracking ref, not an unchecked
stale local value. The command must not recreate a deleted remote branch
implicitly; if no configured remote branch exists, stop and report that the
branch must be restored or configured first.

### 4. Review and plan checks

- Require every plan task intended for this track to be terminal (`[x]`,
  with the task commit SHA format required by `conductor/workflow.md`). Do not
  accept an undefined free-form deferred state.
- Require every phase checkpoint to use the repository's documented checkpoint
  format when the plan contains a phase checkpoint.
- Require the review report to exist.
- Preserve unresolved findings in the archived review; do not silently rewrite
  them as passing.
- Require explicit user confirmation when the review report contains unresolved
  findings or a failed verification result. That confirmation does not
  override the hard stops for `in-progress`, `blocked`, divergent history, or
  failed branch synchronization.

The command may accept either `complete` or `awaiting-review` as the metadata
state, but the review and plan evidence must still be present. A stale status
must be reported rather than silently rewritten before the archive mutation.

## Mutation boundary

The command has two phases with a hard boundary:

### Phase A — read-only verification

Perform every check, collect evidence, and present a summary. On any failure,
return a nonzero result and stop. No archive directory, move, metadata edit,
registry edit, commit, or push is allowed.

### Phase B — confirmed synchronization and mutation

Only after all checks pass and the user confirms:

1. Fetch the configured remote tracking branch again.
2. If local is ahead, push the local implementation commits.
3. If remote is ahead, fast-forward local with `git pull --ff-only` (or an
   equivalent fast-forward-only operation), then re-run the pre-mutation
   checks.
4. Verify local and remote tips are equal and the worktree is clean.
5. Create `conductor/archive/` if needed.
6. Move `conductor/tracks/<track_id>/` to
   `conductor/archive/<track_id>/` as one directory move.
7. Remove the track's complete contiguous registry block from
   `conductor/tracks.md`, including the awaiting-review or blocker note when
   present; do not leave an orphan lifecycle note.
8. Update archived `metadata.json` to `"status": "archived"` and refresh
   `updatedAt`.
9. Stage only the registry edit and the complete directory move.
10. Verify the staged diff contains no unrelated paths.
11. Commit with:

   ```text
   chore(conductor): Archive track '<track_id>'
   ```

12. Verify that the archive folder exists, the source folder is absent, the
   registry entry is absent, and the commit contains only expected paths.
13. Push the archive commit to the configured remote tracking branch.
14. Verify that the remote branch contains the archive commit. If this final
   push fails, report that the archive is local-only and do not claim the
   remote branch is archived.

If synchronization fails, do not begin the archive mutation. A fast-forward or
implementation push may already have changed local or remote branch state by
that point; report those exact changes rather than claiming that nothing
changed. If a pre-commit mutation step fails, attempt a bounded rollback of the
move, metadata, registry edits, newly-created archive directory, and Git index.
If rollback cannot be proven complete, stop, report the exact state, and do not
push further. Once the archive commit succeeds, a failed push is not rolled
back by rewriting history.

For a local-only archive commit, `--resume-push` must verify that the local
archive commit is still the expected commit and push only that commit to the
configured branch. It must not repeat the archive move.

## Failure contract

Every preflight verification failure must report:

- the failed check;
- the observed value or command output;
- the expected condition; and
- the fact that no archive mutation was performed.

Any failure after synchronization or archive mutation has begun must instead
report every local or remote change that already occurred and the exact
recoverable state. A post-commit failure must not be described as having made
no archive mutation.

Examples:

```text
STOP: local branch `track/example` has diverged from `origin/track/example`.
No archive files, metadata, registry entries, commits, or pushes were changed.
```

```text
STOP: working tree is dirty: app/proguard-gradle-repackage.txt.
Commit or move unrelated changes before archiving.
No archive mutation was performed.
```

The command must not continue after a failed preflight check, offer a partial
archive, or silently downgrade a failed synchronization check to a warning.
After synchronization has begun, it must report any fast-forward or push that
already occurred before stopping.

## Example

For `mission-file-parsing_20261016`, a successful run would first synchronize
the local track branch with its configured remote branch, then move:

```text
conductor/tracks/mission-file-parsing_20261016/
  -> conductor/archive/mission-file-parsing_20261016/
```

If preflight synchronization fails, the source folder and all metadata remain
unchanged. If synchronization fails after confirmation, report any
fast-forward or push that already occurred before stopping.

## Integration requirements

Implementation must add the `/conductor/archive` command surface and update the
canonical Conductor lifecycle documentation and README command list. The
existing `/conductor/review` Archive path remains valid; this command provides
the same cleanup operation when that interactive choice is no longer available.
The implementation must preserve the track-worktree scoping rules from
`skill/SKILL.md` and the review command rather than introducing a base-branch
archive path.

## Verification requirements for implementation

Add command-level tests using temporary Git repositories or isolated test
fixtures for:

1. synchronized branch with `complete` status — archives and pushes successfully;
2. synchronized branch with `awaiting-review` status — archives and pushes
   successfully;
3. `in-progress` or `blocked` status — stops with zero archive mutations;
4. remote branch ahead — fast-forwards, then archives successfully;
5. local branch ahead — pushes first, then archives successfully;
6. divergent local and remote branches — stops without archive mutation;
7. missing remote branch/upstream — stops without recreating it;
8. dirty worktree — stops before creating the archive directory;
9. existing archive destination — stops;
10. malformed or mismatched metadata/registry — stops;
11. another live track on the same branch — stops before pushing a partial
    shared-branch cleanup;
12. symlinked source, metadata, registry, or archive path — stops without
    touching a path outside the repository;
13. registry awaiting-review note — removes the complete entry block without an
    orphan note;
14. mismatched metadata `id`, invalid branch fields, or invalid timestamp —
    stops;
15. unrelated staged or untracked files — never stages them;
16. archive commit push failure — reports local-only archive state;
17. mutation failure — rolls back or reports an explicitly recoverable state;
18. successful archive — produces the exact commit message, expected diff, and
    pushed remote state;
19. failed archive push followed by `--resume-push` — pushes only the existing
    archive commit and does not repeat the move.

The failure tests must assert filesystem, metadata, registry, Git index, and
commit state—not only the returned error text.
