---
description: Generate a new Conductor track with a concise shortname_YYYYMMDD ID, spec, phased plan, metadata, and registry entry after setup and before implementation begins
agent: build
---

`/conductor/new-track` is the second step in the Conductor lifecycle: `/conductor/setup -> /conductor/new-track -> /conductor/implement -> /conductor/review`.

Read `conductor/index.md` first, and use it to locate the workflow and tracks registry before creating any track.

If `conductor/index.md` is missing, stale, or does not point to the expected workflow and tracks registry, stop and repair the handshake through `/conductor/setup` before creating the track.

If `conductor/tracks.md` is missing, stop and route back to `/conductor/setup` rather than recreating setup-owned handshake state during `/conductor/new-track`.

Before starting, run the read-only merge-proof checks from `/conductor/cleanup` (its Step 3) on the other `track/*` worktrees from `git worktree list`. For each one that passes all four checks, print one line: ``Branch `<branch>` is merged. Run `/conductor/cleanup` to remove it.`` Do not remove anything here, and do not block track creation on this.

## 1. Track brainstorming

Treat `$ARGUMENTS` as a **seed** for this step, not a final description and not the track's shortname. If `$ARGUMENTS` is empty, ask the user for a brief description of what they want to build before continuing. Infer and confirm the track type (feature, bug, chore, refactor, MVP) before continuing — independently of whether the rest of this step's brainstorming loop runs or is skipped.

**Skip hatch:** if the user's request explicitly says the spec is already decided and to skip brainstorming (e.g. "skip brainstorming", "spec is already decided"), do not run the loop below — proceed directly to Step 2 using `$ARGUMENTS` as the final description, exactly as this command behaved before this step existed.

Otherwise, run the following loop before generating a track ID or creating any artifact:

1. **Draft understanding.** From the seed, identify the purpose, constraints, and success criteria as currently understood.
   - **Domain-language and scenario pass:** identify domain-significant terms that may have multiple meanings. Compare each with existing project terminology and inspect relevant code or documentation. Use concrete scenarios to distinguish meanings. Ask the user only when the distinction affects behavior or scope; otherwise choose a precise term and use it consistently in the draft. Do not create a glossary for every track; record ordinary clarifications in the draft spec and promote terminology to durable project documentation only when it matters across tracks.
2. **Find, classify, and order decision forks.** Do three things internally (do not narrate this mechanism to the user — only its results):
   - **Mental `/conductor/implement` dry-run:** walk the draft spec as if implementing it, task by task. Every point where you would have to guess, or where `/conductor/implement` would have to stop and ask the user, is a decision fork.
   - **Ambiguity-category checklist:** confirm each of the following is resolved or explicitly not applicable: data shapes/models, external or internal API contracts, error handling and failure paths, edge cases and boundaries, acceptance/success criteria, tech and library choices, out-of-scope boundaries, test expectations. Any unresolved category is a decision fork.
   - **Fact-versus-decision classification:** classify every unresolved item as `FACT`, `DECISION`, or `MIXED`.
     - `FACT`: investigate it through the repository, available tools, or primary documentation. Research only when a FACT or MIXED fork depends on external documentation or another verifiable prerequisite; do not ask the user to provide information the agent can verify. For material external findings, use primary sources where available and record the source with concise findings in the draft spec.
     - `DECISION`: ask the user because the answer depends on preference, scope, risk tolerance, or a trade-off.
     - `MIXED`: resolve the factual prerequisite first using primary sources where available, then present the remaining choice to the user and record material sources in the draft spec with concise findings.
     - If sources conflict or are unavailable, explain the uncertainty and present the remaining risk as a user-owned decision rather than silently selecting an implementation assumption. Research informs the decision; it does not silently make it. Small lookups do not require a separate research report; a concise source note in the draft is sufficient, while substantial research may be linked as a separate report.
   - **Design tree and frontier:** model the unresolved items as a design tree. Each fork is a node; record what each fork depends on. The **frontier** is the set of unresolved forks whose prerequisites are settled. Work only on frontier items: resolve frontier `FACT` items, resolve the factual part of frontier `MIXED` items, and ask about one frontier `DECISION` at a time. Recompute the frontier after every fact lookup or user answer. Do not ask a decision whose prerequisites remain unresolved.
   - If both the dry-run and the checklist come back clean, and all factual prerequisites have been resolved, there are no more forks — go to step 4.
3. **Resolve forks, one question at a time.** For each fork:
   - Before asking a question, resolve any factual prerequisite yourself. If sources disagree or the fact cannot be established, explain the uncertainty and present the remaining risk as a user-owned decision. Never turn an unverified fact into an assumed implementation choice.
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
6. **Present the design** (the drafted spec content) to the user and ask for approval. If they ask for changes, revise and re-present — loop with no round cap until they approve. This is Gate A; it is separate from, and earlier than, the pause-for-approval in Step 7 below — approving here does not start `/conductor/implement`, it only unlocks artifact creation in Step 3.

Do not proceed to Step 2 until either the skip hatch was used, or Gate A above has an explicit approval.

## 2. Generate the track ID

Using the approved understanding from Step 1 (not the raw seed, if it changed during brainstorming), derive a concise **shortname**: a 2-4 word kebab-case slug that summarizes the track (e.g. "Add user authentication with OAuth" → `user-auth`). Do not use the full description as the shortname.

Compose the **track ID** as `<shortname>_YYYYMMDD`, where `YYYYMMDD` is today's date (e.g. `user-auth_20260728`).

**Collision check:** list the existing directories under `conductor/tracks/`. If a directory with the generated track ID already exists, do not overwrite it — ask the user with a single-choice question whether to provide a unique name or resume the existing track. Only proceed once the track ID is unique or the user has chosen to resume.

## 2.5. Create the track's worktree

### Detect an existing track worktree (reuse mode)

A refinement track (for example, fixing review feedback on an open PR) lives
on the PR's existing branch. Never create a worktree inside a worktree.

The current directory is a track worktree when all of these hold:

- it is a linked worktree: `git rev-parse --absolute-git-dir` differs from
  `git rev-parse --path-format=absolute --git-common-dir` (they are equal in
  the main checkout);
- the current branch matches `track/*`;
- `conductor/` exists in this checkout.

If it is not a track worktree, skip this subsection and continue below
unchanged.

If it is, check the branch's PR state first:

- GitHub: `gh pr view <branch> --json state --jq .state`.
- GitLab (best effort): `glab mr list --source-branch <branch> --all -F json --jq '.[0].state'`.

If the state is `MERGED`, `merged`, or `CLOSED`/`closed`, do not reuse the
worktree. Stop, explain that this branch's PR is finished, and point to
`/conductor/cleanup` or to running `/conductor/new-track` from the main
checkout. If there is no PR yet or the provider CLI is unavailable, continue.

Never reuse silently. Ask a single-choice question: **Refine this branch's PR
here**, or **Stop — I'll start a separate track from the main checkout**. Only
an explicit "refine here" enters **reuse mode**. If more than one earlier
track exists in this worktree (active under `conductor/tracks/` or archived
under `conductor/archive/`), also ask which one is being refined.

In reuse mode:

- Do not run `git worktree add` and do not create a branch.
- `worktreePath` is the current worktree and `branch` is the current branch.
- `baseBranch` and `baseRef` are copied from an existing track's
  `metadata.json` in this worktree (an active track first, otherwise the
  newest `conductor/archive/*/metadata.json`). Do not read them from `HEAD`,
  which is the track branch itself. If none can be found, stop and ask.
- Record `"refines": "<track_id>"` in `metadata.json` for the track chosen
  above, when there is one.
- Steps 3 onward run in the current directory.

Reuse mode is entered only through this detection and the user's explicit
answer, never as a fallback after a failed `git worktree add`.

### Create a new worktree (outside reuse mode)

Before creating the worktree, determine the branch `HEAD` currently
points to: `git rev-parse --abbrev-ref HEAD`. If this returns the
literal string `HEAD` (a detached-HEAD state, not on any branch), stop
and ask the user to check out a branch first — do not guess or record
a bogus branch name. Otherwise, record this as `baseBranch` — the
actual branch name (e.g. `main`), distinct from `baseRef` below (a
commit SHA). `baseBranch` is what a later PR should target; `baseRef`
is only used for merge-detection SHA ranges, not as a `gh pr create`
argument.

Every track gets its own isolated git worktree and branch, created from
current `HEAD`, so parallel tracks never contend for the same working
directory or registry file:

```bash
git worktree add .worktrees/<track_id> -b track/<track_id>
```

If this command fails — the worktree path or branch already exists,
the directory is not a git repository, or any other git error — stop
immediately and report the exact git error verbatim to the user. Do
not fall back to creating the track in the current worktree, and do
not silently overwrite or reuse an existing worktree/branch (the reuse
mode above is the only sanctioned reuse, and requires the user's answer).

On success, record the base commit SHA that `HEAD` pointed to
immediately before running this command — this is `baseRef`, written
into `metadata.json` in Step 3. All remaining steps in this command
(Step 3 onward) run inside the new worktree at `.worktrees/<track_id>`,
not in the directory `/conductor/new-track` was invoked from.

## 3. Create the track artifacts

Under the generated track ID, inside the worktree created in Step 2.5,
create:

- `conductor/tracks/<track_id>/spec.md`
- `conductor/tracks/<track_id>/plan.md`
- `conductor/tracks/<track_id>/metadata.json`

Write `spec.md` using the exact content approved in Step 1's Gate A (do not re-draft it here), including its two provenance sections.

`metadata.json` records the track ID, type, status (`new`), created/updated timestamps, and the worktree fields from Step 2.5: `worktreePath` (`.worktrees/<track_id>`), `branch` (`track/<track_id>`), `baseBranch` (the branch name `HEAD` was on before worktree creation — used as the PR base branch), and `baseRef` (the base commit SHA recorded in Step 2.5 — used only for merge-detection, not as a PR base). In reuse mode, `worktreePath` is the current worktree rather than `.worktrees/<track_id>`, `baseBranch`/`baseRef` are inherited as described in Step 2.5, and `refines` names the track being refined when one was chosen. If Step 1's "Open questions auto-decided by agent — PLEASE DOUBLE-CHECK" section is non-empty, also record `"needsReview": true` in `metadata.json`.

Planning is first-class: `/conductor/new-track` must produce an approved `spec.md` and `plan.md` before implementation begins. Require task-type tags on every plan task for workflow enforcement (see `conductor/workflow.md`). Write every task line as `- [ ] Task: <description> [<task-type>]` and every phase heading as `## Phase <N>: <title>` — `/conductor/implement` and `/conductor/review` complete these into `- [x] Task: <description> [<task-type>] <sha>` and `## Phase <N>: <title> [checkpoint: <sha>]` per `conductor/workflow.md`'s task commit procedure.

**Phase checkpoint tagging:** when writing each phase heading, tag it `## Phase <N>: <title> [manual-checkpoint]` if the phase contains an `e2e-flow` task, or contains both a `frontend-ui` task and an `api-client`/`api-contract` task (i.e. a UI wired to a real backend call within that phase). Otherwise leave the heading untagged: `## Phase <N>: <title>`. Untagged is the default — `/conductor/implement` auto-checkpoints untagged phases without pausing (see `conductor/workflow.md`'s phase checkpoint procedure). These tags are visible in the plan the user already reviews before approval; the user may add or remove `[manual-checkpoint]` on any phase heading by hand at any time before `/conductor/implement` reaches that phase's checkpoint step.

## 4. Update the registry

Add a new entry to `conductor/tracks.md` under `## Active` that links to the track by its generated ID and uses the human-readable description as the entry label, e.g.:

`- [ ] **Track: <description>** *Link: [tracks/<track_id>/plan.md](./tracks/<track_id>/plan.md)*`

If `metadata.json` was written with `"needsReview": true`, append `— **needs review: contains auto-decided open questions**` to the entry label so this is visible directly in the registry.

## 5. Commit the new track

Stage `conductor/tracks/<track_id>/` and `conductor/tracks.md`, then
commit with the message `chore(conductor): initialize track '<track_id>'`.
This is the anchor commit `/conductor/revert` uses to find and undo an entire
track.

## 6. Announce readiness

Tell the user, in a short summary: the ambiguity-category checklist categories that were resolved vs. marked not-applicable (the readiness summary — do not show the dry-run reasoning itself), and whether `spec.md` contains any agent-auto-decided open questions that need double-checking.

## 7. Pause for approval

Tell the user the generated track ID, the worktree path (`.worktrees/<track_id>`) they should `cd` into before running the next command (in reuse mode they are already in the right worktree, so no `cd` is needed), and that the next step is `/conductor/implement <track_id>` run from inside that worktree. Pause for approval before `/conductor/implement`. Do not invoke `/conductor/implement` yourself under any circumstances — this command ends here and the user must separately run `/conductor/implement`.
