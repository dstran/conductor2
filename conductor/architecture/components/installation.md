# Installation and Distribution

## Purpose

Install Conductor's commands, doctrine, guides, and helper assets into supported
agent discovery locations.

## Responsibilities

- Copy owned command, skill, guide, and helper files.
- Preserve unrelated configuration while refreshing Conductor-owned surfaces.
- Keep optional third-party integrations separate from Conductor installation.

## Key interfaces

- `install.sh` for local source installation.
- `install-latest.sh` for latest-version installation.

## Depends on / Used by

- Depends on the repository asset layout and the user's selected agent homes.
- Used by project maintainers and consuming projects.

## Code paths

- `install.sh`
- `install-latest.sh`
- `gemini-extension.json`
- `.opencode/command/`
- `skill/`
- `conductor/assets/`
- `conductor/scripts/`

## Gotchas

- Installation mutates user-level tool configuration; it is not a test or
  read-only verification command.
- Impeccable installation and initialization require separate consent.
