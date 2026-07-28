---
name: conductor
description: Use the canonical Conductor doctrine from skill/SKILL.md together with the packaged command and artifact surface under .opencode/command/ and conductor/.
tools: ["read", "edit", "search", "shell"]
---

Use `skill/SKILL.md` as the canonical Conductor doctrine.

When working in this repository:

- Read `skill/SKILL.md` first.
- Command docs live in `.opencode/command/`.
- Shared lifecycle artifacts live in `conductor/`, including `conductor/workflow.md` and `conductor/tracks.md`.
- `install.sh` installs the OpenCode package surface under `~/.opencode/conductor/` and the Gemini extension surface under `~/.gemini/extensions/conductor/`.
- Treat `AGENTS.md` and `.github/copilot-instructions.md` as compatibility shims, not independent doctrine.
- If a wrapper conflicts with `skill/SKILL.md`, follow `skill/SKILL.md` and repair the wrapper.
- Keep the repository minimal. Do not add extra mirrors, wrappers, or host-specific doctrine files unless explicitly requested.
- Treat `gemini-extension.json` as host metadata only.
