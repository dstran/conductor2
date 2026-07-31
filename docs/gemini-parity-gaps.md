# Gemini Conductor → OpenCode Port: Parity Gaps

Tracks behavioral gaps between the upstream Gemini Conductor extension
(`github.com/gemini-cli-extensions/conductor`) and this OpenCode port.
Goal: the port should reproduce all upstream behaviors and intentions.

Upstream reference commit: cloned from `main` (129 commits, VERSION per repo).
Upstream structure: `skills/conductor-{setup,new-track,implement,review,status,revert}/SKILL.md`
+ `skills/conductor-setup/assets/workflow.md` + `rules/conductor_antigravity.md`
+ `skills/conductor-setup/scripts/resume.py` + `assets/catalog.md`.

Status legend: `[ ]` open · `[~]` in progress · `[x]` done · `[skip]` intentionally not ported.

---

## Tier 1 — Restore core Conductor behavior

- [ ] **G1. Doc-sync phase in `implement`** *(highest impact)*
  - Upstream: `conductor-implement §4` — after a track completes, re-read the
    track `spec.md` and propose user-confirmed diffs to `product.md`,
    `tech-stack.md`, and `product-guidelines.md` (product-guidelines strictly
    controlled), then commit `docs(conductor): Synchronize docs for track '<id>'`.
  - Port: no doc-sync step at all. Project context files go stale after every track.
  - Files: `.opencode/command/implement.md:82-94`

- [ ] **G6. Record commit SHAs into `plan.md`** *(unblocks G5)*
  - Upstream: phase heading gets `[checkpoint: <sha>]`; each `[x]` task line gets
    the 7-char task SHA appended. `revert`/`review` depend on these SHAs.
  - Port: attaches git notes (good) but never writes SHAs back into `plan.md`,
    breaking the data contract revert/review rely on.
  - Files: `.opencode/command/implement.md:73-78`; workflow commit strategy.

- [ ] **G5. Flesh out `revert` mechanism**
  - Upstream: `conductor-revert` — target selection (direct vs. guided top-3 menu),
    find implementation commits by SHA in `plan.md`, handle ghost/rewritten-history
    commits, find associated plan-update commits, find track-creation commit for
    full-track reverts, Safe (`git revert`) vs. Hard-reset (`git reset --hard`)
    strategy choice, conflict handling, post-revert plan-state verification.
  - Port: 11 lines of intent, no mechanism.
  - Files: `.opencode/command/revert.md:1-11`

- [ ] **G4. `status` parses plans + reports progress**
  - Upstream: `conductor-status` reads registry AND every track's `plan.md`; reports
    date, project health, current phase/task, next action, blockers, total phases,
    total tasks, and `completed/total (percentage%)`.
  - Port: only summarizes registry entries; no plan parsing, counts, %, or next action.
  - Files: `.opencode/command/status.md:8-14`

---

## Tier 2 — Data-contract / cross-tool compatibility

- [ ] **G3. Per-track handshake `index.md`**
  - Upstream: `new-track §2.4` creates `conductor/tracks/<id>/index.md` linking
    spec/plan/metadata; registry entry links to `index.md`; downstream skills
    resolve spec/plan via that track index.
  - Port: links directly to `plan.md`, never creates per-track `index.md`.
  - Files: `.opencode/command/new-track.md:30-42`

- [ ] **G12. Commit at track creation**
  - Upstream: `new-track` commits `chore(conductor): initialize track '<id>'`.
  - Port: creates artifacts and pauses, never commits; revert's "find track-creation
    commit" step has nothing to find.
  - Files: `.opencode/command/new-track.md:44-46`

- [ ] **G11. Commit-message convention alignment**
  - Upstream: `chore(conductor): Mark track '<desc>' as in progress`/`as complete`,
    `chore(conductor): initialize track '<id>'`, `docs(conductor): Synchronize docs...`,
    `conductor(plan): Mark task ... complete`.
  - Port: `conductor(checkpoint): ...`, `conductor(track): ...`. Internally consistent
    but incompatible with upstream + revert's message-matching heuristics.
  - Files: `conductor/workflow.md:74-91`; `.opencode/command/setup.md` embedded workflow.

- [ ] **G13. Commit `[~]` "in progress" registry state before work**
  - Upstream: `implement §3.2` marks track `[~]` and commits before starting tasks.
  - Port: marks `[~]` in-flight; first commit is the phase-1 checkpoint.
  - Files: `.opencode/command/implement.md`

---

## Tier 3 — Optional subsystems (decide keep vs. drop)

- [ ] **G2. Interactive skill-recommendation system (`catalog.md`)**
  - Upstream: `setup §2.6` + `new-track §2.4` analyze project against `assets/catalog.md`,
    recommend agent skills (Firebase/GCP/etc.), disclose 1p/3p trust, warn on 3p,
    `curl`-install into `.agents/skills/`, pause for env reload; `implement`/`review`
    detect and activate installed skills.
  - Port: absent entirely.

- [ ] **G7. Review action-menu + diff suggestions**
  - Upstream: `review §3.1` — when issues found, three-way menu (Apply Fixes /
    Manual Fix / Complete Track); findings include suggested `diff` blocks.
  - Port: correction loop always appends a "Review Fixes" phase and agent implements;
    no apply-diff / manual / ignore fork, no diff-formatted suggestions.
  - Files: `.opencode/command/review.md:75-99`

- [ ] **G9. `## Capabilities` section in `index.md` (ties to G2)**
  - Upstream: index conditionally includes `## Capabilities` → `.agents/skills/`.
  - Port: never emitted.
  - Files: `.opencode/command/setup.md:179-197`; `conductor/index.md`

- [ ] **G10. Antigravity "View Layer UX Adapter" rule**
  - Upstream: `rules/conductor_antigravity.md` — use native `ask_question` GUI modal
    when available, text-menu fallback otherwise.
  - Port: intent met via OpenCode `question` tool; no explicit doctrine binding all
    commands to always use it (only `setup.md` is explicit).

- [ ] **G8. `setup` resumption script** *(functionally equivalent already)*
  - Upstream: `resume.py` computes `next_step`, fast-forwards to first missing artifact.
  - Port: inline shell loop does the equivalent (`setup.md:22`). Low priority.

---

## Port improvements over upstream (keep — do not regress)

- Per-task-type test enforcement table (test-first / test-after / none) —
  more rigorous than upstream's generic ">80% coverage, always-TDD" template.
- Explicit approval gates in `implement` (per-phase) and `review` (closure),
  no-cap correction loop + 3rd-round nudge.
- Git notes for reports instead of commit bodies — cleaner `git log`.
  (But restore G6: plan.md SHA recording that revert needs.)
- `unbias` contract in `skill/SKILL.md` — genuine addition, not in upstream.
