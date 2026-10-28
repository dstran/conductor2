# PR Lifecycle and Living Docs Implementation Plan

> **For agentic workers:** Execute task by task. Each task ends with a commit. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Refinement tracks reuse a PR's worktree, a `/conductor/cleanup` command removes merged worktrees safely, and doc sync moves into `/review` together with a living architecture doc set.

**Architecture:** Conductor is prompt documents (`.opencode/command/*.md`, `skill/SKILL.md`) plus one POSIX shell dispatcher (`conductor/scripts/open-pr.sh`). Only the dispatcher is executable code and has a shell test harness; everything else is verified with grep assertions and a scratch-repo walk-through of the shell commands the prompts embed.

**Tech Stack:** POSIX sh, git 2.50, `gh`, `glab`, Markdown prompts. No new runtime dependency (`mmdc` optional).

**Spec:** `docs/superpowers/specs/2026-10-28-pr-lifecycle-and-living-docs-design.md`

## Global Constraints

- Commits use `GIT_AUTHOR_EMAIL` and `GIT_COMMITTER_EMAIL` set to `3491979+dstran@users.noreply.github.com`.
- All work stays on branch `docs/pr-lifecycle-living-docs-design`. Do not stage the two pre-existing untracked files (`docs/superpowers/plans/2026-10-07-embedded-host-code-doctrine-fixes.md`, `docs/superpowers/reports/2026-10-20-matt-pocock-skills-new-track-analysis.md`).
- `open-pr.sh` keeps exactly four arguments: `source target title body_file`.
- Existing `sh conductor/scripts/test-open-pr.sh` cases must keep passing unchanged.
- Existing approval gates stay. Nothing in these commands merges a PR or deletes without confirmation.
- No wayfinder-style routing in `/new-track`.

## Review Focus

- `open-pr.sh` must not turn any previously failing path into a silent success.
- Cleanup must never remove anything unless all four merge-proof checks hold and the user said yes.
- `/new-track` must never nest a worktree or reuse one without an explicit answer.

## File Map

| File | Change |
|---|---|
| `conductor/scripts/open-pr.sh` | Add existing-PR detection, push, PR comment |
| `conductor/scripts/test-open-pr.sh` | Add push/comment cases |
| `.opencode/command/new-track.md` | Reuse mode in §2.5, `refines`, cleanup hint |
| `.opencode/command/review.md` | §10 live-track guard; §9 doc sync + architecture |
| `.opencode/command/cleanup.md` | New command |
| `.opencode/command/status.md` | §2.5 read-only hint using the shared merge proof |
| `.opencode/command/implement.md` | Remove §5, renumber §6 |
| `.opencode/command/setup.md` | `## Architecture` in index template |
| `conductor/index.md` | Add `## Architecture` link |
| `skill/SKILL.md`, `README.md` | Lifecycle and command list |
| `docs/superpowers/specs/2026-07-31-tier1-parity-design.md` | Mark doc-sync fixtures superseded |

---

## Track 1: Worktree reuse and push-to-existing-PR

### Task 1: `open-pr.sh` pushes to an existing PR and posts the review as a comment

**Files:** `conductor/scripts/open-pr.sh`, `conductor/scripts/test-open-pr.sh`

Behavior to implement, after the existing auth checks and before the create call:

- GitHub: `gh pr view "$source" --json state,url --jq '.state + " " + .url'`. If the output starts with `OPEN `, an open PR exists; the URL is the rest.
- GitLab: `glab mr list --source-branch "$source" -F json --jq '.[0].web_url // empty'`. Non-empty output means an open MR exists (list defaults to open).
- Any failure of the view/list command means "no open request": fall through to the existing create path.
- When one exists: `git push origin "$source"`; on failure call `fallback`. Print `Pushed $source to existing <pull request|merge request>: <url>`. Then post the body file: `gh pr comment "$source" --body-file "$body_file"` / `glab mr note create "$source" -m "$(cat "$body_file")"`. If the comment fails, print `Could not post the review as a comment. Run manually:` plus the equivalent command, and still exit 0.

- [ ] **Step 1: Extend the fake bins and write failing tests.** In `test-open-pr.sh`, extend the `git` stub (before `exit 1`) to log `push` calls: `if [ "$1" = push ]; then printf '%s\n' "$@" >"$FAKE_LOG_DIR/git-push"; exit "${GIT_PUSH_STATUS:-0}"; fi`. Extend the `gh` stub with `pr view` (`printf '%s\n' "${GH_VIEW_OUTPUT:-}"; exit "${GH_VIEW_STATUS:-1}"`) and `pr comment` (log to `gh-comment`, exit `${GH_COMMENT_STATUS:-0}`). Extend the `glab` stub with `mr list` (print `${GLAB_LIST_OUTPUT:-}`, exit 0) and `mr note` (log to `glab-comment`, exit `${GLAB_COMMENT_STATUS:-0}`). The two later blocks that rewrite `gh` and `glab` stubs must get the same additions. Pass the new variables through `run_dispatcher`. Add cases:
  1. GitHub, `GH_VIEW_OUTPUT='OPEN https://github.com/o/r/pull/7'`, `GH_VIEW_STATUS=0`: exit 0; `git-push` equals `push origin track/demo`; `gh-comment` equals `pr comment track/demo --body-file <body>`; no `gh` create log; output contains the URL.
  2. GitHub, view returns `MERGED https://...`: falls through to create (`gh` log exists, no push).
  3. GitHub, view exit 1: falls through to create.
  4. GitHub open PR, `GIT_PUSH_STATUS=1`: exit 1 with the existing fallback text; no comment.
  5. GitHub open PR, `GH_COMMENT_STATUS=1`: exit 0; output contains `gh pr comment` manual command.
  6. GitLab, `GLAB_LIST_OUTPUT='https://gitlab.com/o/r/-/merge_requests/3'`: exit 0; push logged; `glab-comment` first args `mr note create track/demo -m`; no create log.
  7. GitLab empty list: falls through to create.
- [ ] **Step 2: Run, confirm failure.** `sh conductor/scripts/test-open-pr.sh` fails on the new cases.
- [ ] **Step 3: Implement** in `open-pr.sh`: add `existing_pr_url` lookup per provider and the push/comment branch described above, leaving the `fallback` function and argument handling untouched. Reset the fake logs per case (`rm -f "$log_dir/git-push" "$log_dir/gh-comment" "$log_dir/glab-comment"`).
- [ ] **Step 4: Run** `sh conductor/scripts/test-open-pr.sh` → `PASS`. Also `shellcheck` if installed.
- [ ] **Step 5: Commit** `feat(open-pr): push to an existing PR and post the review as a comment`.

### Task 2: `/review` §10 refuses to push while other tracks are live

**Files:** `.opencode/command/review.md`

- [ ] **Step 1: Failing assertion.** `grep -c "other live" .opencode/command/review.md` → `0`.
- [ ] **Step 2: Edit.** In §10 "Open a review request (Archive only)", after the archive commit and before invoking the dispatcher, add: read `conductor/tracks.md`; if any entry other than this track remains under `## Active` (`[ ]`, `[~]`, or `[x]`) or `## Blocked`, do not invoke the dispatcher. List the live tracks and tell the user to finish or archive them, then run the dispatcher manually or re-run this step. The archive commit stays. Also add one sentence: when the dispatcher reports it pushed to an existing request, tell the user a comment with this track's review report was posted.
- [ ] **Step 3: Verify.** `grep -n "other live" .opencode/command/review.md` shows the new text; `git diff --check`.
- [ ] **Step 4: Commit** `docs(review): guard pushes to a shared PR branch`.

### Task 3: `/new-track` reuse mode

**Files:** `.opencode/command/new-track.md`

- [ ] **Step 1: Failing assertion.** `grep -c "reuse mode" .opencode/command/new-track.md` → `0`.
- [ ] **Step 2: Edit §2.5.** Insert, before the existing worktree-creation text, a "Detect an existing track worktree" block:
  - It is a track worktree when `[ "$(git rev-parse --absolute-git-dir)" != "$(git rev-parse --path-format=absolute --git-common-dir)" ]`, the current branch matches `track/*`, and `conductor/` exists.
  - If so, check PR state: `gh pr view <branch> --json state --jq .state` (GitLab: `glab mr list --source-branch <branch> --all -F json --jq '.[0].merged_at // .[0].state'`, best effort). `MERGED` or `CLOSED` → stop; explain the PR is finished; point to `/conductor/cleanup` or running `/new-track` from the main checkout. Unknown or no PR → continue.
  - Ask a single-choice question: "Refine this branch's PR here" or "Stop, I'll start a separate track from the main checkout". Only the first enters **reuse mode**. If more than one earlier track exists, also ask which one is being refined.
  - Reuse mode: skip `git worktree add`; `worktreePath` and `branch` are the current ones; `baseBranch`/`baseRef` are copied from an existing track's `metadata.json` in this worktree (active first, else the newest `conductor/archive/*/metadata.json`); if none is found, stop and ask. Add `"refines": "<track_id>"` when chosen. Steps 3 onward run in the current directory. Reuse mode is only entered through this detection, never as a fallback after a failed `git worktree add`.
  - Adjust the existing "do not silently reuse" sentence to say it applies outside reuse mode.
- [ ] **Step 3: Edit §3 and §7.** §3: mention `refines` in the metadata description and that `worktreePath` is the current directory in reuse mode. §7: in reuse mode, say no `cd` is needed.
- [ ] **Step 4: Verify.** Walk the detection command in a scratch repo (`git worktree add`, run both `rev-parse` commands in the main checkout and the linked worktree; they must be equal and unequal respectively). `git diff --check`.
- [ ] **Step 5: Commit** `feat(new-track): reuse a PR's worktree for refinement tracks`.

---

## Track 2: `/conductor/cleanup`

### Task 4: New `cleanup.md` command

**Files:** `.opencode/command/cleanup.md`

- [ ] **Step 1: Failing assertion.** `test -f .opencode/command/cleanup.md` fails.
- [ ] **Step 2: Write the command** with front matter (`description`, `agent: build`) and these sections:
  1. **Scope.** Optional argument `[branch|track_id]`; without it, every `track/*` worktree from `git worktree list`. Must run from the main checkout; if the current directory is the worktree to remove, print the command to run from the main checkout and stop.
  2. **Merge proof**, all four required, reporting which fails:
     1. `git fetch origin`.
     2. `gh pr view <branch> --json state,headRefOid --jq '.state + " " + .headRefOid'` is `MERGED <sha>` and `<sha>` equals `git rev-parse <branch>`. GitLab best effort: `glab mr list --source-branch <branch> --merged -F json --jq '.[0].sha'`. Without a usable CLI: `git merge-base --is-ancestor <branch> origin/<baseBranch>`; if false, ask the user to confirm the merge manually, treating a yes as a PR-state proof.
     3. `git -C <path> status --porcelain` empty.
     4. `conductor/tracks.md` in that worktree has no live entry.
  3. **Confirmation.** One Yes/No question listing worktree path, local branch, and what will be removed.
  4. **Actions.** `git worktree remove <path>`, `git branch -d <branch>` (use `-D` only if PR state proved the merge), `git worktree prune`. Separately ask Yes/No before `git push origin --delete <branch>`.
  5. **Report** what was removed and what was skipped.
- [ ] **Step 3: Scratch-repo check** of the fallback proof: create a repo with `main`, a `track/x` worktree with a commit, merge it, and confirm `git merge-base --is-ancestor track/x main` exits 0; before merge exits 1.
- [ ] **Step 4: Verify** `grep -c "git worktree remove" .opencode/command/cleanup.md` ≥ 1, `git diff --check`.
- [ ] **Step 5: Commit** `feat(cleanup): add /conductor/cleanup for merged track worktrees`.

### Task 5: `/status` and `/new-track` print a hint; docs list the command

**Files:** `.opencode/command/status.md`, `.opencode/command/new-track.md`, `skill/SKILL.md`, `README.md`, `install.sh`

- [ ] **Step 1: Edit `status.md` §2.5.** Replace the `git log <baseRef>..<branch>` test and the printed commands with the same four-check merge proof as `cleanup.md` (read-only, no `git fetch` side effects beyond `git fetch origin`), and output one line per passing worktree: ``Branch `track/x` is merged. Run `/conductor/cleanup` to remove it.`` Keep "never run automatically."
- [ ] **Step 2: Edit `new-track.md`** near the start (after the index handshake): run the read-only merge-proof checks for other track worktrees and print the same hint; never delete.
- [ ] **Step 3: Edit `SKILL.md` Lifecycle** to add `cleanup` as an optional final step; **`README.md`** usage list to add `/conductor/cleanup`. Check `install.sh` copies `.opencode/command/*.md` generically; edit only if it lists files by name.
- [ ] **Step 4: Verify.** `grep -n "git log <baseRef>" .opencode/command/status.md` returns nothing; `grep -n cleanup README.md skill/SKILL.md`. `git diff --check`.
- [ ] **Step 5: Commit** `docs(status): hint at /conductor/cleanup instead of printing removal commands`.

---

## Track 3: Doc sync in `/review` and architecture docs

### Task 6: Move doc sync from `/implement` to `/review`

**Files:** `.opencode/command/implement.md`, `.opencode/command/review.md`, `docs/superpowers/specs/2026-07-31-tier1-parity-design.md`

- [ ] **Step 1: Failing assertion.** `grep -c "Synchronize" .opencode/command/review.md` → `0`.
- [ ] **Step 2: Edit `implement.md`.** Delete §5 and rename §6 to §5. Fix any reference to "step 5" or doc sync in that file.
- [ ] **Step 3: Edit `review.md` §9.** Insert, after the approval-gated test re-run and before the closure commit, a doc-sync step that runs without prompting:
  - `product.md`: update for material product changes; `tech-stack.md`: for technology or architecture changes. If either file is missing, skip and tell the user to run `/conductor/setup`; never create it.
  - `product-guidelines.md` is excluded.
  - Commit separately: `docs(conductor): Synchronize docs for track '<track_id>'`; no commit if nothing changed.
- [ ] **Step 4: Supersede the fixtures.** Add a note under the `2026-07-31-tier1-parity` spec section describing the doc-sync prompts, stating it moved to `/review` per the new spec.
- [ ] **Step 5: Verify.** `grep -rn "Synchronize project documentation" .opencode skill` returns nothing; `grep -n "Synchronize" .opencode/command/review.md`. `git diff --check`.
- [ ] **Step 6: Commit** `refactor(review): move doc sync from implement to review`.

### Task 7: Architecture documents

**Files:** `.opencode/command/review.md`, `.opencode/command/setup.md`, `conductor/index.md`

- [ ] **Step 1: Failing assertion.** `grep -c "conductor/architecture" .opencode/command/review.md` → `0`.
- [ ] **Step 2: Edit `review.md` doc-sync step** to add the architecture portion:
  - Location `conductor/architecture/`: `README.md` (purpose, "read in this order", one Mermaid `flowchart` of at most about 12 components, each node linking to its `components/` page) and `components/<name>.md` with the template Purpose / Responsibilities / Key interfaces / Depends on, Used by / Code paths / Gotchas, about one screen each.
  - First run (no directory): full repository audit; say so in the commit message body. Later runs: map files changed by this track's own commits (task SHAs in `plan.md` plus review-fix commits, never the diff from `baseRef`) to components; rewrite only those pages; touch the diagram only when a component or edge changed; a new top-level module gets a page and a node.
  - Guards: every cited path must exist (`test -e`); validate Mermaid with `mmdc` when installed, else a structural check and say it was not rendered; split into sub-diagrams on component pages rather than exceeding the node cap; no duplicated facts between files.
  - When creating the directory, append `## Architecture` with `- [Architecture Overview](./architecture/README.md)` to `conductor/index.md` if missing, in the same docs commit.
  - Architecture docs are created regardless of whether `product.md` or `tech-stack.md` exist.
- [ ] **Step 3: Edit `setup.md` §10** index template to add the `## Architecture` section; edit this repo's `conductor/index.md` to add the same section.
- [ ] **Step 4: Verify.** `grep -n "## Architecture" .opencode/command/setup.md conductor/index.md`; `grep -n "architecture" .opencode/command/review.md`. `git diff --check`.
- [ ] **Step 5: Commit** `feat(review): maintain a living architecture doc set`.

### Task 8: Final verification and PR

- [ ] **Step 1:** `sh conductor/scripts/test-open-pr.sh`; `git diff --check main...HEAD`; grep that `.github/` wrappers and `AGENTS.md` do not mention the removed doc-sync step (`grep -rn "Synchronize" .github AGENTS.md`).
- [ ] **Step 2:** `git log main..HEAD --format='%h %ae %s'` shows only the noreply address.
- [ ] **Step 3:** `git push origin docs/pr-lifecycle-living-docs-design`, then `gh pr create --base main` with a summary. If `gh` auth is still invalid, report the compare URL and ask the user to run `gh auth login -h github.com`.

## Self-Review

- Spec coverage: reuse + confirmation + stale-PR (Task 3), push mode + comment (Task 1), live-track guard (Task 2), cleanup + proof + hints (Tasks 4–5), doc sync move + exclusions + missing-file rule (Task 6), architecture set + index + setup (Task 7), superseded fixtures (Task 6).
- Name consistency: `refines`, `existing PR`, merge proof (four checks) are used identically in Tasks 3–5.
- Known limits: prompts are verified by grep and scratch-repo checks, not by running an agent; GitLab paths are best effort and tested only through stubs.
