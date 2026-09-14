# Plan: Fix stale manual-checkpoint tag read in /conductor/implement

Track ID: `checkpoint-fresh-read_20260914`

Skip hatch used (user: "just make the edit directly and show me the
diff", then "go ahead" on proceeding via a lightweight track) — no
brainstorming loop. Both tasks are `backend-logic` (doctrine prose
edits), verified via the same doctrine-text grep-assertion test-first
loop established in the prior track, applied here with genuine
fail-then-pass verification (the already-drafted edit is reverted,
confirmed absent, then reapplied and confirmed present — not assumed
passing because it was drafted earlier in the conversation).

## Phase 1: Tighten the fresh-read requirement

- [x] Task: Update `.opencode/command/implement.md` Step 3.c to
      require an actual read/grep tool call against `plan.md`'s
      current on-disk content at the checkpoint-trigger moment;
      forbid relying on context already loaded via the command's
      `@conductor/tracks/$ARGUMENTS/plan.md` mention; forbid inferring
      the tag from `new-track.md`'s tagging heuristic or the phase's
      task types. Verify via grep assertion: confirm Step 3.c contains
      "read/grep tool call", a reference to not relying on the `@`
      mention, and a reference to not inferring from the tagging
      heuristic [backend-logic] 05302c0
- [x] Task: Apply the identical tightening to `conductor/workflow.md`'s
      Phase Checkpoint Procedure (the authoritative doctrine
      `implement.md` defers to) and to `conductor/assets/
      workflow-template.md` (the packaged template `/conductor/update`
      propagates from, kept in sync so it doesn't later reintroduce
      the stale wording), including the explicit statement that "before
      the checkpoint step" covers removal before `/conductor/implement`
      is even invoked. Verify via grep assertion: confirm both files
      contain the same "read/grep tool call" and "before ... is even
      invoked" language, and that the two files remain byte-identical
      to each other in this section [backend-logic] 313fe19
