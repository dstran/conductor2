# Track: Fix stale manual-checkpoint tag read in /conductor/implement

**Type:** Bug fix

## Summary

`/conductor/implement`'s Phase 3.c ("read the phase heading fresh") is a
textual instruction with no mechanical enforcement — an executing agent
can substitute inference (from `new-track.md`'s tagging heuristic, or
from context already loaded via the command's `@plan.md` mention) for
an actual fresh read of the file. This produced an observed bug: a user
removed `[manual-checkpoint]` from a phase heading *before* invoking
`/conductor/implement`, and the command still paused for manual
checkpoint on that phase — the exact behavior the doctrine says should
not happen ("the user may add or remove the tag by hand at any point
before `/conductor/implement` reaches that phase's checkpoint step").

## Root cause

Confirmed by reading `implement.md` and `workflow.md` end to end: the
doctrine text is internally consistent and unambiguous — there is no
textual contradiction that would excuse the observed behavior. The gap
is structural: "read fresh" is advisory language for an LLM-executed
instruction, not a forced tool call. Nothing in the text explicitly
rules out the agent inferring the tag's presence from the phase's task
types (the same heuristic `new-track.md` uses to originally assign the
tag) instead of mechanically checking the literal on-disk text at the
moment the checkpoint fires.

## Fix

Tighten the doctrine in `implement.md` Step 3.c and `workflow.md`'s
Phase Checkpoint Procedure (plus the packaged `workflow-template.md`,
so `/conductor/update` doesn't later reintroduce the stale wording):

- Explicitly require an actual read/grep tool call against `plan.md`'s
  current on-disk content at the checkpoint-trigger moment.
- Explicitly forbid relying on context already loaded via the
  command's `@conductor/tracks/$ARGUMENTS/plan.md` mention.
- Explicitly forbid inferring the tag from `new-track.md`'s tagging
  heuristic or any reasoning about the phase's task types — only the
  literal tag text counts.
- Explicitly state that "before the checkpoint step" includes removal
  before `/conductor/implement` is even invoked, closing the
  ambiguity that let this slip through.

## Scope

**In scope:** `.opencode/command/implement.md`, `conductor/workflow.md`,
`conductor/assets/workflow-template.md` — doctrine wording only, no
renumbering, no behavior change to the tagged/untagged branches
themselves.

**Out of scope:** any other checkpoint/test-enforcement doctrine not
directly related to this specific fresh-read gap.

## Assumptions & agent-made decisions

*(none — skip hatch used per user's explicit "spec is already decided,
skip brainstorming, just make the edit" instruction)*

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK

*(none)*
