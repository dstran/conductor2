# Verification Baseline and Readable Implementation

**Type:** Feature

## Setup

- Discover existing checks from project scripts, CI, configuration, and supported
  language/framework versions. Keep working tools and avoid duplicate coverage.
- Recommend missing, applicable deterministic checks using official guidance for
  those versions: formatting, linting, type checking or compilation, and tests.
  Show the source, exact commands, dependencies, and configuration changes.
- Obtain approval before installing tools or changing configuration. Run agreed
  checks and record each exact command, scope, and required or deferred status
  in `conductor/tech-stack.md`. Agree on an adoption plan for existing failures
  before making the affected check required.
- Provide an explicit verification-only mode in the existing setup command for
  initialized projects. Skip the product interview and preserve established
  tools and unrelated project context.

## Implement and Review

- Before each code-task commit, apply the relevant style guides to the task
  diff. Read from the caller's perspective; fix unclear names, needless
  indirection, redundant comments, and missed clearer supported idioms. Keep
  useful API documentation and comments explaining non-obvious constraints.
- Use a Gang of Four pattern only when it solves a concrete problem the code has
  today. Follow established conventions for judgment calls and ask before
  changing an approved contract or architecture.
- Run applicable required checks and rerun affected checks after edits. Report
  unresolved trade-offs and distinguish failed, deferred, and unverified checks.
- At review, run the full agreed baseline, including track-only checks. Report
  deferred or unverified checks separately from passes.

## Boundaries

This is workflow tooling; application UI design is not applicable. The workflow
makes the checks repeatable; it does not promise identical generated code.
Keep the existing lifecycle and test enforcement. No blanket reformatting,
mandatory universal toolchain, or numeric readability quotas.

## Assumptions & agent-made decisions

- Use the existing Conductor track structure and `Verification Commands` section.

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK

None.
