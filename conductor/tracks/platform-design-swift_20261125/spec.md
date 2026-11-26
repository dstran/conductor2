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

### Optional Impeccable initialization
- For web projects, after Conductor's product context and tech stack are approved and before setup completes, offer `/impeccable init` when the skill is available. Run it only with explicit opt-in.
- Pass approved Conductor context into the handoff and ask only about material gaps or conflicts, rather than repeating the product interview.
- Conductor's approved context and track specifications remain requirements authority. Impeccable's `PRODUCT.md` is its derived product context and links back to the applicable Conductor sources. Reconcile conflicts explicitly; never silently overwrite existing product context.
- Initialization captures product truth; it does not establish the visual design or create `DESIGN.md`. Honor the skill's own confirmation and configuration-consent steps.
- If initialization was skipped during setup, offer it before the first web design track that needs Impeccable's new-design flow. Confirm that a valid `PRODUCT.md` exists before proceeding to `shape`; preserve an existing valid record without reinitializing unnecessarily.
- If the skill is unavailable or initialization is declined, complete the design brief directly without Impeccable. Backend-only and native tracks do not trigger this optional handoff.

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

Verify routing and lifecycle instructions against scenarios covering web with/without Impeccable, setup initialization accepted/skipped/declined, first-use initialization, existing or conflicting `PRODUCT.md`, native, cross-platform, backend-only, existing designs, existing Swift tooling, and unavailable verification tools. Run existing regression suites and an isolated installer smoke test.

## Assumptions & agent-made decisions

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK
