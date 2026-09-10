# Plan: Worktree-native concurrent Conductor lifecycle

Track ID: `worktree-lifecycle_20260910`

All tasks in this track edit Conductor command doctrine (markdown files
under `.opencode/command/` and `skill/SKILL.md`). Per `spec.md`'s
decision, every task is tagged `backend-logic` and verified by a
scripted git simulation (a temp-repo script that exercises the actual
git mechanics — worktree creation, concurrent lifecycle, merge-back —
and asserts exit codes / file state) run test-first per
`conductor/workflow.md`'s strict test-first loop: write the simulation
script first, confirm it fails against current doctrine-less behavior
(or, where the "behavior" being tested is a doctrine constraint an
agent should follow, confirm the script fails without the doctrine
line to point at), then edit the doctrine file, then confirm the
script passes.

## Phase 1: `/conductor/new-track` creates the worktree

- [ ] Task: Write a scripted simulation asserting that running the
      `/conductor/new-track` worktree-creation step against a repo with
      an existing `.worktrees/<track_id>` or `track/<track_id>` branch
      fails with a clear git error (no silent overwrite, no fallback to
      current-branch mode) [backend-logic]
- [ ] Task: Add Step 2.5 to `new-track.md` — after the track-ID
      collision check and before artifact creation — run
      `git worktree add .worktrees/<track_id> -b track/<track_id>`
      from current `HEAD`; on failure, stop and report the exact git
      error verbatim, per spec's decision (no fallback) [backend-logic]
- [ ] Task: Write a scripted simulation asserting that after this step,
      all subsequent artifact creation (Step 3: spec.md/plan.md,
      Step 4: tracks.md entry, Step 5: commit) happens inside the new
      worktree directory, not the invoking directory [backend-logic]
- [ ] Task: Update `new-track.md` Steps 3–5 to operate relative to the
      new worktree path, and Step 3's `metadata.json` write to include
      `worktreePath`, `branch`, and `baseRef` (the commit SHA `HEAD`
      pointed to before worktree creation) [backend-logic]
- [ ] Task: Update `new-track.md` Step 6 (pause for approval) to tell
      the user the worktree path alongside the track ID, so they know
      where to `cd` before running `/conductor/implement` [backend-logic]

## Phase 2: `/conductor/implement` and `/conductor/revert` become worktree-aware

- [ ] Task: Write a scripted simulation asserting that a track with
      `worktreePath` recorded in `metadata.json` causes `/implement`
      doctrine to read/write/commit inside that worktree, while a
      track with no such field (grandfathered, pre-feature) causes it
      to operate on the current worktree unchanged [backend-logic]
- [ ] Task: Add a preamble step to `implement.md` (before Step 1): read
      the target track's `metadata.json`; if `worktreePath` is present,
      confirm the command is running inside (or switch context to)
      that path before touching `plan.md`/`tracks.md`; if absent,
      proceed exactly as today (grandfather clause) [backend-logic]
- [ ] Task: Apply the same preamble pattern to `revert.md` (its Step 1
      target-selection step), since `/revert`'s git reconciliation must
      run against the correct worktree's history [backend-logic]
- [ ] Task: Update doctrine wording in both files: replace references
      to "`conductor/tracks.md`" (implying a single global file) with
      "the tracks registry in the track's worktree" [backend-logic]

## Phase 3: `/conductor/review` archives on-branch, then opens a PR

- [ ] Task: Write a scripted simulation reproducing the verified
      end-to-end property from `spec.md`: two worktrees each run
      new-track → implement (status flip) → review (closure) → archive
      (move dir, strip registry entry) on their own branch, then both
      branches merge into a shared base with `git merge --no-edit`;
      assert both merges exit 0 with no conflicts and both
      `archive/<id>/` directories present [backend-logic]
- [ ] Task: Write a scripted simulation asserting that skipping archive
      (leaving a live `[x]` entry) and merging two such branches DOES
      conflict — documenting the residual risk from spec.md as an
      explicit, checked boundary rather than an assumption
      [backend-logic]
- [ ] Task: Extend `review.md` Step 10's Archive branch: after the
      existing move-and-commit, add a PR-opening step — check for `gh`
      on PATH and authenticated (`gh auth status`); if present, run
      `gh pr create` against the track's recorded `baseRef` with a
      summary of the closure report; if absent/unauthenticated, print
      the exact manual `git push -u origin track/<track_id>` and
      PR-creation instructions instead. Explicitly state Conductor
      never merges the PR — that is always a human action
      [backend-logic]
- [ ] Task: Add a line to `review.md` clarifying that Delete and Skip
      (Step 10's other two branches) do not open a PR — only Archive
      does, since Delete/Skip leave no clean merge-back state per
      spec's documented residual risk [backend-logic]

## Phase 4: `/conductor/status` aggregates across worktrees and flags merged branches

- [ ] Task: Write a scripted simulation with multiple sibling worktrees
      (some with unmerged commits on their branch, one with a branch
      fully merged into its recorded `baseRef`) asserting that a status
      scan correctly partitions them into "still active" vs.
      "cleanup-ready" [backend-logic]
- [ ] Task: Rewrite `status.md` Step 0 (new, before today's Step 1) to
      enumerate `.worktrees/*` (via `git worktree list`) in addition to
      the current worktree, and read each one's `conductor/tracks.md`
      and `conductor/tracks/*/metadata.json` [backend-logic]
- [ ] Task: Add a new step to `status.md`: for each discovered worktree,
      compute `git log <baseRef>..<branch>` from its `metadata.json`; if
      empty (or `gh pr view --json state` reports merged), flag it as
      cleanup-ready and print the exact `git worktree remove
      .worktrees/<track_id>` plus local/remote branch-delete commands —
      detection only, never auto-run [backend-logic]
- [ ] Task: Update `status.md` Step 3 (present the summary) to include
      a new "Cleanup-ready worktrees" section listing any flagged in
      the previous task [backend-logic]

## Phase 5: Doctrine-wide wording sweep

- [ ] Task: Write a scripted check (grep-based, asserting zero matches)
      confirming no command doc under `.opencode/command/` still implies
      a single global `conductor/tracks.md` shared by all tracks
      simultaneously (i.e. no unqualified "the tracks registry" without
      "in the track's worktree" or equivalent) [backend-logic]
- [ ] Task: Update `skill/SKILL.md`'s "Project Surface" and "Implement
      Contract" sections to state that `conductor/tracks.md` and
      `conductor/tracks/` are per-worktree when a track has its own
      worktree, and that `/conductor/new-track` creates that worktree
      by default [backend-logic]
- [ ] Task: Update `setup.md` Step 8 (tracks registry skeleton) with a
      one-line note that this file's scope is the current
      worktree/branch once tracks begin using dedicated worktrees
      [backend-logic]
- [ ] Task: Update the root `AGENTS.md` compatibility-wrapper note (if
      it references the tracks registry) to match, keeping `skill/
      SKILL.md` as the canonical source per this repo's own doctrine
      rule [backend-logic]
