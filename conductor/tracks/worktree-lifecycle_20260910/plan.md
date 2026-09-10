# Plan: Worktree-native concurrent Conductor lifecycle

Track ID: `worktree-lifecycle_20260910`

All tasks in this track edit Conductor command doctrine — markdown
prose in files under `.opencode/command/`, `skill/SKILL.md`,
`AGENTS.md`. No application code is touched anywhere in this track.

**Revised test-first approach (superseding the original per-task
"scripted git simulation" framing):** a bash script cannot verify that
an LLM agent will faithfully follow markdown prose, and it cannot
test-first ambient git/filesystem mechanics that already work today
regardless of what doctrine says (e.g. `git worktree add` already
refuses to collide with an existing branch — that's git's behavior,
not this track's to build). The only artifact each task actually
changes is the doctrine text itself, so the genuine test-first loop per
task is:

1. Write a grep/structural assertion against the target `.md` file
   confirming the specific new doctrine text is present (e.g. "does
   `new-track.md` contain a step running `git worktree add
   .worktrees/<track_id> -b track/<track_id>`?").
2. Run it. Confirm it fails — the text genuinely isn't there yet.
3. Make the doctrine edit.
4. Run it again. Confirm it passes.
5. Mark the task `[x]` per the usual task commit procedure.

The underlying git-mechanics claims this track's design relies on (the
merge-clean property when archive runs before merge-back; the conflict
that occurs if it doesn't) are already validated empirically and
recorded as evidence in `spec.md`'s "Key design property" section —
that evidence is not re-derived per task.

## Phase 1: `/conductor/new-track` creates the worktree [checkpoint: dee74da]

- [x] Task: Add Step 2.5 to `new-track.md` — after the track-ID
      collision check and before artifact creation — run
      `git worktree add .worktrees/<track_id> -b track/<track_id>`
      from current `HEAD`; on failure, stop and report the exact git
      error verbatim, per spec's decision (no fallback). Verify via
      grep assertion: confirm `new-track.md` contains a step invoking
      `git worktree add` with the `.worktrees/<track_id>` path and
      `-b track/<track_id>` branch name, plus the no-fallback stop
      language [backend-logic] beed03e
- [x] Task: Update `new-track.md` Steps 3–5 to operate relative to the
      new worktree path, and Step 3's `metadata.json` write to include
      `worktreePath`, `branch`, and `baseRef` (the commit SHA `HEAD`
      pointed to before worktree creation). Verify via grep assertion:
      confirm Step 3's `metadata.json` description names all three new
      fields [backend-logic] f4afe90
- [x] Task: Update `new-track.md` Step 6 (pause for approval) to tell
      the user the worktree path alongside the track ID, so they know
      where to `cd` before running `/conductor/implement`. Verify via
      grep assertion: confirm Step 6 mentions the worktree path
      [backend-logic] dee74da

## Phase 2: `/conductor/implement` and `/conductor/revert` become worktree-aware

- [x] Task: Add a preamble step to `implement.md` (before Step 1): read
      the target track's `metadata.json`; if `worktreePath` is present,
      confirm the command is running inside (or switch context to)
      that path before touching `plan.md`/`tracks.md`; if absent,
      proceed exactly as today (grandfather clause). Verify via grep
      assertion: confirm `implement.md` contains a preamble step
      checking `metadata.json` for `worktreePath` and both the
      worktree-context and grandfather branches [backend-logic] 3b2859e
- [x] Task: Apply the same preamble pattern to `revert.md` (its Step 1
      target-selection step), since `/revert`'s git reconciliation must
      run against the correct worktree's history. Verify via grep
      assertion: confirm `revert.md` contains the equivalent
      `worktreePath` check before Step 1's target resolution
      [backend-logic] b15c315
- [x] Task: Update doctrine wording in both files: replace references
      to "`conductor/tracks.md`" (implying a single global file) with
      "the tracks registry in the track's worktree". Verify via grep
      assertion: confirm zero remaining unqualified "conductor/
      tracks.md" mentions in either file outside the new worktree-aware
      phrasing [backend-logic] ee6878a

## Phase 3: `/conductor/review` archives on-branch, then opens a PR

- [ ] Task: Extend `review.md` Step 10's Archive branch: after the
      existing move-and-commit, add a PR-opening step — check for `gh`
      on PATH and authenticated (`gh auth status`); if present, run
      `gh pr create` against the track's recorded `baseRef` with a
      summary of the closure report; if absent/unauthenticated, print
      the exact manual `git push -u origin track/<track_id>` and
      PR-creation instructions instead. Explicitly state Conductor
      never merges the PR — that is always a human action. Verify via
      grep assertion: confirm Step 10's Archive branch contains the
      `gh pr create` invocation, the `baseRef` reference, the manual
      fallback instructions, and the "never merges" statement
      [backend-logic]
- [ ] Task: Add a line to `review.md` clarifying that Delete and Skip
      (Step 10's other two branches) do not open a PR — only Archive
      does, since Delete/Skip leave no clean merge-back state per
      spec's documented residual risk. Verify via grep assertion:
      confirm the Delete and Skip branches each state no PR is opened
      [backend-logic]

## Phase 4: `/conductor/status` aggregates across worktrees and flags merged branches

- [ ] Task: Rewrite `status.md` Step 0 (new, before today's Step 1) to
      enumerate `.worktrees/*` (via `git worktree list`) in addition to
      the current worktree, and read each one's `conductor/tracks.md`
      and `conductor/tracks/*/metadata.json`. Verify via grep assertion:
      confirm `status.md` contains a step invoking `git worktree list`
      and reading each discovered worktree's registry/metadata
      [backend-logic]
- [ ] Task: Add a new step to `status.md`: for each discovered worktree,
      compute `git log <baseRef>..<branch>` from its `metadata.json`; if
      empty (or `gh pr view --json state` reports merged), flag it as
      cleanup-ready and print the exact `git worktree remove
      .worktrees/<track_id>` plus local/remote branch-delete commands —
      detection only, never auto-run. Verify via grep assertion: confirm
      `status.md` contains the `git log <baseRef>..<branch>` check and
      the cleanup-command output, with explicit "never auto-run"
      language [backend-logic]
- [ ] Task: Update `status.md` Step 3 (present the summary) to include
      a new "Cleanup-ready worktrees" section listing any flagged in
      the previous task. Verify via grep assertion: confirm Step 3 lists
      this new section [backend-logic]

## Phase 5: Doctrine-wide wording sweep

- [ ] Task: Update `skill/SKILL.md`'s "Project Surface" and "Implement
      Contract" sections to state that `conductor/tracks.md` and
      `conductor/tracks/` are per-worktree when a track has its own
      worktree, and that `/conductor/new-track` creates that worktree
      by default. Verify via grep assertion: confirm both named sections
      contain the per-worktree/worktree-creation language
      [backend-logic]
- [ ] Task: Update `setup.md` Step 8 (tracks registry skeleton) with a
      one-line note that this file's scope is the current
      worktree/branch once tracks begin using dedicated worktrees.
      Verify via grep assertion: confirm Step 8 contains this note
      [backend-logic]
- [ ] Task: Update the root `AGENTS.md` compatibility-wrapper note (if
      it references the tracks registry) to match, keeping `skill/
      SKILL.md` as the canonical source per this repo's own doctrine
      rule. Verify via grep assertion: confirm `AGENTS.md` has no
      tracks-registry wording that contradicts `skill/SKILL.md`'s
      updated per-worktree language (or confirm it makes no such
      reference at all, in which case this task is a no-op check, not
      an edit) [backend-logic]
- [ ] Task: Run a final repo-wide grep sweep confirming no command doc
      under `.opencode/command/` still implies a single global
      `conductor/tracks.md` shared by all tracks simultaneously (i.e.
      no unqualified "the tracks registry" without "in the track's
      worktree" or equivalent phrasing anywhere in the five touched
      files). This is the phase's closing verification, run after all
      four edits above, not a per-file edit of its own [backend-logic]
