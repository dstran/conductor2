# Swift Code Style Guide

This guide separates Swift API design guidance from a project's formatting
and engineering policies. It applies to project-owned Swift code, including
libraries and native modules, not just iOS user interfaces.

## Sources and Authority

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):
  naming, clarity at the point of use, conventions, and documentation.
- [swiftlang/swift-format](https://github.com/swiftlang/swift-format):
  formatting tooling and configuration, not a universal official Swift style.
- The project's approved configuration and documented engineering decisions
  govern formatting, architecture, concurrency, and error-handling policies.
  Do not label those local choices as Apple requirements.

## API Clarity

- Prioritize clarity at the call site over brevity. Review representative uses,
  not just declarations.
- Include words needed to disambiguate a call; omit needless words that merely
  repeat type information. Name parameters and variables for their roles.
- Use argument labels that make calls readable and distinguish argument roles.
  Omit labels only where the API guidelines' conventions justify it, such as
  value-preserving conversions or indistinguishable arguments.
- Use `UpperCamelCase` for types and protocols and `lowerCamelCase` for other
  declarations. Follow established acronym casing consistently.
- Nonmutating Boolean properties and methods read as assertions, such as
  `isEmpty` or `contains(_:)`. Capability protocols use appropriate `able`,
  `ible`, or `ing` suffixes; protocols naming a thing use nouns.
- Name side-effecting methods with imperative verbs. Use consistent
  mutating/nonmutating pairs such as `sort()` / `sorted()` and
  `formUnion(_:)` / `union(_:)`.
- Use established terminology; avoid obscure or nonstandard abbreviations.

## Documentation

- Document APIs with Swift documentation comments explaining their meaning,
  behavior, and return values. Start with a concise summary; describe important
  parameters, errors, preconditions, and side effects where needed.
- If an API cannot be explained clearly, reconsider its design rather than
  disguising ambiguity with a longer comment.
- Document computed properties with nonconstant complexity so callers do not
  mistake expensive work for ordinary stored-property access.

## Formatting and Verification

- Preserve existing formatter/linter choices and configuration, including
  `.swift-format`, `.swiftformat`, and `.swiftlint.yml` where present.
  SwiftLint and Nick Lockwood's SwiftFormat are distinct tools from
  `swiftlang/swift-format`; do not interchange their commands or configs.
- If no formatter is established, recommend `swiftlang/swift-format` and
  confirm the user's choice. Its default formatting is one possible style,
  **not an official universal Swift coding standard**.
- Verify the available tool/version and its help before recording a project
  check command in `conductor/tech-stack.md`. Swift 6 toolchains include
  `swift format`; a standalone installation may expose `swift-format`.
  Do not assume either exists or understands syntax newer than its parser.
- With a confirmed compatible tool, a non-mutating enforcement check may use
  `swift format lint --strict <project-owned-paths>` or
  `swift-format lint --strict <project-owned-paths>`; add `--recursive` when
  checking directories. Strict mode makes style warnings fail the check.
  Use the project's actual paths and configuration, not a blind scan of
  generated code or vendored dependencies.
- A lint check is not a formatting run. Never use `--in-place` during review
  or reformat a repository without explicit approval.
- Report a missing tool or unrun check as **not verified**, not as a pass.
  Do not silently install tools or invent successful output.

## Engineering Policy Is Separate

Use the confirmed Swift version, supported platforms, architecture, testing
strategy, concurrency model, and error-handling rules recorded by the project.
Raise conflicts for approval rather than importing a new app architecture,
blanket `@MainActor` policy, or force-unwrap rule as an alleged API guideline.
