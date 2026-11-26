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

### Optional Impeccable installation and initialization
- Verify that Impeccable is discoverable in the current agent session, rather than assuming an installed directory is sufficient.
- If unavailable for a web project, offer assisted installation, official installation instructions, or continuation without it. Before executing an installation command, explain its source, target agent, local/global scope, and configuration effects and obtain explicit approval. Use current official instructions rather than guessing a command or downloading dependencies silently.
- Recheck skill discovery after installation. If a restart is required, finish Conductor setup and defer initialization until a session can discover the skill. Installation failure or refusal must not block setup or remove the direct design-brief fallback.
- For web projects, after Conductor's product context and tech stack are approved and before setup completes, offer `/impeccable init` when the skill is available. Run it only with explicit opt-in.
- Pass approved Conductor context into the handoff and ask only about material gaps or conflicts, rather than repeating the product interview.
- Conductor's approved context and track specifications remain requirements authority. Impeccable's `PRODUCT.md` is its derived product context and links back to the applicable Conductor sources. Reconcile conflicts explicitly; never silently overwrite existing product context.
- Initialization captures product truth; it does not establish the visual design or create `DESIGN.md`. Honor the skill's own confirmation and configuration-consent steps.
- If initialization was skipped during setup, offer it before the first web design track that needs Impeccable's new-design flow. Confirm that a valid `PRODUCT.md` exists before proceeding to `shape`; preserve an existing valid record without reinitializing unnecessarily.
- If the skill is unavailable or initialization is declined, complete the design brief directly without Impeccable. Backend-only and native tracks do not trigger this optional handoff.
- Installation and initialization apply to the consuming web project, not this Conductor tooling repository.

### Design artifacts
Use track-local `design.md` for user tasks, flows, significant states, layout intent, accessibility, references, and acceptance criteria.

`spec.md` remains requirements authority; `plan.md` incorporates the approved design work. Reuse existing product/design documentation without creating competing sources of truth.

### User-controlled design decisions
- Preserve Impeccable's applicable design-option presentation, user selection, and revision rounds. Reusing confirmed product context must not skip unresolved visual or interaction decisions.
- Approval of product requirements or installation/initialization does not approve a visual direction. Obtain explicit selection and confirmation of the resulting brief before final specification and implementation-plan approval; do not choose on the user's behalf unless explicitly delegated.
- Record the selected direction and supporting references in track-local `design.md` and carry its consequences into `spec.md` and `plan.md`.
- Preserve the established direction for narrow refinements; do not force alternatives or reopen already approved decisions unnecessarily.
- Browser previews and live variants remain dependent on the installed skill, available tools, and a runnable project. Report unavailable capabilities and use a supported alternative presentation without fabricating previews or bypassing user choice.

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

Verify routing and lifecycle instructions against scenarios covering web with/without Impeccable, assisted installation accepted/declined/failed, installation requiring restart, setup initialization accepted/skipped/declined, first-use initialization, existing or conflicting `PRODUCT.md`, design alternatives selected/revised, requirements approved without design selection, unavailable preview tools, native, cross-platform, backend-only, existing designs, existing Swift tooling, and unavailable verification tools. Run existing regression suites and an isolated installer smoke test.

## Assumptions & agent-made decisions

## Open questions auto-decided by agent — PLEASE DOUBLE-CHECK
