# Deterministic Review Request Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a deterministic GitHub/GitLab request-creation dispatcher for the Archive phase of `/conductor/review`, with stable fallback behavior.

**Architecture:** A standalone POSIX shell script owns remote parsing, provider selection, CLI invocation, and fallback output. The review command remains orchestration-only and passes metadata plus the review report to the script. A shell test harness supplies fake `git`, `gh`, and `glab` executables so parser and dispatch behavior can be tested without network access or provider credentials.

**Tech Stack:** POSIX shell, Git, GitHub CLI (`gh`), GitLab CLI (`glab`), shell test harness.

## Global Constraints

- Preserve the existing Archive-only request-creation gate.
- Match only exact hosts `github.com` and `gitlab.com`; treat all other hosts as unsupported.
- Support both `git@host:owner/repo.git` and `https://host/owner/repo.git` remote forms.
- Use body-file flags rather than interpolating report content into shell command text.
- Never merge a pull request or merge request automatically.
- Do not change Delete or Skip cleanup behavior.

---

### Task 1: Add Deterministic Request Dispatcher

**Files:**
- Create: `conductor/scripts/open-pr.sh`
- Create: `conductor/scripts/test-open-pr.sh`

**Interfaces:**
- Consumes: four positional arguments: `<source-branch> <target-branch> <title> <body-file>`; the current repository's `origin` remote; `git`, `gh`, and `glab` executables resolved from `PATH`.
- Produces: exit status `0` when a provider CLI creates the request; exit status `1` when fallback instructions are printed; no request creation for unsupported remotes or failed prerequisites.

- [ ] **Step 1: Write the failing shell tests**

Create a temporary fake executable directory and test harness that invokes the
dispatcher from a temporary Git repository. The fake `git` returns a selected
remote URL for `git remote get-url origin`; fake provider CLIs record arguments
and return configurable statuses. Include assertions equivalent to:

```sh
run_case github_ssh 0 \
  'git@github.com:owner/repo.git' gh \
  'gh pr create --base main --head track/demo --title Demo --body-file /tmp/review.md'
run_case github_https 0 \
  'https://github.com/owner/repo.git' gh \
  'gh pr create --base main --head track/demo --title Demo --body-file /tmp/review.md'
run_case gitlab_ssh 0 \
  'git@gitlab.com:owner/repo.git' glab \
  'glab mr create --source-branch track/demo --target-branch main --title Demo --description-file /tmp/review.md'
run_case gitlab_https 0 \
  'https://gitlab.com/owner/repo.git' glab \
  'glab mr create --source-branch track/demo --target-branch main --title Demo --description-file /tmp/review.md'
run_fallback 'https://forge.example/owner/repo.git' 'unsupported host'
run_fallback 'https://github.com/owner/repo.git' 'git push -u origin track/demo'
run_provider_failure github 'https://github.com/owner/repo.git'
```

The assertions must also verify that the body path is passed as one argument,
that the unselected provider is never called, and that fallback output names
the parsed host when one is available.

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```sh
sh conductor/scripts/test-open-pr.sh
```

Expected: FAIL because `conductor/scripts/open-pr.sh` does not exist yet.

- [ ] **Step 3: Implement the minimal dispatcher**

Implement `conductor/scripts/open-pr.sh` with `set -eu`, argument-count and
body-file validation, and a strict remote parser covering exactly these forms:

```sh
git@HOST:PATH
https://HOST/PATH
```

Extract `HOST`, map only `github.com` and `gitlab.com`, and emit one fixed
fallback function containing the source branch and `git push -u origin` command.
Use command existence checks plus exit status checks for authentication. Invoke
the provider commands exactly as follows:

```sh
gh pr create --base "$target" --head "$source" \
  --title "$title" --body-file "$body_file"
glab mr create --source-branch "$source" --target-branch "$target" \
  --title "$title" --description-file "$body_file"
```

Route every non-zero auth or creation result to fallback and return `1`.

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```sh
sh conductor/scripts/test-open-pr.sh
```

Expected: PASS for both remote URL forms, both providers, unsupported hosts,
missing/auth-failing CLIs, and provider command failures.

- [ ] **Step 5: Run shell syntax checks**

Run:

```sh
sh -n conductor/scripts/open-pr.sh conductor/scripts/test-open-pr.sh
```

Expected: no syntax errors.

- [ ] **Step 6: Commit the dispatcher and tests**

```sh
git add conductor/scripts/open-pr.sh conductor/scripts/test-open-pr.sh
git commit -m "feat(conductor): dispatch review requests by remote host"
```

### Task 2: Wire Review Archive Cleanup to the Dispatcher

**Files:**
- Modify: `.opencode/command/review.md:145-167`

**Interfaces:**
- Consumes: Task 1's `conductor/scripts/open-pr.sh <source> <target> <title> <body-file>` interface and the existing `metadata.json` `branch`/`baseBranch` fields.
- Produces: deterministic Archive-only instructions that report script success or its explicit fallback output while preserving human-only merge approval.

- [ ] **Step 1: Update the review command instructions**

Replace the GitHub-only `gh auth status` and `gh pr create` instructions with
instructions to create a temporary body file from
`conductor/tracks/$ARGUMENTS/review.md`, invoke the dispatcher with the recorded
`branch`, `baseBranch`, and track description, and report its output. State that
the dispatcher detects `origin` in SSH or HTTPS form, supports exact
`github.com`/`gitlab.com` matches, and emits manual instructions for all other
hosts or command failures. Keep the existing no-PR behavior when either branch
field is missing and the existing statement that Conductor never merges.

- [ ] **Step 2: Review the resulting documentation for lifecycle invariants**

Confirm the edited section still says all of the following:

```text
request creation occurs only after Archive
Delete and Skip do not create a request
missing branch/baseBranch skips request creation
Conductor creates but never merges
```

- [ ] **Step 3: Run the focused dispatcher tests and documentation checks**

Run:

```sh
sh conductor/scripts/test-open-pr.sh
git diff --check
```

Expected: dispatcher tests pass and Git reports no whitespace errors.

- [ ] **Step 4: Commit the review wiring**

```sh
git add .opencode/command/review.md
git commit -m "docs(conductor): use remote-aware review request dispatcher"
```

### Task 3: Full Verification

**Files:**
- Verify: `conductor/scripts/open-pr.sh`
- Verify: `conductor/scripts/test-open-pr.sh`
- Verify: `.opencode/command/review.md`

**Interfaces:**
- Consumes: all implementation changes from Tasks 1 and 2.
- Produces: evidence that the full repository checks and deterministic dispatcher checks pass.

- [ ] **Step 1: Run the focused and repository-wide checks**

Run:

```sh
sh conductor/scripts/test-open-pr.sh
sh -n conductor/scripts/open-pr.sh conductor/scripts/test-open-pr.sh
git diff --check HEAD~2..HEAD
```

Expected: all commands exit successfully.

- [ ] **Step 2: Inspect the final diff**

Run:

```sh
git status --short
git diff HEAD~2..HEAD -- conductor/scripts .opencode/command/review.md
```

Confirm no unrelated files changed, no secrets are present, and the review
command still limits request creation to Archive cleanup.
