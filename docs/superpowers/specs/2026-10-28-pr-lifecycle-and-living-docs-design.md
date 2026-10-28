# PR Lifecycle and Living Documentation Design

## Intent

Conductor creates one worktree and branch per track and opens a PR when the
track is archived. Three gaps follow from that:

1. **Review feedback has no home.** A reviewer's findings on the PR need
   refinement tracks, but `/new-track` always creates a new worktree, so
   refinements cannot live on the PR's branch.
2. **Nothing cleans up after a merge.** `/status` only prints removal commands.
3. **Project docs go stale.** `product.md` and `tech-stack.md` are synced at
   the end of `/implement`, before review fixes land, and nothing documents
   the architecture for developers.

The goal is a PR lifecycle where the worktree stays alive while the PR is open,
is cleaned up safely once it merges, and the project documentation stays
accurate and easy to consume without extra user effort.

## Verified current behavior

- `new-track.md` §2.5 runs `git worktree add .worktrees/<id> -b track/<id>`
  unconditionally. It records `baseBranch` from the current `HEAD` and says
  "do not silently ... reuse an existing worktree/branch." Run inside a track
  worktree, it would nest a worktree and record `track/<prev>` as `baseBranch`.
- `review.md` §10 creates the PR only on **Archive**, via
  `conductor/scripts/open-pr.sh`, which always runs `gh pr create` /
  `glab mr create`. A second track on the same branch would try to open a
  duplicate PR and fall back to manual instructions.
- Each track is archived before its branch is merged, so `conductor/tracks.md`
  matches the base at merge time (`worktree-lifecycle_20260910` spec).
  Refinement tracks must preserve this.
- `status.md` §2.5 detects merged worktrees with `git log <baseRef>..<branch>`
  being empty, optionally cross-checked with `gh pr view`. It never acts. The
  empty-log test fails for squash merges.
- Doc sync (`product.md`, `tech-stack.md`, `product-guidelines.md`) is
  `implement.md` §5, not `/review`. It asks Yes/No per diff and runs before the
  review correction loop.

## Goals

- Refinement tracks reuse the PR's existing worktree and branch.
- A merged PR leads to safe local cleanup with at most one confirmation.
- Review keeps `product.md` and `tech-stack.md` current and maintains a concise
  architecture document set, automatically.
- New developers can read the architecture docs in a short, fixed order.

## Non-goals

- Merging PRs. Merging stays a human action.
- Automatic deletion with no confirmation.
- Remote branch deletion without an explicit yes.
- Retrofitting tracks created before worktree support.
- Generating documentation for the whole codebase on every track.

## Anti-goals

- Cleanup that deletes a branch holding commits the PR did not merge.
- Docs that read confidently but cite code that does not exist.
- A nested worktree, or a second PR for the same branch.

## Part 1: Refinement tracks reuse the worktree

**Order: first.** Parts 2 and 3 depend on it.

### `/new-track` §2.5 — detect and reuse

Before `git worktree add`, decide whether the current directory is already a
track worktree. It is when all of these hold:

- `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`
  (a linked worktree);
- the current branch matches `track/*`;
- `conductor/` exists in this checkout.

If so, **reuse mode**:

- Do not run `git worktree add`; no new branch.
- `worktreePath` and `branch` are the current worktree and branch.
- `baseBranch` and `baseRef` are inherited from an existing track in this
  worktree (an active track's `metadata.json`, else the newest
  `conductor/archive/*/metadata.json`). They are **not** read from `HEAD`,
  which is the track branch itself. If none can be found, stop and ask.
- Add `"refines": "<previous_track_id>"` when the user names one or one is
  unambiguous; otherwise omit.
- The "do not reuse an existing worktree" rule keeps applying to the
  non-reuse path. Reuse mode is entered only by the detection above, never as
  a fallback after a failed `git worktree add`.
- Steps 3 onward are unchanged and run in the current directory.
- **Confirmation (user's decision).** Detection never reuses silently. Before
  entering reuse mode, ask one single-choice question: refine this PR's branch
  here, or stop so the user can start a separate track from the main checkout.
  Only an explicit "refine here" enters reuse mode. This question also covers
  the `refines` link, so ask which earlier track is being refined when more than
  one exists.

Outside a track worktree, behavior is unchanged.

**Stale PR (my call).** Before entering reuse mode, check the branch's PR state
with the provider CLI. If the PR is `MERGED` or `CLOSED`, do not reuse: stop,
explain that the branch's PR is finished, and point to `/conductor/cleanup` or
to running `/new-track` from the main checkout. If no PR exists yet, or the CLI
is unavailable, reuse proceeds.

### `/review` §10 — push to the existing PR instead of opening another

After Archive, if the branch already has an open PR, push and report instead of
creating one. Determine that with the provider CLI, not local state:

- GitHub: `gh pr view <branch> --json state,url`; open means `state` is `OPEN`.
- GitLab: `glab mr list --source-branch <branch>`.
- If the provider CLI is unavailable or unauthenticated, fall back to the
  existing manual output, adding "if a request for this branch is already
  open, pushing is sufficient."

This logic belongs in `open-pr.sh`, which receives the same four arguments, so
the dispatcher contract for callers is unchanged. Behavior when an open PR
exists: `git push origin <branch>`, print the PR URL, exit 0.

**PR comment (user's decision).** After a successful push to an existing PR,
post the track's `review.md` as a comment (`gh pr comment <branch>
--body-file <file>`; `glab mr note` on GitLab) so each refinement's report is
visible on the PR. This reuses the existing body-file argument, so the
four-argument contract is unchanged. If commenting fails, the push still
stands: print the failure and the manual `gh pr comment` command, and exit 0.

### Invariant to keep

Every track on the branch is archived before the next push to the PR, so
`tracks.md` still matches the base at merge time.

**Enforcement (my call).** `/review` §10 checks `conductor/tracks.md` before it
pushes. If any other entry is still live (`[ ]`, `[~]`, or `[x]` under
`## Active`), it does not push. It names the live tracks and tells the user to
finish or archive them first. The archive commit is kept. Enforcement is in
`review.md`, not `open-pr.sh`, because the script has no knowledge of the
registry.

## Part 2: Post-merge cleanup

### New command `/conductor/cleanup [branch|track_id]`

Without an argument it considers every Conductor worktree from
`git worktree list`. Cleanup is keyed on the **branch**, because several tracks
can now share one.

**Merge proof** (all must hold before anything is removed):

1. `git fetch origin`.
2. PR state is `MERGED` per `gh pr view <branch> --json state,headRefOid`, and
   `headRefOid` equals the local branch tip. This also covers squash merges.
   On GitLab use `glab mr view <branch>` with the equivalent state and head
   SHA fields (my call: best effort, same logic). Without a usable provider CLI, fall back to
   `git merge-base --is-ancestor <branch> origin/<baseBranch>`; if that is
   false, ask the user to confirm the merge by hand rather than guessing.
3. The worktree is clean (`git status --porcelain` empty) and the local branch
   has no commits beyond the merged head.
4. No track in that worktree is still active in `conductor/tracks.md`.

If any check fails, report which one and remove nothing.

**Actions**, after one Yes/No confirmation listing what will be removed:

- Run from the main checkout, never from inside the worktree being removed. If
  invoked inside it, print the command to run from the main checkout.
- `git worktree remove <path>`, `git branch -d <branch>`, `git worktree prune`.
  Use `-D` only if step 2 proved the merge by PR state.
- Ask separately before `git push origin --delete <branch>`; the host may have
  deleted it already.

### Triggering without friction

`/status` and the start of `/new-track` run the **read-only merge-proof checks**
only. If a worktree passes all four, they print one line:
"Branch `track/x` is merged. Run `/conductor/cleanup` to remove it." Nothing is
deleted from those entry points.

### Changes to existing docs

- `status.md` §2.5: replace its commands-only output with the line above and
  make its merge test the same proof as `/cleanup` (fixing the squash gap).
  Keep "never run automatically."
- `skill/SKILL.md` Lifecycle: add `cleanup` as an optional final step.
- Installer and README: ship and list the new command.

## Part 3: Documentation at review time

### Move doc sync from `/implement` to `/review`

- Remove `implement.md` §5.
- Add a step to `review.md` §9, after the user approves and before the closure
  commit, so review-loop fixes are reflected.
- Run it **without a prompt**. The result is a separate commit
  `docs(conductor): Synchronize docs for track '<id>'` that the PR shows.
- Scope: `product.md` for material product changes, `tech-stack.md` for
  technology or architecture changes, and the architecture set below.
- `product-guidelines.md` is **excluded** from unattended updates (my call: it
  defines product identity). Review may mention that `spec.md` touches
  branding or tone, but does not edit the file.
- If nothing needs to change, make no commit and say so.

### Architecture documents

Location `conductor/architecture/`, linked from `conductor/index.md` under a
new "Architecture" heading.

- `README.md`: purpose, a "read in this order" list, and one Mermaid
  `flowchart` of at most about 12 components and their dependency edges. Each
  node links to its page under `components/`.
- `components/<name>.md`, one per component, fixed template: Purpose;
  Responsibilities; Key interfaces; Depends on / Used by; Code paths; Gotchas.
  Target length is one screen.

### Reaching existing projects (my call)

`/setup` writes the "Architecture" heading into `conductor/index.md` for new
projects: `setup.md` §10's index template gains an `## Architecture` section
linking `./architecture/README.md`. For existing projects, `/review` appends
that section when it creates `architecture/` and finds it missing, in the same
docs commit, leaving the rest of `index.md` untouched.

If `product.md` or `tech-stack.md` does not exist, doc sync skips that file and
tells the user to run `/conductor/setup` to create it (user's decision).
Review never creates a minimal version, because `/setup`'s interview records
verification commands and module layout with the user's approval. The
architecture set does not depend on either file and is created regardless.

### How review updates them

- First run, no `architecture/` directory: one full audit of the repository to
  create the set. Mark this in the commit message.
- Later runs are **diff-scoped**: map the track's changed files to components.
  "The track's changed files" means files changed by this track's own commits
  (the task SHAs recorded in its `plan.md` plus its review-fix commits), not the
  diff from the inherited `baseRef`, which would include earlier tracks on a
  shared branch (my call);
  rewrite only those pages; touch the overview diagram only if a component or
  dependency edge was added, removed, or changed.
- A new top-level module becomes a new component page and diagram node.

### Guards against drift

- Every code path cited must exist in the checkout.
- Mermaid blocks must parse. Validate with `mermaid-cli` (`mmdc`) when
  installed; otherwise do a structural check and note it was not rendered.
- Overview diagram stays under the node cap; split into sub-diagrams on the
  component pages instead of growing it.
- Facts stay in the pages; the README only links and orients. Do not duplicate
  content between files.

## Constraints

- No new runtime dependency. `mmdc` is optional.
- Existing approval gates stay: `/review` step 7 approval, no auto-start of
  `/implement`, PR merging by humans.
- Dispatcher contract (four arguments) stays stable; installer copies any new
  asset.
- Historical specs and tests that refer to `/implement` doc-sync (the
  `2026-07-31-tier1-parity` fixtures) must be updated or marked superseded.

## Decisions made (for the user to check)

- **Mine:** `/cleanup` plus read-only prompts, instead of automatic cleanup.
- **Mine:** `product-guidelines.md` excluded from unattended updates.
- **Mine:** a `refines` field in `metadata.json`.
- **Mine:** push-vs-create logic lives in `open-pr.sh`.
- **User's:** refinement tracks run `/new-track` inside the PR's worktree and
  must not nest worktrees.
- **User's:** doc updates happen during review with no user input.
- **User's:** `/new-track` asks before reusing a track worktree.
- **User's:** a refinement's `review.md` is posted as a PR comment.

## Left to the builder

- Exact wording of the command docs and the architecture page template.
- How the first-run audit enumerates components for a given language or layout.
- Test fixtures for the shell logic (temporary repositories simulating a merged
  and squash-merged PR, and a reuse-mode `/new-track`).

## Suggested split

Three tracks, in this order: (1) worktree reuse plus `open-pr.sh` push mode,
(2) `/cleanup` and `/status` changes, (3) doc sync move plus architecture set.
