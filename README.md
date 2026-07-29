# conductor2

An OpenCode port of the Conductor spec-driven development workflow, with
compatibility packaging for Claude, Codex, Gemini CLI, and Antigravity.

Conductor's lifecycle is `setup -> new-track -> implement -> review`, backed by
per-project state under a `conductor/` directory.

- Canonical doctrine: `skill/SKILL.md`
- OpenCode command docs: `.opencode/command/*.md`
- Bundled code style guides: `conductor/assets/code_styleguides/`
- Shared lifecycle artifact templates: `conductor/index.md`, `conductor/workflow.md`, `conductor/tracks.md`
- `gemini-extension.json` is Gemini host metadata, not doctrine

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

The installer writes to each supported tool's discovery location:

| Tool | Installed to |
| --- | --- |
| OpenCode (commands) | `~/.config/opencode/command/conductor/*.md` |
| OpenCode (style-guide assets) | `~/.config/opencode/command/conductor/assets/code_styleguides/` |
| OpenCode (skill) | `~/.config/opencode/skills/conductor/SKILL.md` |
| Claude | `~/.claude/skills/conductor/SKILL.md` |
| Codex | `~/.codex/skills/conductor/SKILL.md` |
| Gemini CLI | `~/.gemini/extensions/conductor/` |
| Antigravity | `~/.gemini/antigravity/skills/conductor/SKILL.md` |

Re-running the installer cleanly replaces the installed files.

## Usage (OpenCode)

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

Setup creates the project state under `conductor/` in your working directory;
later commands read and update it.
