# Phase Auto-Checkpoint — Design

Adds a static, plan-time tag that lets `/implement` skip the manual
"does this meet expectations?" pause for phases judged low-risk at plan
generation, while keeping the existing manual gate for phases that touch
a real frontend↔backend integration point. This is net-new scope (not a
Gemini-parity restoration) — the same category of deliberate addition as
`unbias` in `skill/SKILL.md`.

## Problem

Today, `implement.md` step 3 and `workflow.md`'s "Phase checkpoint
procedure" pause for an explicit user "yes" at the end of **every**
phase, with no exceptions ("Nothing beyond a phase checkpoint is
finalized without that" — `workflow.md:88-89`). For a track made mostly
of `backend-logic`/`api-client` phases with fully automated test
coverage and no manual-verification steps, this pause adds friction
without adding safety: there's nothing for a human to look at that the
automated tests haven't already confirmed.

The friction should be removed for phases where a human check adds no
signal, while preserved for phases where it does — specifically, phases
that wire a frontend to a real backend call or exercise a full user
flow, where automated tests can confirm behavior exists but not that it
*feels* right.

## Goal

`/new-track` marks, at plan-generation time, which phases are expected
to need a human look. `/implement` trusts that mark: tagged phases keep
today's full manual-gate behavior; untagged phases checkpoint
immediately once their tests pass, no pause. The mark is plain text in
`plan.md`, so the user can add or remove it by hand at any time before
`/implement` reaches that phase's checkpoint step.

## Non-goals

- **No runtime judgment call.** `/implement` does not decide at
  checkpoint time whether a phase "could have been automated" (this
  was an earlier design iteration, discarded). The decision is static,
  made once by `/new-track`, and overridable only by editing `plan.md`.
- **No track-wide checkpoint-mode flag.** An earlier iteration proposed
  a `Checkpoint mode: manual` line applying to an entire track. Dropped
  in favor of per-phase tags, which are strictly more precise — tagging
  every phase in a track by hand achieves the same effect if truly
  needed.
- **`/implement` never auto-invokes `/review`, in any tagging
  combination.** Whether zero, some, or all phases were tagged, track
  completion still ends with `/implement` updating `tracks.md` to
  `Status: implementation complete — awaiting review` and telling the
  user to run `/review <track_id>` themselves. This matches today's
  behavior exactly; auto-transitioning into `/review` was considered
  and explicitly declined — it collapses two of the four deliberate
  lifecycle steps (`setup -> new-track -> implement -> review`) into
  one, and `/review` still has its own pause-and-ask gate before final
  closure, so auto-invoking it wouldn't remove a human decision, only
  relocate it while removing the point where the user chooses whether a
  full-track review is warranted right now.
- **No change to task-level execution.** The strict test-first/test-after
  loops, per-task commit procedure, and in-flight correction handling in
  `implement.md`/`workflow.md` are unchanged. Only the phase-boundary
  checkpoint step is affected.
- **No retroactive/runtime re-tagging by `/implement`.** If a phase
  turns out mid-run to need manual verification that wasn't anticipated
  (e.g. an unexpected external-service dependency), `/implement` does
  not add the tag on the fly. The tag is authored at plan time and
  edited by the user only; this keeps the mechanism auditable as a
  single, static source of truth in `plan.md` rather than a decision
  that can silently drift during a run.

## Design

### 1. The tag

A new bracketed tag on the phase heading, written by `/new-track`
alongside phase generation, sitting next to (and independent of) the
existing completion tag:

```
## Phase 4: Wire signup form to auth API [manual-checkpoint]
```

- **Untagged (default):** phase auto-checkpoints — no pause.
- **Tagged `[manual-checkpoint]`:** phase keeps today's full manual gate
  (summary, "Does this meet expectations?", pause, correction loop with
  3rd-round nudge, checkpoint only on explicit yes).

The tag and the completion tag coexist without format conflict:

| State | Heading |
|---|---|
| Tagged, not yet checkpointed | `## Phase 4: Wire signup form to auth API [manual-checkpoint]` |
| Tagged, checkpointed | `## Phase 4: Wire signup form to auth API [manual-checkpoint] [checkpoint: a1b2c3d]` |
| Untagged, checkpointed (today's format, unchanged) | `## Phase 3: Extract shared util [checkpoint: 9f0e1a2]` |

An untagged phase that auto-checkpoints ends up in the exact same
heading format a manually-checkpointed phase has today — no format
regression for anyone not using the new tag.

### 2. `/new-track`'s tagging heuristic

When generating `plan.md`, `/new-track` tags a phase `[manual-checkpoint]`
if either is true:

- The phase contains an `e2e-flow` task (inherently crosses layers,
  exercises a full user flow), **or**
- The phase contains a `frontend-ui` task **and** an
  `api-client`/`api-contract` task in the same phase — i.e., UI wired to
  a real backend call within that phase.

A phase with only `backend-logic`/`api-client`/`api-contract` tasks, or
only `frontend-ui` styling/layout tasks with no backend wiring in the
same phase, is left untagged.

These tags are visible in the plan the user already reviews during
`/new-track`'s existing plan-approval step — no separate approval
question is needed; the user can strike a tag during that same review,
or edit it later by hand.

### 3. `/implement`'s checkpoint step (replaces current step 3c/3d)

At the phase-checkpoint trigger (moment a phase's last task hits `[x]`),
`/implement` reads the phase heading:

- **Tagged `[manual-checkpoint]`:** unchanged from today — run phase
  tests, write out manual verification steps, present the phase summary,
  ask "Does this meet expectations? Reply yes to checkpoint and
  continue, or tell me what to change," pause and wait, loop on
  feedback (3rd-round nudge if repeated), checkpoint on explicit yes.
- **Untagged:** run phase tests, present the same phase summary plus one
  line — "No manual checkpoint required — auto-checkpointing" — then
  immediately run the phase checkpoint procedure (git note + append
  `[checkpoint: <sha>]`, exactly as today's mechanics) and continue to
  the next phase. No pause, no wait for a reply.

Nothing about the underlying checkpoint mechanics changes in either
branch — only whether `/implement` pauses for a reply.

### 4. Manual override

The tag is plain text in a git-tracked file, so:

- **Remove a tag:** delete `[manual-checkpoint]` from a phase heading
  before `/implement` reaches that phase's checkpoint step. `/implement`
  re-reads the heading fresh at checkpoint time — it has no memory of
  the tag ever being present — so the phase auto-checkpoints exactly
  like any other untagged phase.
- **Add a tag:** append `[manual-checkpoint]` to any untagged phase
  heading before `/implement` reaches it, forcing the manual gate for
  that phase even though `/new-track`'s heuristic didn't flag it.
- Edits are effective only for phases `/implement` has not yet
  checkpointed — a phase already checkpointed is done regardless of
  later heading edits (matches existing immutability of completed
  phases; `/revert` is the mechanism for undoing a checkpointed phase).

### 5. Track-end behavior

Unchanged in every tagging combination. Once all phases are
checkpointed (mixture of tagged/untagged, all tagged, or all untagged),
`/implement` performs today's step 4 exactly: update `tracks.md` to the
awaiting-review state, and tell the user the track is ready for
`/review <track_id>`, then stop. `/implement` never invokes `/review`.

## Interfaces / cross-file impact

- **`conductor/workflow.md`** — "Phase checkpoint procedure" section
  updated: replace the implicit "if anything can't be confirmed by an
  automated test" runtime judgment with the explicit tag-check rule;
  document the `[manual-checkpoint]` tag format alongside the existing
  `[checkpoint: <sha>]` format and the ordering shown in the table
  above.
- **`.opencode/command/implement.md`** — step 3 (currently 3a-3g)
  rewritten per Design §3: branch on tag presence instead of a runtime
  "can this be automated" judgment call at 3c.
- **`.opencode/command/new-track.md`** — phase-generation step gains the
  tagging heuristic from Design §2; tags are part of what the existing
  plan-approval gate already shows the user.
- **`.opencode/command/setup.md`** — mirrors `workflow.md`'s embedded
  copy of the phase checkpoint procedure (existing pattern in this repo
  keeps these two in sync); update identically.
- **`.opencode/command/status.md`** — verify `[manual-checkpoint]` does
  not interfere with the existing `[checkpoint: <sha>]` suffix detection
  used to flag missing checkpoints (`status.md:23-25`). The two tags are
  visually and positionally distinct brackets; `status.md`'s parsing
  should treat `[manual-checkpoint]` as pass-through.
- **`.opencode/command/revert.md`** — no mechanical change expected;
  reverting a phase strips its `[checkpoint: <sha>]` suffix per existing
  behavior (`revert.md:90`) and leaves any `[manual-checkpoint]` tag
  untouched, since that tag describes the phase's checkpoint *policy*,
  not its completion state.

## Testing / verification approach

Same two-layer convention as
`docs/superpowers/specs/2026-07-31-tier1-parity-design.md` and
`docs/superpowers/specs/2026-08-19-new-track-brainstorming-design.md`:
static checks plus behavioral fixture runs, since these are markdown
protocols interpreted by an LLM.

### Layer 1 — Static checks

- Grep `new-track.md` for the tagging heuristic (e2e-flow OR
  frontend-ui + api-client/api-contract pairing) in the phase-generation
  step.
- Grep `implement.md` and `workflow.md` for the tag-check branch
  replacing the old runtime judgment language, and for the
  `[manual-checkpoint]` format documented alongside `[checkpoint: <sha>]`.
- Read-through consistency: no stale references to a runtime
  "can this be automated" judgment call remain; no track-wide
  `Checkpoint mode` flag language was introduced; `implement.md` step 4
  (track-complete) still says to hand off to `/review` manually, in
  every branch.

### Layer 2 — Behavioral fixture runs

`opencode run --command <name> "<args>" --dir <fixture>` against
disposable git fixtures under `/tmp`, asserting on ground truth
(resulting `plan.md` content, checkpoint commits, git log), not
eyeballing.

| Scenario | Fixture precondition | Mechanical assertion |
|---|---|---|
| Untagged phase auto-checkpoints | Track with a phase containing only `backend-logic`/`api-client` tasks | After `/implement` runs that phase, `plan.md` shows `[checkpoint: <sha>]` with no pause/prompt observed in the run transcript |
| Tagged phase keeps manual gate | Track with a phase containing an `e2e-flow` task | `/new-track`'s generated `plan.md` shows `[manual-checkpoint]` on that heading; `/implement` pauses and requires an explicit yes before that phase's `[checkpoint: <sha>]` appears |
| Hand-edit removes the gate | Same as above, but user deletes `[manual-checkpoint]` from `plan.md` before running `/implement` | That phase auto-checkpoints with no pause, heading ends as plain `[checkpoint: <sha>]` |
| Hand-edit adds the gate | Track with an untagged `backend-logic`-only phase; user adds `[manual-checkpoint]` before running `/implement` | That phase pauses for explicit yes despite the heuristic not flagging it |
| Mixed track, no auto-review | Track with one tagged phase and one untagged phase | After both phases checkpoint, `tracks.md` shows the awaiting-review status and `/implement`'s final message names `/review <track_id>`; `/review` has **not** run (no review-report git note, no track-closure commit) |
| `status.md`/`revert.md` pass-through | Track with a `[manual-checkpoint]`-tagged, checkpointed phase | `/status` reports the phase as checkpointed with no false "missing checkpoint" flag; `/revert` on that phase strips `[checkpoint: <sha>]` but leaves `[manual-checkpoint]` intact |

## Risks / trade-offs

- **Heuristic can mis-tag.** A phase might get tagged `[manual-checkpoint]`
  when the human check adds no real value, or left untagged when it
  should have been flagged. Mitigated by the tag being visible in the
  plan-approval review and freely hand-editable at any point before that
  phase runs — the heuristic is a starting default, not a binding
  verdict.
- **Static tagging can't react to actual risk discovered mid-run.** If a
  phase turns out to need manual verification that wasn't anticipated at
  plan time, `/implement` does not add the tag itself (explicit
  non-goal, §"Non-goals"). The user must add it by hand before that
  phase's checkpoint, or accept the auto-checkpoint and use `/revert` if
  it turns out wrong.
- **No track-wide convenience toggle.** Tagging every phase in a track
  individually is more typing than a single track-wide flag would have
  been. Accepted — precision at the phase level was judged more valuable
  than the convenience of an all-or-nothing switch.
- **Behavioral fixture runs cost real tokens/time per scenario.**
  Accepted, consistent with prior specs in this repo — static checks
  alone can't verify LLM-interpreted protocol behavior.
