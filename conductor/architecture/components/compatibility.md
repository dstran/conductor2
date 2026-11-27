# Compatibility Surfaces

## Purpose

Expose the shared Conductor doctrine to additional agent ecosystems without
creating competing workflow definitions.

## Responsibilities

- Package the canonical skill and applicable command/asset trees for compatible
  hosts.
- Keep compatibility metadata and wrappers aligned with canonical doctrine.

## Key interfaces

- Gemini extension manifest and bundled surface.
- Claude, Codex, and Antigravity skill discovery locations populated by installer.

## Depends on / Used by

- Depends on `skill/SKILL.md`, command documents, installer behavior, and shared
  project assets.
- Used by users who install the compatibility surface in another host.

## Code paths

- `gemini-extension.json`
- `.github/copilot-instructions.md`
- `.github/agents/`
- `install.sh`
- `skill/SKILL.md`

## Gotchas

- OpenCode is the supported target; copied surfaces are compatibility support,
  not independently implemented workflows.
