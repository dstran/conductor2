# Track: Worktree-native concurrent Conductor lifecycle

**Type:** Feature

## Summary

Extend Conductor's lifecycle (`setup → new-track → implement → review`) so multiple tracks can run fully concurrently, each isolated in its own git worktree and branch, from creation through archive and PR. Two `/conductor/implement` runs in separate worktrees never contend for the same files, because each branch's registry additions are fully unwound (via archive) before it's ever merged.

## Scope

**In scope:**
- `/conductor/new-track` always creates a dedicated worktree (`.worktrees/<track_id>`) and branch (`track/<track_id>`) from current `HEAD`, then creates all track artifacts inside it.
- `metadata.json` gains `worktreePath`, `branch`, `baseRef` fields, recorded once at creation.
- `/conductor/implement` and `/conductor/revert` operate inside the track's worktree (read/write/commit there) when the track has recorded worktree info.
- `/conductor/review` step 10 (track cleanup), after archive-on-branch, adds: open a PR (`gh pr create`) against `baseRef`. Human reviews and merges; Conductor never auto-merges.
- `/conductor/status`, when run from any worktree, aggregates across all live `.worktrees/*` — showing each track's progress, plus flagging any worktree whose branch is fully merged into its `baseRef` with the exact `git worktree remove`/branch-delete cleanup commands. Detection only; human runs the commands.
- Doctrine wording updated across `skill/SKILL.md`, `new-track.md`, `implement.md`, `review.md`, `status.md`, `revert.md` to say "the tracks registry in the track's worktree" instead of implying one global file.

**Out of scope:**
- Auto-merging PRs (human always merges).
- Retrofitting worktrees onto tracks created before this feature — those are grandfathered and continue on the current worktree exactly as today.
- A new dedicated cleanup/sync command — merged-branch detection folds into `/conductor/status`.
- Cross-worktree track-ID collision checking — remains a known minor gap (documented below), not solved by this track.

## Key design property (why this doesn't conflict)

`/conductor/new-track` inserts a `tracks.md` entry at a fixed anchor; if two branches both insert there, merging them back conflicts. But `/conductor/review`'s archive step removes that same entry before the branch is ever merged — so by PR time, each branch's `tracks.md` is byte-identical to its `baseRef` version. Verified empirically (two full-lifecycle worktrees, `new-track → implement → review → archive`, merged to a shared base with `git merge --no-edit`): both merges succeeded with exit code 0, no conflicts, both `archive/<id>/metadata.json` present, `tracks.md` unchanged from base.

This property only holds if archive (or delete) runs **before** merge-back. If a track chooses "Skip" cleanup in `/conductor/review` step 10 and its live `[x]` entry gets merged, a second such track can still conflict on `tracks.md` — this is a documented residual risk, not eliminated by this track.

## Decisions

- Worktree location: `.worktrees/<track_id>`, branch `track/<track_id>`, branched from current `HEAD` at `/conductor/new-track` time.
- Worktree creation is **always-on** default behavior — no opt-out flag.
- If `git worktree add` fails (collision, git error, not a repo), `/conductor/new-track` stops and reports the exact git error — no fallback to current-branch mode.
- PR-opening lives inside `/conductor/review` step 10, immediately after archive-on-branch, in the same command invocation.
- If `gh` is missing/unauthenticated, `/conductor/review` detects this and gives manual `git push` + PR-creation instructions instead of failing silently.
- `baseRef` is persisted in `metadata.json` at creation time (not re-derived later) — used by both `/conductor/review`'s PR step and `/conductor/status`'s merged-branch detection.
- `/conductor/status`'s merged-branch check: `git log <baseRef>..track/<track_id>` empty (or `gh pr view --json state` shows merged) ⇒ flag as cleanup-ready with exact commands.
- Tracks created before this feature (no `worktreePath`/`branch`/`baseRef` in `metadata.json`) are grandfathered: `/conductor/implement`/`/conductor/review`/`/conductor/revert` operate on the current worktree exactly as today, no retrofit offered.
- This track's own tasks (doctrine/markdown edits to command docs) are tagged `backend-logic`, verified via scripted git simulations (temp repos exercising worktree creation, concurrent lifecycle, and merge-back) run test-first per `workflow.md`'s existing strict test-first loop — no new task type introduced.

## Assumptions & agent-made decisions

*(none — every fork was answered directly)*

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK

*(none — every fork was answered directly)*
