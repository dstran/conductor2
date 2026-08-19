# Per-Feature Brainstorming in `/new-track` — Design

Adds a per-track design-discovery step to `/new-track`. This is net-new
scope (not a Gemini-parity restoration — upstream `new-track` has no
equivalent; the closest, G2 skill-catalog recommendation, is Tier 3 and
undecided in `docs/gemini-parity-gaps.md`). It is the same category of
deliberate addition as the `unbias` contract in `skill/SKILL.md`.

## Problem

`/new-track` currently takes `$ARGUMENTS` as a given description and
formalizes it directly into a track ID, `spec.md`, `plan.md`, and
`metadata.json` (`new-track.md:14-42`). No alternatives are explored, no
assumptions are surfaced, and no design is agreed before commitment.

Conductor has rich *project-level* discovery (`setup.md`'s interactive
interview → `product.md`/`tech-stack.md`/`product-guidelines.md`,
`setup.md:12-13,36,41-55`) but nothing analogous at the *per-track* level.
A vague or wrong premise in `$ARGUMENTS` becomes a fully committed,
registry-tracked, test-enforced plan. Conductor's downstream machinery
(typed tasks, TDD enforcement, phase checkpoints, git-anchored revert)
*amplifies* the cost of a bad premise: the wrong thing gets built well,
and correcting it costs a `/revert` plus re-planning rather than one
clarifying question up front.

A second, sharper failure mode: an ambiguous `spec.md` forces `/implement`
to **stop mid-run and ask the user** (`implement.md:37-38,49-52`),
defeating the purpose of the formal pipeline.

## Goal

The new brainstorming step does not finish until `spec.md` is
**implementation-ready**, defined precisely as:

> `/implement` → `/review` could run start-to-finish without stopping to
> ask the user anything.

Exploration is **unbounded on real decision forks** — there is no "propose
2-3 approaches" cap. Options are presented wherever a genuine decision
fork exists, as many forks as exist, no more.

## Non-goals

- **`/new-track` never auto-invokes `/implement`.** "Implementation-ready"
  is a property of the *spec*, not a *trigger*. Step 6's existing
  pause-and-hand-back-to-user behavior (`new-track.md:51-53`) is preserved
  and terminal: `/new-track` ends by telling the user the track ID and
  that the next step is `/conductor/implement <track_id>`, then stops. The
  user must separately initiate `/implement`. "Autonomy" throughout this
  document means `/implement` does not stop to ask questions *once the
  user has started it* — never that `/new-track` starts it.
- No scope-decomposition step for oversized/multi-subsystem descriptions
  (explicitly declined).
- No visual-companion / browser mockup tool (declined — conductor tracks
  skew backend/logic per `workflow.md`'s task types; scope creep against a
  repo doctrine of staying minimal).
- No change to the mechanics of `/implement`, `/review`, `/revert`,
  `/status`, or `workflow.md`'s test-enforcement/commit procedures. The new
  `spec.md` provenance sections (below) are additive and ignored by
  existing parsers.

## Design

### 1. Flow position and framing

The brainstorming step becomes **step 1** of `/new-track`, before track-ID
generation:

```
0. Read handshake (unchanged: index.md / tracks.md checks, new-track.md:8-12)
1. NEW: Zero-ambiguity brainstorming (this document)
   - $ARGUMENTS is a SEED, not a locked title. If empty, ask for one
     (existing behavior, now feeding the dialogue instead of being final).
   - Explicit skip hatch: if the user signals "spec is decided, skip
     brainstorming", treat $ARGUMENTS as final and jump to step 2
     (today's behavior, preserved).
2. Generate track ID  — now derived from the APPROVED understanding, not
   raw $ARGUMENTS (the dialogue may change what's being built).
3. Create track artifacts — write the already-approved spec.md verbatim,
   then plan.md + metadata.json (existing mechanics: task-type tags, etc.).
4. Update registry (unchanged).
5. Commit new track (unchanged anchor commit).
6. Pause for approval — "track ready, next is /implement" (existing,
   UNCHANGED, terminal — does NOT start /implement).
```

Rationale for seed-not-locked timing: the track ID is baked into the
directory path, the `tracks.md` registry entry, and every commit message
referencing `<track_id>`. If the shortname were generated from the raw
seed before the dialogue, it would permanently misdescribe an approved
spec that the dialogue changed. This mirrors `setup.md`, which holds the
Greenfield answer as an "Initial Concept" seed and only formalizes
`product.md` after its interview concludes (`setup.md:36-43`).

### 2. Exit gate — dual verification (BOTH must pass)

The step terminates only when both of the following clear. Both run
**internally**; the user sees only the resulting clarifying questions and,
at the end, a short readiness summary (which checklist categories were
resolved vs. marked N/A).

**(a) Mental `/implement` dry-run.** The agent walks the draft spec as if
implementing it, task by task. Every point where it would have to *guess*
or *stop and ask the user* becomes a required decision fork to resolve.
The loop repeats until a full dry-run surfaces zero stop-and-ask points.

**(b) Ambiguity-category checklist.** Every category is either resolved or
explicitly marked N/A:

- data shapes / models
- external or internal API contracts (request/response shape)
- error handling and failure paths
- edge cases and boundaries
- acceptance / success criteria
- tech and library choices
- out-of-scope boundaries (what this track will NOT do)
- test expectations (what proves each task done)

These map onto `workflow.md`'s task types — e.g. an unresolved API
contract is exactly what makes an `api-client`/`api-contract` task stop
mid-`/implement`; missing acceptance criteria is what makes `/review`
unable to confirm the spec was met.

### 3. Per-fork interaction model (replaces "2-3 approaches" entirely)

At each fork with more than one viable option, the agent presents the
options with trade-offs and a recommendation, asking **one question at a
time** (consistent with `setup.md`'s established interview style). A fork
with only one sane option is simply stated, not offered as a choice.

Per fork, the user may:

1. **Answer it** — normal path.
2. **"You decide this one"** — agent picks a sane default, records it in
   `spec.md`'s assumptions section, moves on.
3. **"You decide the rest"** — agent resolves all remaining forks with
   recorded decisions.
4. **"I don't know / don't care"** — treated as (2): agent decides +
   records, never stalls.
5. **"Exit brainstorming now"** — agent auto-decides *everything still
   open* (as in 3), records each in the double-check section, ends the loop.

Absent options 2-5, the loop is genuinely **unbounded** — it keeps asking
until every fork is answered.

### 4. Provenance sections in `spec.md`

To keep the autonomy guarantee honest, `spec.md` gains two sections. A
fully user-answered spec leaves both empty.

- `## Assumptions & agent-made decisions` — every fork the agent closed on
  the user's behalf during normal flow (option 2), each with the chosen
  value and a one-line rationale.
- `## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK` —
  populated only on "decide the rest" / early exit (options 3 and 5): every
  remaining fork the agent closed without a specific user answer, flagged
  loudly for review. When this section is non-empty, `metadata.json` and
  the `tracks.md` entry are marked so the user knows the spec — while
  implementation-ready — contains unreviewed auto-decisions.

Net effect: the spec is **always** implementation-ready at the end of the
step (satisfying the goal), but the document never hides *how* it got
there.

### 5. Spec self-review (before presenting the design)

After drafting `spec.md` and before the design-approval gate, the agent
does a quick inline pass — placeholder scan (no "TBD"/"TODO"), internal
consistency, ambiguity check — and fixes issues inline. No re-review loop.
(Mirrors superpowers brainstorming step 7.)

### 6. Two distinct, sequential gates — both return control to the user

- **Gate A (new, end of step 1):** spec is implementation-ready and
  self-reviewed → present the design → user approves (loop on revision
  requests, no cap) → proceed to artifact creation (steps 2-5), still
  inside `/new-track`.
- **Gate B (existing step 6, unchanged, terminal):** artifacts committed →
  tell the user the track ID and that the next step is `/implement` →
  **`/new-track` ends.** The user separately initiates `/implement`.

Neither gate triggers `/implement`.

## Interfaces / cross-file impact

- Only `.opencode/command/new-track.md` changes structurally: new step 1,
  steps 2-6 renumbered/re-anchored, ID generation moved to consume the
  approved understanding, skip hatch added.
- `conductor/workflow.md`, `implement.md`, `review.md`, `revert.md`,
  `status.md`: **no change**. The artifacts they consume (`spec.md`,
  `plan.md`, track-ID format) are unchanged in *shape*; the two new
  `spec.md` provenance sections are additive markdown headings that
  existing consumers ignore.
- `skill/SKILL.md:29-34` ("Planning Discipline") already asserts
  `new-track` produces an *approved* `spec.md`/`plan.md` before
  implementation. This change makes "approved" substantive (a real
  zero-ambiguity dialogue) rather than nominal (a single pause after
  artifacts already exist). No doctrine wording needs to change, though a
  one-line pointer may be added.
- `docs/gemini-parity-gaps.md`: log this in "Port improvements over
  upstream" as a genuine addition (same treatment as `unbias`), so the
  parity ledger stays honest that this is not upstream behavior.

## Testing / verification approach

Same two-layer convention as `docs/superpowers/specs/2026-07-31-tier1-parity-design.md`:
these are markdown protocols interpreted by an LLM, so "does it parse"
(static) and "does it behave" (live) are different questions and both are
required.

### Layer 1 — Static checks

- Grep `new-track.md` for: the new step-1 heading, the dual-gate wording
  (mental dry-run + checklist), the per-fork option set, the two provenance
  section headers, and the skip hatch.
- Read-through consistency: step renumbering is internally consistent; no
  stale step references; Gate B's "next step is /implement, pause" text is
  intact and no auto-invoke language was introduced.

### Layer 2 — Behavioral fixture runs

`opencode run --command new-track "<args>" --dir <fixture>` against
disposable git fixtures under `/tmp`, asserting on ground truth (resulting
`spec.md` content, track ID, `git log`), not eyeballing.

| Scenario | Fixture precondition | Mechanical assertion |
|---|---|---|
| Vague seed → forks then implementation-ready spec | fresh `conductor/` from `/setup`, deliberately vague `$ARGUMENTS` | run asks ≥1 clarifying question; final `spec.md` has no `TBD`/`TODO`; both provenance sections present (may be empty); no track artifacts created before design approval |
| **Core property: chained autonomy** | run `/new-track` (answering all forks), then run `/implement` on the produced track | `/implement` runs to completion with **zero** clarifying questions to the user |
| "Exit now" mid-loop | vague seed, user says "exit brainstorming now" after a couple of forks | `spec.md` is still complete AND `## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK` is **non-empty**; `metadata.json`/`tracks.md` entry carries the flag |
| Skip hatch (regression guard) | user invokes with "skip brainstorming, spec is decided" + detailed `$ARGUMENTS` | zero clarifying questions asked; track ID + artifacts created directly, matching today's behavior |
| No auto-start (guard for this whole doc's Non-goal) | any successful `/new-track` run | after the run, `/implement` has **not** executed: no phase/task commits exist beyond the `chore(conductor): initialize track` anchor; the run's final message tells the user to run `/implement` next |

Interactive prompts inside these runs are steered by stating intended
answers directly in the `opencode run` message. Any unexpected
permission-request/halt during a fixture run is itself a failure of that
scenario.

## Risks / trade-offs

- **Unbounded loop can be long.** A genuinely under-specified track with
  many forks means many questions. Mitigated by options 2-5 (delegate one,
  delegate rest, exit) — the user is never forced to answer everything.
- **"Zero ambiguity" is a judgment the agent makes about itself.** The dual
  gate (concrete `/implement` dry-run tied to an observable downstream
  event, plus a fixed checklist) is what makes it auditable rather than
  "the agent decided it was tired of asking." The Layer-2 chained-autonomy
  test measures the exact claimed property mechanically.
- **Auto-decided specs can be wrong.** The double-check section + track
  flag make that visible rather than silent; `/review` still catches spec
  non-compliance downstream.
- **Added turns on every track** (unless skipped). Accepted: the cost
  asymmetry favors resolving a fork in one turn now over a `/revert` +
  re-plan later.
- **Behavioral fixture runs cost real tokens/time per scenario.** Accepted
  — static checks alone cannot verify LLM-interpreted protocol behavior,
  and the chained-autonomy run is the only real evidence the goal is met.
