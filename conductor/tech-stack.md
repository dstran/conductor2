# Technology Stack

## Project Structure

- Markdown: canonical doctrine, OpenCode commands, compatibility wrappers,
  lifecycle templates, and code style guides.
- Shell: installers, review-request dispatcher, and regression test harnesses.
- Python 3: archive recovery helper, using the standard library.
- Git: branches, worktrees, commits, and notes for track lifecycle state.
- GitHub CLI / GitLab CLI: provider-specific pull-request integration.

## Key Paths

- `skill/SKILL.md`: canonical doctrine.
- `.opencode/command/`: OpenCode lifecycle command instructions.
- `conductor/assets/`: bundled guides and workflow template.
- `conductor/scripts/`: lifecycle helpers and their tests.
- `install.sh` and `install-latest.sh`: local and latest-version installation.

## Verification Commands

Run from the repository root:

| Command | Scope |
| --- | --- |
| `sh conductor/scripts/test-open-pr.sh` | Review dispatcher regression tests |
| `sh conductor/scripts/test-archive-track.sh` | Archive helper regression tests |

These scripts create temporary repositories and stub external provider
commands. They require a shell and Git; archive tests also require Python 3.

No application build command or repository-wide lint command has been
identified. The installer is not a build or a read-only verification command:
it changes user-level tool configuration and must not be run as a substitute
for tests.

## Application Platforms

This repository is workflow tooling, not a web, iOS, or Android application.
Guidance for those platforms is distributed as project-facing assets and
instructions where supported; it does not define this repository's runtime.
