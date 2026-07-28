# Copilot Instructions

This repository keeps canonical Conductor doctrine in `skill/SKILL.md` and ships the current command/artifact surface alongside it.

- Read `skill/SKILL.md` before changing doctrine, workflow, or host compatibility behavior.
- Command docs live in `.opencode/command/`.
- Shared lifecycle artifacts live in `conductor/`, including `conductor/workflow.md` and `conductor/tracks.md`.
- `install.sh` exposes that surface under `~/.opencode/conductor/` and bundles the Gemini extension surface under `~/.gemini/extensions/conductor/`.
- Keep Copilot-facing files thin. They exist to route Copilot to `skill/SKILL.md` and the packaged surfaces, not to redefine Conductor.
- If `AGENTS.md`, `.github/copilot-instructions.md`, or `.github/agents/*.agent.md` drift from `skill/SKILL.md`, update them to match `skill/SKILL.md`.
- `gemini-extension.json` is host metadata, not doctrine.
