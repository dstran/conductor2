---
description: Remove a track worktree and its local branch after its pull request has been merged, with a single confirmation
agent: build
---

`/conductor/cleanup` is an optional step after the Conductor lifecycle: `/conductor/setup -> /conductor/new-track -> /conductor/implement -> /conductor/review -> /conductor/cleanup`.

Treat the command's optional argument as a branch name (`track/<track_id>`) or
track ID. Cleanup is keyed on the **branch**, because several tracks can share
one PR branch.

When a branch or track ID is supplied, OpenCode appends it to this prompt; use
that trailing value as the filter. With no argument, consider every candidate.

Nothing is removed unless every merge-proof check below passes **and** the user answers yes.

## 1. Where to run

Run from the main checkout, never from inside a worktree being removed. Determine this with `git rev-parse --absolute-git-dir` and `git rev-parse --path-format=absolute --git-common-dir`: if they differ, the current directory is a linked worktree. In that case stop and print the command to run from the main checkout (`cd <main checkout> && /conductor/cleanup`), appending the same branch or track ID if one was supplied.

## 2. Choose the candidates

Run `git worktree list --porcelain`. Candidates are worktrees whose branch matches `track/*`. If an argument was supplied, keep only the candidate whose branch or track ID matches it; if none matches, say so and stop. If there are no candidates, say so and stop.

## 3. Merge proof (all four must hold, per candidate)

Run `git fetch origin` once first. For each candidate with branch `<branch>` at `<path>`, check and report which check fails; if any fails, remove nothing for that candidate.

1. **Merged.** The pull request for `<branch>` is merged and its head is the local branch tip:
   - GitHub: `gh pr view <branch> --json state,headRefOid --jq '.state + " " + .headRefOid'` prints `MERGED <sha>`, and `<sha>` equals `git rev-parse <branch>`. This also covers squash merges.
   - GitLab (best effort): `glab mr list --source-branch <branch> --merged -F json --jq '.[0].sha'` prints a SHA equal to `git rev-parse <branch>`.
   - Without a usable provider CLI: `git merge-base --is-ancestor <branch> origin/<baseBranch>` (take `baseBranch` from a track's `metadata.json` in that worktree, else the repository's default branch). If this is false, do not guess: ask the user to confirm by hand that the PR was merged. A yes counts as proof of merge; a no ends the check.
2. **Clean.** `git -C <path> status --porcelain` prints nothing.
3. **No unmerged commits.** The local branch has no commits beyond the merged head (the SHA equality in check 1, or the ancestor test, already guarantees this; with a manual confirmation, also require `git rev-list origin/<baseBranch>..<branch>` to be empty or explain what is left).
4. **No live tracks.** `<path>/conductor/tracks.md` has no entry under `## Active` or `## Blocked`.

## 4. Confirm

For the candidates that passed, list the worktree path and local branch that will be removed and ask one Yes/No question. On no, remove nothing and stop.

## 5. Remove

For each confirmed candidate, from the main checkout:

```bash
git worktree remove <path>
git branch -d <branch>
git worktree prune
```

Use `git branch -D <branch>` only if `git branch -d` refuses and check 1 proved the merge from PR state (a squash merge leaves the branch un-merged in git's view). Never use `--force` on `git worktree remove`.

Then ask a **separate** Yes/No question before deleting the remote branch: `git push origin --delete <branch>`. The host may already have deleted it; if so, skip the question.

## 6. Report

State what was removed, what was kept, and which check blocked anything that was skipped.
