# conductor2

An OpenCode port of the Conductor spec-driven development workflow.

Conductor's lifecycle is `setup -> new-track -> implement -> review`, backed by
per-project state under a `conductor/` directory.

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
- `/conductor/status` — summarize active, blocked, and archived tracks.
- `/conductor/revert` — revert a track, phase, or task.
- `/conductor/update` — sync `conductor/workflow.md` with the currently
  installed doctrine, if it has changed since `/setup` ran.

Setup creates the project state under `conductor/` in your working directory;
later commands read and update it.
