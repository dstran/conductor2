# Deterministic Review Request Creation

## Context

The `/conductor/review` command currently creates a pull request only during
Archive cleanup and assumes the repository is hosted on GitHub. The workflow
should support GitHub pull requests and GitLab merge requests while keeping
provider selection and command construction deterministic for both HTTPS and
SSH remotes.

## Goals

- Preserve the existing Archive-only request-creation gate.
- Detect the provider from the `origin` remote without relying on agent
  interpretation of prose.
- Support common HTTPS and SSH remote URL forms.
- Use the provider's native CLI with explicit branch, title, and body values.
- Provide stable manual fallback instructions for unsupported environments or
  command failures.
- Make the dispatch logic independently testable.

## Non-goals

- Automatically merging a pull request or merge request.
- Supporting arbitrary self-hosted GitHub or GitLab instances in the first
  version.
- Changing the behavior of Delete or Skip cleanup choices.
- Making external state such as network availability or existing requests
  deterministic.

## Design

Add a small repository script, `conductor/scripts/open-pr.sh`, accepting the
source branch, target branch, title, and review-report body file. The script
will:

1. Read `origin` with `git remote get-url origin`.
2. Parse the host from supported SSH and HTTPS forms using one strict parser.
3. Map exact hosts to providers:
   - `github.com` -> GitHub
   - `gitlab.com` -> GitLab
   - all other hosts -> unsupported
4. Check the corresponding CLI using exit status:
   - `gh auth status --hostname github.com`
   - `glab auth status`
5. Invoke the provider-specific command with body-file input:
   - GitHub: `gh pr create --base <target> --head <source> --title <title> --body-file <body-file>`
   - GitLab: `glab mr create --source-branch <source> --target-branch <target> --title <title> --description-file <body-file>`
6. On unsupported hosts, missing or unauthenticated CLIs, or request-creation
   failures, print a fixed fallback containing `git push -u origin <source>`
   and instructions to open the request manually. Return a non-zero status for
   fallback so the command caller can report the outcome explicitly.

The script will avoid interpolating the report body into a shell command. The
caller will pass the existing review report file and metadata values directly
as arguments. It will retain the current requirement that both `branch` and
`baseBranch` exist before request creation is attempted.

Update `.opencode/command/review.md` so Archive cleanup invokes the script and
reports whether it created a request or emitted fallback instructions. The
documentation will continue to state that Conductor never merges requests.

## Error Handling

The script will treat every non-zero prerequisite or CLI result as a fallback
condition. It will not silently discard an unsupported host, authentication
failure, missing executable, network error, or already-existing request. The
manual instructions will include the parsed host when available; otherwise
they will identify the host as unknown.

## Testing

Test the script without requiring live provider access by injecting or mocking
Git commands and provider CLIs. Cover:

- GitHub HTTPS and SSH remote parsing.
- GitLab HTTPS and SSH remote parsing.
- Unsupported host fallback.
- Missing or unauthenticated CLI fallback.
- Correct provider-specific flags and body-file handling.
- Provider command failure fallback.
- Successful command exit status for each provider.
- Missing branch or base branch handling at the workflow boundary.

## Scope

The implementation is limited to the new dispatch script, its focused tests,
and the review command documentation. No changes are needed to track metadata,
new-track behavior, or cleanup semantics.
