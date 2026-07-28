# Install OpenCode Wiring Fix — Design

## Goal

Fix `install.sh` so that after a user runs it, OpenCode actually discovers and
exposes the Conductor slash commands and the `conductor` skill. Today the
installer copies these files to locations OpenCode never scans, so the port is
non-functional in OpenCode.

Scope is **OpenCode only**. The Claude, Codex, Gemini CLI, and Antigravity
install paths are intentionally left unchanged.

## Verified OpenCode Discovery Behavior

Confirmed against the installed opencode `1.18.8` binary and the official docs
(`opencode.ai/docs/commands`, `/docs/skills`):

- Global config directory is `~/.config/opencode` (not `~/.opencode`).
- Commands are loaded with the glob `{command,commands}/**/*.md` under config
  directories. The command name is derived by taking the file path relative to
  the config dir, stripping the leading `command/` (or `commands/`) segment, and
  stripping the `.md` extension.
  - Therefore `command/conductor/setup.md` registers as `/conductor/setup`.
  - Subdirectory namespacing is supported because the glob recurses (`**`).
- Skills are loaded from `~/.config/opencode/skills/<name>/SKILL.md`. The
  directory name must match the `name` in the SKILL.md frontmatter (`conductor`).

## Current (Broken) Behavior

`install.sh` currently does, for OpenCode:

- `install_skill_flavor "$HOME/.opencode/skill/conductor"` — wrong base dir
  (`~/.opencode` vs `~/.config/opencode`) and wrong folder (`skill` vs `skills`).
- `install_packaged_surface "$HOME/.opencode/conductor"` — copies the repo's
  `.opencode/` and `conductor/` trees under `~/.opencode/conductor/`, producing
  `~/.opencode/conductor/.opencode/command/*.md`, which is not a discovery path.

Result: no `/setup`, `/new-track`, `/implement`, `/review`, `/status`,
`/revert`, and no auto-discovered `conductor` skill in OpenCode.

## Target Behavior

After install, the following exist and are discoverable by OpenCode:

- Skill: `~/.config/opencode/skills/conductor/SKILL.md`
- Commands (namespaced under `conductor/`):
  - `~/.config/opencode/command/conductor/setup.md` → `/conductor/setup`
  - `~/.config/opencode/command/conductor/new-track.md` → `/conductor/new-track`
  - `~/.config/opencode/command/conductor/implement.md` → `/conductor/implement`
  - `~/.config/opencode/command/conductor/review.md` → `/conductor/review`
  - `~/.config/opencode/command/conductor/status.md` → `/conductor/status`
  - `~/.config/opencode/command/conductor/revert.md` → `/conductor/revert`

The shared `conductor/` artifacts (`index.md`, `workflow.md`, `tracks.md`) are
**not** copied into any global OpenCode location. At runtime the command docs
reference `@conductor/index.md` etc., which resolve relative to the user's
project working directory, and `/setup` generates those artifacts per project.
Global copies would be dead files.

Nothing is written under `~/.opencode/` by the OpenCode install path anymore.

## Implementation

In `install.sh`:

- Add `install_opencode_surface()` that:
  - Writes the skill to `~/.config/opencode/skills/conductor/SKILL.md`.
  - Copies `$ROOT/.opencode/command/*.md` into
    `~/.config/opencode/command/conductor/`.
  - Removes/recreates only those two target directories so re-running is clean,
    without clobbering the user's unrelated `~/.config/opencode` contents.
- Replace the two OpenCode lines (`install_skill_flavor "$HOME/.opencode/..."`
  and `install_packaged_surface "$HOME/.opencode/conductor"`) with a single call
  to `install_opencode_surface`.
- Leave `install_skill_flavor` (Claude, Codex, Antigravity) and
  `install_gemini_flavor` (Gemini CLI) untouched.
- Remove `install_packaged_surface`, which now has no callers.

## Verification

1. Run the installer into a sandbox `HOME`.
2. Assert these files exist:
   - `~/.config/opencode/skills/conductor/SKILL.md`
   - `~/.config/opencode/command/conductor/{setup,new-track,implement,review,status,revert}.md`
3. Assert nothing was written under `~/.opencode/`.
4. Assert the Claude/Codex/Gemini/Antigravity targets are still produced as
   before.

## Non-Goals

- Changing command doctrine or the `conductor/` artifact contents.
- Touching non-OpenCode install flavors beyond leaving them working as-is.
- Fixing the other parity gaps (archive step, setup scaffolding, status/revert
  depth) — those are separate tracks.
