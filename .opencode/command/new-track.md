---
description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/new-track` is the second step in the Conductor lifecycle: `setup -> new-track -> implement -> review`.

Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/setup` rather than recreating setup-owned handshake state during `/new-track`.

## 1. Track brainstorming

Treat `$ARGUMENTS` as a **seed** for this step, not a final description and not the track's shortname. If `$ARGUMENTS` is empty, ask the user for a brief description of what they want to build before continuing.

**Skip hatch:** if the user's request explicitly says the spec is already decided and to skip brainstorming (e.g. "skip brainstorming", "spec is already decided"), do not run the loop below — proceed directly to Step 2 using `$ARGUMENTS` as the final description, exactly as this command behaved before this step existed.

Otherwise, run the following loop before generating a track ID or creating any artifact:

1. **Draft understanding.** From the seed, identify the purpose, constraints, and success criteria as currently understood.
2. **Find decision forks.** Do two things internally (do not narrate this mechanism to the user — only its results):
   - **Mental `/implement` dry-run:** walk the draft spec as if implementing it, task by task. Every point where you would have to guess, or where `/implement` would have to stop and ask the user, is a decision fork.
   - **Ambiguity-category checklist:** confirm each of the following is resolved or explicitly not applicable: data shapes/models, external or internal API contracts, error handling and failure paths, edge cases and boundaries, acceptance/success criteria, tech and library choices, out-of-scope boundaries, test expectations. Any unresolved category is a decision fork.
   - If both the dry-run and the checklist come back clean, there are no more forks — go to step 5.
3. **Resolve forks, one question at a time.** For each fork:
   - If there is more than one viable option, present the options with trade-offs and your recommendation, then ask.
   - If there is exactly one sane option, state it — do not offer it as a choice.
   - The user may respond in one of four ways:
     - **Answer the question** — record the answer and continue to the next fork.
     - **"You decide this one" (or "I don't know" / "I don't care")** — pick the option you recommended (or the only sane one), record it under a running "Assumptions & agent-made decisions" list (value + one-line rationale), and continue.
     - **"You decide the rest"** — for every fork still open (this one and all remaining), pick the recommended/sane option and record each under a running "Open questions auto-decided by agent" list (value + one-line rationale). Stop asking and go to step 4.
     - **"Exit brainstorming now"** — treat exactly like "you decide the rest": auto-decide everything still open, record each, stop asking, go to step 4.
   - Repeat step 2 (re-check the dry-run and checklist against the now-updated draft) after each answered fork — resolving one fork can surface new ones. There is no cap on how many rounds this takes.
4. **Draft `spec.md` content** from the fully-resolved understanding. Include, verbatim as section headers:
   - `## Assumptions & agent-made decisions` — every fork resolved via "you decide this one"/"I don't know", each as a bullet: the decision and a one-line rationale. Leave the header with no bullets beneath it if this never happened.
   - `## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK` — every fork resolved via "you decide the rest"/"exit brainstorming now", each as a bullet: the decision and a one-line rationale. Leave the header with no bullets beneath it if this never happened.
5. **Self-review the draft once**, inline, before presenting it: scan for placeholders ("TBD", "TODO", incomplete sections), internal contradictions, and any requirement that could be read two ways — fix issues directly in the draft, no separate re-review pass.
6. **Present the design** (the drafted spec content) to the user and ask for approval. If they ask for changes, revise and re-present — loop with no round cap until they approve. This is Gate A; it is separate from, and earlier than, the pause-for-approval in Step 7 below — approving here does not start `/implement`, it only unlocks artifact creation in Step 3.

Do not proceed to Step 2 until either the skip hatch was used, or Gate A above has an explicit approval.

## 2. Generate the track ID

Using the approved understanding from Step 1 (not the raw seed, if it changed during brainstorming), derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.

Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).

**Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.

## 3. Create the track artifacts

Under the generated track ID, create:

- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`

Write `spec.md` using the exact content approved in Step 1's Gate A (do not re-draft it here), including its two provenance sections.

`metadata.json` records the track ID, type, status (`new`), and created/updated timestamps. If Step 1's "Open questions auto-decided by agent — PLEASE DOUBLE-CHECK" section is non-empty, also record `"needsReview": true` in `metadata.json`.

Planning is first-class: `/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/implement` and `/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.

## 4. Update the registry

Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:

`- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

If `metadata.json` was written with `"needsReview": true`, append `— **needs review: contains auto-decided open questions**` to the entry label so this is visible directly in the registry.

## 5. Commit the new track

Stage `conductor/tracks/<track_id>/` and `conductor/tracks.md`, then
commit with the message `chore(conductor): initialize track '<track_id>'`.
This is the anchor commit `/revert` uses to find and undo an entire
track.

## 6. Announce readiness

Tell the user, in a short summary: the ambiguity-category checklist categories that were resolved vs. marked not-applicable (the readiness summary — do not show the dry-run reasoning itself), and whether `spec.md` contains any agent-auto-decided open questions that need double-checking.

## 7. Pause for approval

Tell the user the generated track ID and that the next step is `/conductor/implement <track_id>`. Pause for approval before `/implement`. Do not invoke `/implement` yourself under any circumstances — this command ends here and the user must separately run `/implement`.
