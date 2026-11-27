# conductor2

An OpenCode port of the Conductor spec-driven development workflow.

Conductor's lifecycle is `setup -> new-track -> implement -> review`, backed by
per-project state under a `conductor/` directory. `/conductor/archive` is the
optional recovery cleanup for a reviewed track when the review Archive choice
is no longer available.

- Canonical doctrine: `skill/SKILL.md`
- OpenCode command docs: `.opencode/command/*.md`
- Bundled code style guides: `conductor/assets/code_styleguides/`
- Shared lifecycle artifact templates: `conductor/index.md`, `conductor/workflow.md`, `conductor/tracks.md`

## Install / update (always latest)

Install or update to the latest version from GitHub with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh | bash
```

Run the same command again any time to update. It keeps a cache clone at
`~/.cache/conductor2` (honoring `$XDG_CACHE_HOME`), syncs it to the latest, and
runs the installer. Then restart your AI shell.

Overrides (environment variables):

- `CONDUCTOR_REF` — branch or tag to install (default `main`).
- `CONDUCTOR_REPO` — git URL to clone (default `https://github.com/dstran/conductor2.git`).

Prefer to inspect before running remote code? Download, read, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh -o install-latest.sh
less install-latest.sh
bash install-latest.sh
```

## Install from a local clone

Run the installer from **outside** this source tree (it refuses to run from the
repository root):

```bash
cd /path/to/some/other/dir
/path/to/conductor2/install.sh
```

Then restart your AI shell so it picks up the new commands and skill.

The installer writes Conductor's skill and OpenCode commands to
`~/.config/opencode/`. It also happens to write the same skill file to a few
other tools' discovery locations, since they share a common `SKILL.md`
format — but OpenCode is the only target this project builds and tests
against:

| Tool | Installed to |
| --- | --- |
| OpenCode (commands) | `~/.config/opencode/command/conductor/*.md` |
| OpenCode (style-guide assets) | `~/.config/opencode/command/conductor/assets/code_styleguides/` |
| OpenCode (skill) | `~/.config/opencode/skills/conductor/SKILL.md` |
| Claude *(incidental)* | `~/.claude/skills/conductor/SKILL.md` |
| Codex *(incidental)* | `~/.codex/skills/conductor/SKILL.md` |
| Gemini CLI *(incidental)* | `~/.gemini/extensions/conductor/` |
| Antigravity *(incidental)* | `~/.gemini/antigravity/skills/conductor/SKILL.md` |

Re-running the installer cleanly replaces the installed files.

## Usage

After installing and restarting, the lifecycle is exposed as namespaced slash
commands. Run them in your own project's directory:

- `/conductor/setup` — initialize the project: an interactive interview that
  audits the codebase, defines `product.md`, `product-guidelines.md`, and
  `tech-stack.md`, copies matching code style guides, writes `workflow.md`, and
  builds the `conductor/index.md` handshake.
- `/conductor/new-track` — plan a new track (spec + phased plan + registry entry).
- `/conductor/implement` — implement an approved track phase-by-phase.
- `/conductor/review` — review a completed track before closing it.
- `/conductor/archive` — safely recover review cleanup: synchronize the track
  branch, move it to `conductor/archive/`, commit, and push the archive.
- `/conductor/cleanup` — remove a merged track's worktree and local branch
  after confirming the pull request was merged.
- `/conductor/status` — summarize active, blocked, and archived tracks.
- `/conductor/revert` — revert a track, phase, or task.
- `/conductor/update` — sync `conductor/workflow.md` with the currently
  installed doctrine, if it has changed since `/setup` ran.

Setup creates the project state under `conductor/` in your working directory;
later commands read and update it.

## Design planning and platform standards

The lifecycle is unchanged. Material UI changes are designed during
`/conductor/new-track`, **before** specification/implementation-plan approval
and `/conductor/implement`:

```text
draft requirements -> design alternatives -> user selection/revisions
-> confirmed design brief -> approved spec and plan -> implementation
```

- **Web:** prefer the optional [Impeccable](https://impeccable.style/) skill's
  planning-only `shape` workflow. Conductor preserves applicable design
  alternatives, your selection, and revision rounds; requirements approval
  is not visual-direction approval. Narrow refinements preserve the established
  design, and approved external designs can be reused.
- **iOS / Android:** use Apple HIG / Android design guidance. Cross-platform
  apps share product intent but honor each deployment platform's interactions.
  Impeccable is not automatically invoked for native work.
- **No UI change:** backend/tooling tracks record design as not applicable;
  established-pattern fixes need only a short justification, not a design exercise.

For consuming web projects, setup offers optional Impeccable initialization
after product and stack approval. It verifies current-session skill discovery.
If unavailable, choose assisted installation, official instructions, or
continuation without it. Installation requires separate approval of the command,
source, local/global scope, and configuration effects; the Conductor installer
does **not** bundle or automatically install Impeccable. A required agent restart
defers initialization without blocking setup.

With the skill available, opt into `init` to reuse approved product context and
confirm only gaps/conflicts. Existing valid `PRODUCT.md` is reused; it is derived
context linking back to Conductor's approved sources, not competing requirements.
`init` does not establish a visual design or create `DESIGN.md`. If skipped, the
first relevant web design track can resume the handoff. Direct design planning
remains available when Impeccable is unavailable or declined. Browser previews
and live variants depend on its available tooling and a runnable project.

Track worktrees start from committed `HEAD`, not uncommitted files in the
original checkout. Before branching, Conductor checks only the explicitly
selected durable product/design context and references; if any are missing or
uncommitted, it stops for a selective-commit decision. It never stages or
copies those files automatically. Secrets, machine-local configuration, and
temporary Impeccable runtime/preview state are excluded. The destination
worktree is checked again before planning continues.

The selected direction, states, references, platform decisions, and acceptance
criteria live in track-local `design.md` when applicable. Implementation reads
them; review checks rendered behavior and platform/accessibility evidence.
Unavailable checks are **not verified**, not passes. Missing required evidence
blocks closure unless the requirement is explicitly revised with approval.

For project-owned Swift code, setup recommends the bundled `swift` guide:
Swift API Design Guidelines for naming/API clarity, plus the project's selected
formatter. Existing tools/configuration are preserved; `swiftlang/swift-format`
is recommended only when no formatter is established. Its default formatting
is not a universal official Swift style. Swift selection is independent of
whether the project has an iOS UI.
