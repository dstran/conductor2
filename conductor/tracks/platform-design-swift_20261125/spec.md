## Proposed feature specification

**Title:** Platform-aware design gates and Swift standards
**Type:** Feature

### Design checkpoint
Keep `setup → new-track → implement → review` unchanged.

During `new-track`, before specification and implementation-plan approval:
- Material changes to user flows, navigation, interaction, or visual structure require an approved design brief.
- Established-pattern fixes can record a short justification instead.
- Approved external designs can satisfy the checkpoint; discovery need not be repeated.

### Platform routing
- **Web:** prefer Impeccable `shape` when available. Otherwise, produce the same brief directly.
- **iOS:** use Apple HIG.
- **Android:** use Android design guidance.
- **Cross-platform:** share product intent while documenting platform-specific behavior.
- Do not install Impeccable automatically or invoke it for native work unless requested.

### Design artifacts
Use track-local `design.md` for user tasks, flows, significant states, layout intent, accessibility, references, and acceptance criteria.

`spec.md` remains requirements authority; `plan.md` incorporates the approved design work. Reuse existing product/design documentation without creating competing sources of truth.

### Swift standards
Add a bundled Swift guide and recommend it during setup for Swift projects:
- Swift API Design Guidelines for naming and API clarity.
- Preserve existing formatting tools and configuration.
- Prefer `swift-format` when no formatter is established; record the confirmed check command.
- Clearly distinguish official guidance from project-specific engineering policies.

The `swift-format` project explicitly says its default formatting is **not a universal official Swift style**; the guide will preserve that distinction.

### Implementation and review
- Implementation reads applicable design decisions and style guides.
- Web review checks rendered responsive behavior and accessibility.
- Native review checks simulator/device behavior, text scaling, accessibility, and platform interactions.
- Report unavailable checks as **not verified**, never as passes.
- Missing evidence for a required acceptance criterion prevents closure until resolved or explicitly revised with approval.

### Boundaries and verification
No new top-level command, mandatory design dependency, automatic reformatting, or implementation of an actual app.

Verify routing and lifecycle instructions against scenarios covering web with/without Impeccable, native, cross-platform, backend-only, existing designs, existing Swift tooling, and unavailable verification tools. Run existing regression suites and an isolated installer smoke test.

## Assumptions & agent-made decisions

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK
